import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/trip_provider.dart';
import 'providers/packing_provider.dart';

import 'providers/preview_provider.dart';
import 'service/preview_api.dart';

import 'screens/luggage_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'theme/app_theme.dart';

import 'models/item_preview_sample.dart';
import 'screens/item_preview_screen.dart';
import 'screens/initial_trip_screen.dart';

import 'service/device_api.dart';
import 'providers/device_provider.dart';

void main() {
  runApp(const CherryPickApp());
}

class CherryPickApp extends StatelessWidget {
  const CherryPickApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Preview API base URL (ngrok 주소)
    const String previewBaseUrl =
        'https://unmatted-cecilia-criticizingly.ngrok-free.dev';

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
          create: (_) => DeviceProvider(api: DeviceApiService()),
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
  // 🔹 앱 처음 켰을 때 보이는 화면
  initialLocation: '/initial-trip',
  routes: [
    // 🔹 첫 여행 입력 화면
    GoRoute(
      path: '/initial-trip',
      builder: (context, state) => const InitialTripScreen(),
    ),

    // ✅ 미리보기 디자인 디버그용 (샘플 데이터)
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
