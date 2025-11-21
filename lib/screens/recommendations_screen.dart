import 'package:flutter/material.dart';
import '../widgets/simple_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/travel_recommendations.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,   // leading 제거
        centerTitle: false,
        titleSpacing: 0,
        title: Stack(
          alignment: Alignment.center,
          children: [
            // 왼쪽 여행명 / 헤더 UI
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 200,     // 기존 leadingWidth 동일하게 유지
                child: SimpleHeader(),
              ),
            ),

            // 정확히 화면 기준 가운데에 표시되는 cherry pick
            const Align(
              alignment: Alignment.center,
              child: Text(
                'cherry pick',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),

      body: const TravelRecommendations(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }
}
