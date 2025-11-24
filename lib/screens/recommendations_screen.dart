// lib/screens/recommendations_screen.dart
import 'package:flutter/material.dart';

import '../widgets/cherry_app_bar.dart';          // ✅ 공용 AppBar
import '../widgets/bottom_navigation.dart';
import '../widgets/travel_recommendations.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const CherryAppBar(),               // ✅ 중앙 로고만
      body: const TravelRecommendations(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }
}
