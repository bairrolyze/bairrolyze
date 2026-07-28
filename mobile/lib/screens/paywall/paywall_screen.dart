import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../providers/pro_provider.dart';
import '../../services/purchase_service.dart';

const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kAccent  = Color(0xFF3B82F6);
const _kBorder  = Color(0xFF1A2845);
const _kPurple  = Color(0xFF7C3AED);
const _kIndigo  = Color(0xFF4F46E5);

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PaywallScreen(),
        ),
      );

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _loadingOfferings = false;
  bool _purchasing = false;
  String? _error;

  // Fallback display prices when RevenueCat isn't configured yet
  String get _proPrice {
    final pkg = _offerings?.current?.availablePackages
        .where((p) => p.identifier.contains('pro'))
        .firstOrNull;
    return pkg?.storeProduct.priceString ?? '€7.99';
  }

  String get _premiumPrice {
    final pkg = _offerings?.current?.availablePackages
        .where((p) => p.identifier.contains('premium'))
        .firstOrNull;
    return pkg?.storeProduct.priceString ?? '€14.99';
  }

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (PurchaseService.isMock) return;
    setState(() => _loadingOfferings = true);
    final offerings = await PurchaseService.getOfferings();
    if (mounted) setState(() { _offerings = offerings; _loadingOfferings = false; });
  }

  Future<void> _purchase(ProTier tier) async {
    setState(() { _purchasing = true; _error = null; });

    try {
      if (PurchaseService.isMock) {
        // Dev / demo mode — simulate purchase instantly
        await Future.delayed(const Duration(milliseconds: 600));
        ref.read(proProvider.notifier).upgradeTo(tier);
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Real RevenueCat purchase
      final identifier = tier == ProTier.premium ? 'premium' : 'pro';
      final pkg = _offerings?.current?.availablePackages
          .where((p) => p.identifier.contains(identifier))
          .firstOrNull;

      if (pkg == null) {
        setState(() => _error = 'Product not available. Please try again.');
        return;
      }

      final info = await PurchaseService.purchase(pkg);
      if (info != null) {
        ref.read(proProvider.notifier).upgradeTo(
              PurchaseService.tierFromCustomerInfo(info),
            );
        if (mounted) Navigator.of(context).pop();
      }
    } on PurchasesErrorCode catch (e) {
      if (mounted) setState(() => _error = _errorMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() { _purchasing = true; _error = null; });
    await ref.read(proProvider.notifier).restorePurchases();
    if (mounted) {
      setState(() => _purchasing = false);
      final tier = ref.read(proProvider).tier;
      if (tier != ProTier.free) {
        Navigator.of(context).pop();
      } else {
        setState(() => _error = 'No active purchases found on this account.');
      }
    }
  }

  String _errorMessage(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return '';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending. Check your payment method.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Product not available in your region.';
      default:
        return 'Purchase failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _TopBar(),
                  const SizedBox(height: 28),
                  _Header(),
                  const SizedBox(height: 24),
                  _FreeCard(),
                  const SizedBox(height: 12),
                  _ProCard(price: _proPrice),
                  const SizedBox(height: 12),
                  _PremiumCard(price: _premiumPrice),
                  const SizedBox(height: 24),
                  if (_error != null && _error!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  _GradientButton(
                    label: 'Start Pro — $_proPrice/mo',
                    gradient: const LinearGradient(
                      colors: [_kAccent, _kPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    loading: _purchasing,
                    onTap: () => _purchase(ProTier.pro),
                  ),
                  const SizedBox(height: 12),
                  _GradientButton(
                    label: 'Try Premium — $_premiumPrice/mo',
                    gradient: const LinearGradient(
                      colors: [_kPurple, _kIndigo],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    loading: _purchasing,
                    onTap: () => _purchase(ProTier.premium),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _purchasing ? null : _restore,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.45),
                      ),
                      child: const Text('Restore purchases',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Cancel anytime. Billed monthly.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            // Full-screen loading overlay during purchase
            if (_purchasing)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: _kAccent,
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _kSurface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Icon(Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.55), size: 18),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kAccent, _kPurple]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Go Pro',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock the full\nHomeScope',
            style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.w800,
              color: Colors.white, letterSpacing: -1.0, height: 1.18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Make confident decisions with every insight at your fingertips.',
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.52), height: 1.55),
          ),
        ],
      );
}

class _FreeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.62,
        child: _TierCard(
          name: 'Free',
          price: '€0 / forever',
          features: const [
            '2 property comparisons',
            '1 neighbourhood alert',
            'Core analysis & maps',
          ],
        ),
      );
}

class _ProCard extends StatelessWidget {
  final String price;
  const _ProCard({required this.price});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kAccent.withValues(alpha: 0.65), width: 1.5),
          boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TierHeader(name: 'Pro', price: '$price / month'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kAccent, _kIndigo]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('MOST POPULAR',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...[
              'Unlimited comparisons',
              '10 neighbourhood alerts',
              'Priority analysis',
              'Historical timeline',
            ].map((f) => _FeatureRow(label: f)),
          ],
        ),
      );
}

class _PremiumCard extends StatelessWidget {
  final String price;
  const _PremiumCard({required this.price});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kPurple.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TierHeader(name: 'Premium', price: '$price / month'),
            const SizedBox(height: 14),
            ...[
              'Everything in Pro',
              '99 alerts with push notifications',
              'AI investment insights',
              'Trend forecasting',
            ].map((f) => _FeatureRow(label: f, color: _kPurple)),
          ],
        ),
      );
}

class _TierCard extends StatelessWidget {
  final String name, price;
  final List<String> features;
  const _TierCard({required this.name, required this.price, required this.features});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TierHeader(name: name, price: price),
            const SizedBox(height: 14),
            ...features.map((f) => _FeatureRow(label: f)),
          ],
        ),
      );
}

class _TierHeader extends StatelessWidget {
  final String name, price;
  const _TierHeader({required this.name, required this.price});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(price,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.48))),
        ],
      );
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final Color color;
  const _FeatureRow({required this.label, this.color = _kAccent});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: color, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.80), height: 1.4)),
            ),
          ],
        ),
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final bool loading;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: loading ? null : gradient,
            color: loading ? _kSurface2 : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: loading
                ? null
                : [BoxShadow(color: _kAccent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: loading ? Colors.white.withValues(alpha: 0.35) : Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
      );
}
