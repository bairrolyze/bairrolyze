import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/pro_provider.dart';
import '../paywall/paywall_screen.dart';

const _kBg = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kAccent = Color(0xFF3B82F6);
const _kBorder = Color(0xFF1A2845);

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final alerts = ref.watch(alertsProvider);
    final alertsNotifier = ref.read(alertsProvider.notifier);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              unreadCount: alerts.unreadCount,
              onMarkAllRead: alertsNotifier.markAllRead,
            ),
            Expanded(
              child: pro.tier == ProTier.free
                  ? _PaywallSection()
                  : alerts.entries.isEmpty
                      ? _EmptySection()
                      : _AlertsContent(
                          alerts: alerts,
                          alertsNotifier: alertsNotifier,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onMarkAllRead;

  const _Header({required this.unreadCount, required this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Neighbourhood Alerts',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: onMarkAllRead,
              style: TextButton.styleFrom(
                foregroundColor: _kAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mark all read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paywall marketing section (free tier)
// ---------------------------------------------------------------------------

class _PaywallSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_kAccent, Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Stay ahead of the market',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Get notified when neighbourhood scores change, new amenities open, or safety levels shift. Never miss a change that matters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.42),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                _FeatureCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: _kAccent,
                  title: 'Score Updates',
                  body: 'Weekly summary of how your saved neighbourhoods are performing.',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.add_location_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: 'New Amenities',
                  body:
                      'Be first to know when a school, transport link or park opens nearby.',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.security_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Safety Alerts',
                  body:
                      'Immediate notification if a saved area\'s safety score changes significantly.',
                ),
                const SizedBox(height: 32),
                _GradientButton(
                  label: 'Start Free Trial',
                  onPressed: () => PaywallScreen.show(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'From €7.99/month after trial',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kAccent, Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (subscribed but no alerts)
// ---------------------------------------------------------------------------

class _EmptySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              const Text(
                'No alerts set up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Analyze a neighbourhood and tap \'Follow\' to start receiving alerts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _GradientButton(
            label: 'Add your first neighbourhood',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Main content (subscribed + has entries)
// ---------------------------------------------------------------------------

class _AlertsContent extends ConsumerWidget {
  final AlertsState alerts;
  final AlertsNotifier alertsNotifier;

  const _AlertsContent({
    required this.alerts,
    required this.alertsNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _FollowingSection(
            entries: alerts.entries,
            onUnfollow: alertsNotifier.unfollow,
          ),
        ),
        if (alerts.notifications.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
              child: Text(
                'RECENT ALERTS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notif = alerts.notifications[index];
                return _NotificationTile(notification: notif);
              },
              childCount: alerts.notifications.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Following horizontal list
// ---------------------------------------------------------------------------

class _FollowingSection extends StatelessWidget {
  final List<AlertEntry> entries;
  final void Function(String id) onUnfollow;

  const _FollowingSection({
    required this.entries,
    required this.onUnfollow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Text(
            'FOLLOWING (${entries.length})',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return _FollowingCard(
                entry: entries[index],
                onUnfollow: () => onUnfollow(entries[index].id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FollowingCard extends StatelessWidget {
  final AlertEntry entry;
  final VoidCallback onUnfollow;

  const _FollowingCard({required this.entry, required this.onUnfollow});

  @override
  Widget build(BuildContext context) {
    final score = entry.scoreAtSave;
    final typeLabels = entry.types.map((t) => _typeLabel(t)).toList();

    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreBadge(score: score),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.address.displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: typeLabels
                .map((label) => _TypePill(label: label))
                .toList(),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: onUnfollow,
              child: Text(
                'Unfollow',
                style: TextStyle(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AlertType type) {
    switch (type) {
      case AlertType.weeklyDigest:
        return 'weekly';
      case AlertType.scoreChange:
        return 'score';
      case AlertType.newAmenity:
        return 'amenity';
      case AlertType.safetyAlert:
        return 'safety';
    }
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? const Color(0xFF22C55E)
        : score >= 50
            ? _kAccent
            : const Color(0xFFFFA726);

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            score.round().toString(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;

  const _TypePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  final AlertNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(notification.type);
    final bgColor = notification.isRead
        ? _kSurface
        : Color.alphaBlend(
            _kAccent.withValues(alpha: 0.07),
            _kSurface,
          );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notification.isRead
              ? _kBorder
              : _kAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatTimestamp(notification.timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForType(AlertType type) {
    switch (type) {
      case AlertType.weeklyDigest:
        return _kAccent;
      case AlertType.scoreChange:
        return const Color(0xFF22C55E);
      case AlertType.newAmenity:
        return const Color(0xFFFFA726);
      case AlertType.safetyAlert:
        return const Color(0xFFEF4444);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
