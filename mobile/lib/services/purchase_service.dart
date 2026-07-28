import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../providers/pro_provider.dart';

/// Thin wrapper around RevenueCat.
///
/// Set your API keys below (obtain from app.revenuecat.com).
/// While keys are still placeholders the service runs in mock/dev mode —
/// purchases are simulated in-memory and nothing hits RevenueCat's servers.
class PurchaseService {
  // ── Replace with real keys from app.revenuecat.com ───────────────────────
  static const _apiKeyIos     = 'REVENUECAT_IOS_API_KEY';
  static const _apiKeyAndroid = 'REVENUECAT_ANDROID_API_KEY';

  // ── Entitlement IDs — must match your RevenueCat dashboard ───────────────
  static const entitlementPro     = 'pro';
  static const entitlementPremium = 'premium';

  // ── Offering ID — "default" is the RevenueCat default ────────────────────
  static const offeringId = 'default';

  // Mock mode active whenever keys haven't been replaced
  static bool get isMock =>
      _apiKeyIos == 'REVENUECAT_IOS_API_KEY' || kDebugMode;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (isMock) {
      debugPrint('[PurchaseService] Mock mode — set real API keys to enable IAP.');
      return;
    }
    try {
      final key = Platform.isIOS ? _apiKeyIos : _apiKeyAndroid;
      final config = PurchasesConfiguration(key)..appUserID = null; // anonymous
      await Purchases.configure(config);
      await Purchases.setLogLevel(LogLevel.warn);
    } catch (e) {
      debugPrint('[PurchaseService] init error: $e');
    }
  }

  // ── Read state ────────────────────────────────────────────────────────────

  static Future<CustomerInfo?> getCustomerInfo() async {
    if (isMock) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (isMock) return null;
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Purchase ──────────────────────────────────────────────────────────────

  static Future<CustomerInfo?> purchase(Package package) async {
    try {
      return await Purchases.purchasePackage(package);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    }
  }

  static Future<CustomerInfo?> restorePurchases() async {
    if (isMock) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static ProTier tierFromCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active;
    if (active.containsKey(entitlementPremium)) return ProTier.premium;
    if (active.containsKey(entitlementPro)) return ProTier.pro;
    return ProTier.free;
  }
}
