import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls which bottom-nav tab is active in the main shell.
/// 0 = Search, 1 = Explore, 2 = Discover, 3 = You
final shellTabProvider = StateProvider<int>((ref) => 0);
