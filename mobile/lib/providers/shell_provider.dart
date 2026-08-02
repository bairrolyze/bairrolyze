import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls which screen is active in the main shell's IndexedStack.
/// 0 = Home, 1 = Results (post-analyse), 2 = Map, 3 = Saved, 4 = Profile
final shellTabProvider = StateProvider<int>((ref) => 0);
