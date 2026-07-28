import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';
import '../models/score_model.dart';

class SavedProperty {
  final String id;
  final AddressModel address;
  final LocationScore score;
  final DateTime savedAt;

  SavedProperty({
    required this.id,
    required this.address,
    required this.score,
    required this.savedAt,
  });
}

class CompareState {
  final List<SavedProperty> items;
  const CompareState({this.items = const []});
  bool contains(String id) => items.any((p) => p.id == id);
}

class CompareNotifier extends StateNotifier<CompareState> {
  CompareNotifier() : super(const CompareState());

  void add(AddressModel address, LocationScore score) {
    final id = idFor(address);
    if (state.contains(id)) return;
    final item = SavedProperty(
      id: id,
      address: address,
      score: score,
      savedAt: DateTime.now(),
    );
    state = CompareState(items: [...state.items, item]);
  }

  void remove(String id) =>
      state = CompareState(items: state.items.where((p) => p.id != id).toList());

  void clear() => state = const CompareState();

  static String idFor(AddressModel a) =>
      a.displayAddress.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
}

final compareProvider = StateNotifierProvider<CompareNotifier, CompareState>(
  (ref) => CompareNotifier(),
);
