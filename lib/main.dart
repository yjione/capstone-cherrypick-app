// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/trip_provider.dart';
import 'providers/packing_provider.dart';
import 'providers/preview_provider.dart';
import 'providers/device_provider.dart';
import 'providers/reference_provider.dart';

import 'service/preview_api.dart';
import 'service/device_api.dart';
import 'service/reference_api.dart';

import 'screens/luggage_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/item_preview_screen.dart';
import 'screens/initial_trip_screen.dart';
import 'screens/onboarding_screen.dart';
//import 'screens/splash_screen.dart';

import 'theme/app_theme.dart';
import 'models/item_preview_sample.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 DeviceProvider를 먼저 만들어서 저장된 uuid/token 로딩
  final deviceProvider = DeviceProvider(api: DeviceApiService());
  await deviceProvider.loadFromStorage();

  runApp(CherryPickApp(deviceProvider: deviceProvider));
}

class CherryPickApp extends StatelessWidget {
  final DeviceProvider deviceProvider;

  const CherryPickApp({super.key, required this.deviceProvider});

  @override
  Widget build(BuildContext context) {
    // 🔹 Preview API base URL (ngrok 주소)
    const String previewBaseUrl =
        'https://gutturalized-london-unmistakingly.ngrok-free.dev';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PackingProvider()),
        ChangeNotifierProvider(
          create: (_) => PreviewProvider(
            api: PreviewApiService(baseUrl: previewBaseUrl),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReferenceProvider(
            api: ReferenceApiService(),
          ),
        ),
        // 이미 초기화된 DeviceProvider 주입
        ChangeNotifierProvider<DeviceProvider>.value(
          value: deviceProvider,
        ),
      ],
      child: MaterialApp.router(
        title: 'Cherry Pick',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    // GoRoute(
    //   path: '/splash',
    //   builder: (context, state) => const SplashScreen(),
    // ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/initial-trip',
      builder: (context, state) => const InitialTripScreen(),
    ),
    GoRoute(
      path: '/preview-debug',
      builder: (context, state) => ItemPreviewScreen(
        data: buildSamplePreviewResponse(),
      ),
    ),
    GoRoute(
      path: '/luggage',
      builder: (context, state) => const LuggageScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/checklist',
      builder: (context, state) => const ChecklistScreen(),
    ),
    GoRoute(
      path: '/recommendations',
      builder: (context, state) => const RecommendationsScreen(),
    ),
  ],
);
