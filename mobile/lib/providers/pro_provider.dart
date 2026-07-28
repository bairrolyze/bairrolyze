import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';

enum ProTier { free, pro, premium }

class ProState {
  final ProTier tier;
  final bool isRestoring;

  const ProState({this.tier = ProTier.free, this.isRestoring = false});

  bool get isPro     => tier == ProTier.pro || tier == ProTier.premium;
  bool get isPremium => tier == ProTier.premium;
  int  get maxCompare => isPro ? 10 : 2;
  int  get maxAlerts  => isPremium ? 99 : (isPro ? 10 : 1);
}

class ProNotifier extends StateNotifier<ProState> {
  ProNotifier() : super(const ProState()) {
    _syncFromRevenueCat();
  }

  // Called on app start and after any purchase/restore
  Future<void> _syncFromRevenueCat() async {
    final info = await PurchaseService.getCustomerInfo();
    if (info == null) return; // mock mode or network error — keep current state
    if (mounted) {
      state = ProState(tier: PurchaseService.tierFromCustomerInfo(info));
    }
  }

  void upgradeTo(ProTier tier) => state = ProState(tier: tier);

  Future<void> restorePurchases() async {
    state = ProState(tier: state.tier, isRestoring: true);
    final info = await PurchaseService.restorePurchases();
    if (info != null && mounted) {
      state = ProState(tier: PurchaseService.tierFromCustomerInfo(info));
    } else if (mounted) {
      state = ProState(tier: state.tier);
    }
  }

  void reset() => state = const ProState();
}

final proProvider = StateNotifierProvider<ProNotifier, ProState>(
  (ref) => ProNotifier(),
);
