// lib/screens/recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/cherry_app_bar.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/travel_recommendations.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../models/trip.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // 웹에서 /recommendations 로 바로 들어올 때도
    // trip 목록을 한 번은 불러오도록 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final device = context.read<DeviceProvider>();
      final tripProvider = context.read<TripProvider>();

      if (device.deviceUuid == null || device.deviceToken == null) {
        // 디바이스 등록 안 돼 있으면 그냥 놔두고,
        // 다른 화면에서 initial-trip 으로 보내도록.
        return;
      }

      if (!tripProvider.hasLoadedOnce) {
        await tripProvider.fetchTripsFromServer(
          deviceUuid: device.deviceUuid!,
          deviceToken: device.deviceToken!,
        );
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme
        .of(context)
        .colorScheme;
    final tripProvider = context.watch<TripProvider>();
    final Trip? currentTrip = tripProvider.currentTrip;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const CherryAppBar(),
      body: _buildBody(context, tripProvider, currentTrip),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildBody(BuildContext context,
      TripProvider tripProvider,
      Trip? currentTrip,) {
    final cs = Theme
        .of(context)
        .colorScheme;

    // 아직 서버에서 불러오는 중
    if (!_initialized || tripProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 한 번 불러왔는데도 여행이 없으면 안내문 + 버튼
    if (tripProvider.hasLoadedOnce && currentTrip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.luggage_outlined,
                size: 56,
                color: cs.onSurface.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                '선택된 여행이 없어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '여행을 추가하면 여행지와 기간에 맞는\n'
                    '추천 짐 리스트를 보여드릴게요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/initial-trip'),
                child: const Text('여행 추가하러 가기'),
              ),
            ],
          ),
        ),
      );
    }

    // 정상 케이스: 현재 선택된 여행이 있음
    return TravelRecommendations(trip: currentTrip!);
  }
}
