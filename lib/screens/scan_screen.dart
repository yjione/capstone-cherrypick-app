// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_navigation.dart';
import '../widgets/item_scanner.dart';
import '../widgets/yolo_scanner.dart'; // 새로운 YOLO 스캐너
import '../widgets/cherry_app_bar.dart';      // ✅ 추가
import '../providers/trip_provider.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // 🔹 현재 선택된 여행 가져오기
    final tripProvider = context.watch<TripProvider>();
    final currentTrip = tripProvider.currentTrip;

    // 🔹 1) 여행이 하나도 없거나, 현재 선택된 여행이 없으면 안내 화면
    // ⚠️ 개발/테스트용: 여행 체크 비활성화 - 바로 스캔 가능!
    // if (currentTrip == null) {
    //   return Scaffold(
    //     backgroundColor: scheme.surface,
    //     appBar: const CherryAppBar(),
    //     body: Center(
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 24),
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             const Icon(
    //               Icons.luggage_outlined,
    //               size: 56,
    //             ),
    //             const SizedBox(height: 16),
    //             const Text(
    //               '등록된 여행이 없어요',
    //               style: TextStyle(
    //                 fontSize: 18,
    //                 fontWeight: FontWeight.w700,
    //               ),
    //               textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 8),
    //             const Text(
    //               '어떤 여행을 떠나는지 먼저 설정해 주세요.\n'
    //                   '여행을 기준으로 항공 규정에 맞는지 알려줄게요.',
    //               style: TextStyle(fontSize: 14),
    //               textAlign: TextAlign.center,
    //             ),
    //             const SizedBox(height: 24),
    //             FilledButton(
    //               onPressed: () {
    //                 // 🔸 여행 관리/추가하는 Luggage 탭으로 이동
    //                 context.go('/luggage');
    //               },
    //               child: const Text('여행 추가하러 가기'),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //     bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    //   );
    // }

    // 🔹 2) 현재 여행이 있는 정상 케이스 → 새로운 YOLO 스캐너 UI
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const CherryAppBar(),               // ✅ 통일
      body: const YoloScanner(), // ItemScanner 대신 YoloScanner 사용
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }
}
