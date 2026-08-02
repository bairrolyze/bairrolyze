import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../../config/onboarding_priorities.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/preferences_provider.dart';

// Shared brand gradient — mirrors the home screen's blue→violet accent.
const _brandGradient = LinearGradient(
  colors: [AppColors.accent, AppColors.accent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _kGutter = 24.0;
const _kMaxPriorities = 3;

/// First-launch onboarding — a "what matters to you" flow that captures the
/// signals a user cares about and resolves them into a scoring [UserProfile].
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _selected = <String>{};
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggle(String key) {
    setState(() {
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else if (_selected.length < _kMaxPriorities) {
        _selected.add(key);
      }
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final keys = _selected.toList();
    final n = ref.read(preferencesProvider.notifier);
    await n.setPriorities(keys);
    await n.setProfile(profileFromPriorities(keys));
    await n.setOnboardingComplete(true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // Soft brand glow for depth, matching the home hero.
          const Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: Center(child: _GlowBlob()),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar: page dots (left) + persistent Skip (right).
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kGutter, 12, 12, 4),
                  child: Row(
                    children: [
                      _PageDots(page: _page, count: 3),
                      const Spacer(),
                      TextButton(
                        onPressed: _finishing ? null : _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: p.textTertiary,
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _WelcomePage(onNext: () => _goTo(1)),
                      _PrioritiesPage(
                        selected: _selected,
                        onToggle: _toggle,
                        onContinue: () => _goTo(2),
                      ),
                      _ConfirmationPage(
                        selectedKeys: _selected.toList(),
                        finishing: _finishing,
                        onFinish: _finish,
                      ),
                    ],
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

// ── Page 1: Welcome ───────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, _kGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(26),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: -6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.home_rounded,
                  color: AppColors.accent, size: 44),
            )
                .animate()
                .fadeIn(duration: 460.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 22),
          Text(
            'Bairrolyze',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 460.ms),
          const SizedBox(height: 20),
          Text(
            "Let's tailor your scores",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ).animate(delay: 110.ms).fadeIn(duration: 460.ms).slideY(
                begin: 0.08,
                end: 0,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: 14),
          Text(
            'Bairrolyze scores every address around\nwhat matters to you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 15.5,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 460.ms),
          const Spacer(flex: 3),
          _PrimaryButton(
            label: 'Get started',
            onPressed: onNext,
          ).animate(delay: 220.ms).fadeIn(duration: 460.ms),
        ],
      ),
    );
  }
}

// ── Page 2: Priorities ────────────────────────────────────────────────────────

class _PrioritiesPage extends StatelessWidget {
  final Set<String> selected;
  final void Function(String key) onToggle;
  final VoidCallback onContinue;

  const _PrioritiesPage({
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final atCap = selected.length >= _kMaxPriorities;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 8, _kGutter, _kGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            "What matters most where you'll live?",
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Pick up to 3.',
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 15,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: atCap ? 1 : 0,
                child: Text(
                  "That's the max",
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < onboardingPriorities.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PriorityTile(
                        priority: onboardingPriorities[i],
                        selected: selected.contains(onboardingPriorities[i].key),
                        dimmed: atCap &&
                            !selected.contains(onboardingPriorities[i].key),
                        onTap: () => onToggle(onboardingPriorities[i].key),
                      )
                          .animate(delay: (60 * i).ms)
                          .fadeIn(duration: 360.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: 'Continue',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final OnboardingPriority priority;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _PriorityTile({
    required this.priority,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : p.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.7)
                    : p.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  priority.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    priority.label,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1 : 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _brandGradient,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Page 3: Confirmation ──────────────────────────────────────────────────────

class _ConfirmationPage extends StatelessWidget {
  final List<String> selectedKeys;
  final bool finishing;
  final VoidCallback onFinish;

  const _ConfirmationPage({
    required this.selectedKeys,
    required this.finishing,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final profile = profileFromPriorities(selectedKeys);
    final chosen = onboardingPriorities
        .where((pr) => selectedKeys.contains(pr.key))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, _kGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(26),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: -6,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                profile.emoji,
                style: const TextStyle(fontSize: 42),
              ),
            )
                .animate()
                .fadeIn(duration: 460.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ),
          const SizedBox(height: 24),
          Text(
            "Perfect — we'll prioritize ${profile.emoji} ${profile.label}.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ).animate(delay: 80.ms).fadeIn(duration: 460.ms),
          if (chosen.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Your priorities',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ).animate(delay: 140.ms).fadeIn(duration: 460.ms),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final pr in chosen)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pr.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          pr.label,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ).animate(delay: 180.ms).fadeIn(duration: 460.ms),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              "We'll use a balanced, general profile — you can refine this any time in settings.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 15,
                height: 1.5,
                letterSpacing: -0.1,
              ),
            ).animate(delay: 140.ms).fadeIn(duration: 460.ms),
          ],
          const Spacer(flex: 3),
          _PrimaryButton(
            label: 'Start exploring',
            busy: finishing,
            onPressed: onFinish,
          ).animate(delay: 220.ms).fadeIn(duration: 460.ms),
        ],
      ),
    );
  }
}

// ── Shared pieces ─────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool busy;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.40),
            blurRadius: 26,
            offset: const Offset(0, 9),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: busy ? null : onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int page;
  final int count;
  const _PageDots({required this.page, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          width: on ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            gradient: on ? _brandGradient : null,
            color: on ? null : p.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.16),
              AppColors.accent.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
