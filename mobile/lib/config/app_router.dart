import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/preferences_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/shell/main_shell.dart';
import 'app_theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod prefs changes into a Listenable so the router re-evaluates
  // its redirect whenever preferences (initialized / onboardingComplete) change.
  final refresh = ValueNotifier<int>(0);
  ref.listen(preferencesProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final prefs = ref.read(preferencesProvider);
      final loc = state.matchedLocation;
      // Prefs not loaded yet → hold on a brief splash to avoid flashing
      // onboarding before we know whether it's a returning user.
      if (!prefs.initialized) return loc == '/splash' ? null : '/splash';
      // First launch → onboarding until completed.
      if (!prefs.onboardingComplete) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      // Loaded + onboarded → keep users out of the splash/onboarding routes.
      if (loc == '/onboarding' || loc == '/splash') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const _SplashGate(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

/// Minimal holding screen shown while SharedPreferences loads on cold start.
class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.home_rounded, color: AppColors.accent, size: 36),
        ),
      ),
    );
  }
}
