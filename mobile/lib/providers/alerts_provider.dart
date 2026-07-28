import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';

enum AlertType { weeklyDigest, scoreChange, newAmenity, safetyAlert }

class AlertEntry {
  final String id;
  final AddressModel address;
  final double scoreAtSave;
  final Set<AlertType> types;
  final DateTime createdAt;

  AlertEntry({
    required this.id,
    required this.address,
    required this.scoreAtSave,
    required this.types,
    required this.createdAt,
  });

  static String _idFor(AddressModel a) =>
      a.displayAddress.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
}

// A mock alert notification (simulated, would be real push in production)
class AlertNotification {
  final String entryId;
  final String title;
  final String body;
  final AlertType type;
  final DateTime timestamp;
  bool isRead;

  AlertNotification({
    required this.entryId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

class AlertsState {
  final List<AlertEntry> entries;
  final List<AlertNotification> notifications;

  const AlertsState({
    this.entries = const [],
    this.notifications = const [],
  });

  bool isFollowing(AddressModel address) =>
      entries.any((e) => e.id == AlertEntry._idFor(address));

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier() : super(const AlertsState());

  void follow(AddressModel address, double score, {Set<AlertType>? types}) {
    final id = AlertEntry._idFor(address);
    if (state.isFollowing(address)) return;

    final entry = AlertEntry(
      id: id,
      address: address,
      scoreAtSave: score,
      types: types ?? {AlertType.weeklyDigest, AlertType.scoreChange},
      createdAt: DateTime.now(),
    );

    // Generate mock initial notifications
    final notifs = _generateMockNotifications(entry, score);

    state = AlertsState(
      entries: [...state.entries, entry],
      notifications: [...state.notifications, ...notifs],
    );
  }

  void unfollow(String id) => state = AlertsState(
        entries: state.entries.where((e) => e.id != id).toList(),
        notifications: state.notifications.where((n) => n.entryId != id).toList(),
      );

  void markAllRead() => state = AlertsState(
        entries: state.entries,
        notifications: state.notifications
            .map((n) => AlertNotification(
                  entryId: n.entryId,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  timestamp: n.timestamp,
                  isRead: true,
                ))
            .toList(),
      );

  void clear() => state = const AlertsState();

  static List<AlertNotification> _generateMockNotifications(
      AlertEntry entry, double score) {
    final now = DateTime.now();
    final name = entry.address.displayAddress.split(',').first;
    return [
      AlertNotification(
        entryId: entry.id,
        title: 'Weekly digest for $name',
        body:
            'Overall score remains ${score.round()}/100. Transport and education scores stable.',
        type: AlertType.weeklyDigest,
        timestamp: now.subtract(const Duration(days: 2)),
      ),
      AlertNotification(
        entryId: entry.id,
        title: 'New amenity nearby',
        body: 'A new pharmacy opened within 500m of your saved address.',
        type: AlertType.newAmenity,
        timestamp: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertsState>(
  (ref) => AlertsNotifier(),
);
