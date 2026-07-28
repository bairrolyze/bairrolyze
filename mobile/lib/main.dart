import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/purchase_service.dart';

final logger = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5),
);

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash visible until we finish initialising
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Hive.initFlutter();
  await Hive.openBox('homescope_cache');
  await Hive.openBox('search_history');

  // RevenueCat — no-ops in mock/dev mode until real API keys are added
  await PurchaseService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Remove native splash — Flutter renders the first frame
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: HomeScopeApp()));
}

class HomeScopeApp extends ConsumerWidget {
  const HomeScopeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HomeScope',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
