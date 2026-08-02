import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// A single parsed Server-Sent Event from the analyze pipeline stream.
///
/// Mirrors the events emitted by `backend/services/sse.py`:
///   - "job_status": job-level status changed (pending/running/done/error)
///   - "stage": a single stage's status changed (address_found/map_ready/
///     amenities_ready/score_ready/summary_ready)
///   - "complete": terminal event, includes the final result payload if the
///     job succeeded
///   - "error": job not found/expired
///   - "timeout": server-side stream safety cutoff hit
class SseEvent {
  final String event;
  final Map<String, dynamic> data;

  const SseEvent(this.event, this.data);

  @override
  String toString() => 'SseEvent($event, $data)';
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.backendBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  /// Creates a background analyze job. The backend responds 202 Accepted
  /// immediately with an `analysis_id` — the actual pipeline (geocode ->
  /// amenities -> score -> AI summary) runs asynchronously. Follow up with
  /// [streamAnalysis] (preferred) or [getAnalysisStatus] (polling) to get
  /// progress and the final result.
  Future<String> createAnalysisJob({
    required String address,
    required String countryCode,
    required String profile,
    required double radius,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/analyze',
      data: {
        'address': address,
        'country_code': countryCode,
        'profile': profile,
        'radius': radius,
      },
    );
    final analysisId = response.data?['analysis_id'] as String?;
    if (analysisId == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Missing analysis_id in response',
      );
    }
    return analysisId;
  }

  /// One-shot poll of a job's current status (see backend
  /// GET /analyze/{id}/status). Useful for simple clients; the app itself
  /// prefers [streamAnalysis] for live progress.
  Future<Map<String, dynamic>> getAnalysisStatus(String analysisId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/analyze/$analysisId/status',
    );
    return response.data!;
  }

  /// Consumes the SSE stream at GET /analyze/{id}/stream, yielding one
  /// [SseEvent] per server-sent event as it arrives. The stream closes
  /// naturally when the server emits a terminal event ("complete",
  /// "error", or "timeout") and ends the HTTP response.
  Stream<SseEvent> streamAnalysis(String analysisId) async* {
    final response = await _dio.get<ResponseBody>(
      '/api/v1/analyze/$analysisId/stream',
      options: Options(
        responseType: ResponseType.stream,
        // The connection may legitimately stay open for a while as stages
        // complete; the server enforces its own max-duration cutoff.
        receiveTimeout: Duration.zero,
      ),
    );

    final byteStream = response.data!.stream;
    var buffer = '';

    await for (final chunk in byteStream) {
      buffer += utf8.decode(chunk, allowMalformed: true);

      // SSE events are separated by a blank line ("\n\n").
      while (true) {
        final separatorIndex = buffer.indexOf('\n\n');
        if (separatorIndex == -1) break;

        final rawEvent = buffer.substring(0, separatorIndex);
        buffer = buffer.substring(separatorIndex + 2);

        final parsed = _parseSseEvent(rawEvent);
        if (parsed != null) yield parsed;
      }
    }
  }

  SseEvent? _parseSseEvent(String rawEvent) {
    var eventName = 'message';
    String? dataLine;

    for (final line in rawEvent.split('\n')) {
      if (line.startsWith('event: ')) {
        eventName = line.substring('event: '.length).trim();
      } else if (line.startsWith('data: ')) {
        dataLine = line.substring('data: '.length);
      }
    }

    if (dataLine == null || dataLine.isEmpty) return null;
    try {
      final data = jsonDecode(dataLine) as Map<String, dynamic>;
      return SseEvent(eventName, data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> geocode(String address, String countryCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/geocode',
      data: {'address': address, 'country_code': countryCode},
    );
    return response.data!;
  }
}
