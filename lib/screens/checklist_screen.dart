import 'package:flutter/material.dart';
import '../widgets/simple_header.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/regulation_checker.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

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
        titleSpacing: 0,                    // Stack이 AppBar 전체 너비 사용하도록 설정
        title: Stack(
          alignment: Alignment.center,
          children: [
            // 왼쪽 헤더: 여행 선택, 뒤로가기 등 들어가는 영역
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 200,                  // 기존 leadingWidth 동일하게 유지
                child: SimpleHeader(),
              ),
            ),

            // 진짜 가운데 정렬된 cherry pick
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

      body: const RegulationChecker(),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }
}
