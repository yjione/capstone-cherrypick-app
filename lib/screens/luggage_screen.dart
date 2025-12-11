// lib/screens/luggage_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../widgets/bottom_navigation.dart';
import '../widgets/packing_manager.dart';
import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../models/trip.dart';
import '../widgets/cherry_app_bar.dart';   // ✅ 공용 AppBar

class LuggageScreen extends StatefulWidget {
  const LuggageScreen({super.key});

  @override
  State<LuggageScreen> createState() => _LuggageScreenState();
}

class _LuggageScreenState extends State<LuggageScreen> {
  /// 🔎 상단 검색창 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// 화면 진입 시 한 번 서버에서 여행 목록 & 가방 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final device = context.read<DeviceProvider>();
      final tripProvider = context.read<TripProvider>();
      final packingProvider = context.read<PackingProvider>();

      // ⭐ 0) 아직 기기 등록이 안 되어 있으면 첫 여행 설정 화면으로 보냄
      if (device.deviceUuid == null || device.deviceToken == null) {
        context.go('/initial-trip');
        return;
      }

      // 1) 여행 목록 먼저 가져오기
      await tripProvider.fetchTripsFromServer(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
      );

      // 2) 현재 여행 기준으로 가방/아이템 로딩
      final currentTrip = tripProvider.currentTrip;
      if (currentTrip != null) {
        if(packingProvider.bags.isEmpty){
          await packingProvider.loadBagsFromServer(
            deviceUuid: device.deviceUuid!,
            deviceToken: device.deviceToken!,
            tripId: int.parse(currentTrip.id),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packingProvider = context.watch<PackingProvider>();
    final bagCount = packingProvider.bags.length;

    final tripProvider = context.watch<TripProvider>();
    final List<Trip> trips = tripProvider.trips;
    final currentTrip = tripProvider.currentTrip;
    final isLoadingTrips = tripProvider.isLoading;
    final hasLoadedTrips = tripProvider.hasLoadedOnce; // ⭐

    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    /// 0) 서버에서 여행 목록 로딩 중이면 로딩 화면
    if (isLoadingTrips) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: const CherryAppBar(),      // ✅ 중앙 로고 텍스트
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      );
    }

    /// 1) 서버에서 한 번이라도 불러봤고, 등록된 여행이 하나도 없음 → 안내 화면
    if (hasLoadedTrips && trips.isEmpty) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: const CherryAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.luggage_outlined,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const Text(
                  '등록된 여행이 없어요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '여행을 추가하면 가방을 나눠 담고\n짐을 한 화면에서 관리할 수 있어요.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/initial-trip'),
                  child: const Text('여행 추가하기'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      );
    }

    /// 2) 여행은 있는데 currentTrip이 null 인 경우 → 첫 번째 여행 선택
    if (currentTrip == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (tripProvider.trips.isNotEmpty) {
          tripProvider.setCurrentTrip(tripProvider.trips.first.id);
        }
      });
      return const SizedBox.shrink();
    }

    // ---------- 아래는 기존 코드 그대로 (상단 타이틀만 이미지로 교체) ----------
    PreferredSizeWidget _topBar() {
      final scheme = Theme.of(context).colorScheme;
      final textColor = scheme.onSurface;

      return PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔻 가운데 PNG 로고 텍스트
                      Image.asset(
                        'assets/images/Cherry_Pick_Text.png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => _showTripSelector(context),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentTrip.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(width: 28, height: 1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🔎 상단 검색창 (+ X 버튼)
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '추가한 짐에서 검색',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceVariant.withOpacity(0.12),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor.withOpacity(0.5),
                    ),
                    // ✅ 여기: 검색어 있을 때만 X 버튼 노출
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: textColor.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<PackingProvider>()
                            .setSearchQuery('');
                        setState(() {}); // X 버튼 숨기기 위해 리빌드
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: scheme.outline.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: scheme.outline.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: scheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  cursorColor: textColor.withOpacity(0.8),
                  onChanged: (value) {
                    context.read<PackingProvider>().setSearchQuery(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (bagCount == 0) {
      // 가방이 아직 없을 때: 상단만 두고 PackingManager에서 빈 상태 표시
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: _topBar(),
        body: const PackingManager(showSearch: false),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      );
    }

    return DefaultTabController(
      key: ValueKey(bagCount),
      length: bagCount,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: _topBar(),
        body: const PackingManager(showSearch: false),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      ),
    );
  }

  // 여행 선택/추가/삭제 바텀시트
  void _showTripSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Consumer<TripProvider>(
          builder: (context, tripProvider, __) {
            final trips = tripProvider.trips;
            final currentTripId = tripProvider.currentTripId;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (c, i) {
                  // 마지막 줄: "여행 추가"
                  if (i == trips.length) {
                    return ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text(
                        '여행 추가',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/initial-trip');
                      },
                    );
                  }

                  final trip = trips[i];
                  final selected = trip.id == currentTripId;

                  return ListTile(
                    title: Text(
                      trip.name,
                      style: TextStyle(
                        fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(trip.destination),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected)
                          const Icon(
                            Icons.check_rounded,
                            size: 20,
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                          ),
                          onPressed: () async {
                            await _confirmDeleteTrip(
                                context, trip, tripProvider);
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final device = context.read<DeviceProvider>();
                      final packingProvider =
                      context.read<PackingProvider>();

                      tripProvider.setCurrentTrip(trip.id);
                      Navigator.pop(context);

                      // 여행 변경 시 새 여행의 가방/아이템 다시 로딩
                      if (device.deviceUuid != null &&
                          device.deviceToken != null) {
                        await packingProvider.loadBagsFromServer(
                          deviceUuid: device.deviceUuid!,
                          deviceToken: device.deviceToken!,
                          tripId: int.parse(trip.id),
                        );
                      }
                    },
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: trips.length + 1,
              ),
            );
          },
        );
      },
    );
  }

  // 여행이 하나도 없을 때 보여줄 화면 ----------------------------
  Widget _buildNoTripBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              '아직 등록된 여행이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '여행을 추가하면 가방별 짐 정리는 물론\n'
                  '항공 규정과 추천 짐 리스트도 함께 볼 수 있어요.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // 바로 여행 추가 화면으로
                context.go('/initial-trip');
              },
              child: const Text('여행 추가하러 가기'),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _confirmDeleteTrip(
      BuildContext context,
      Trip trip,
      TripProvider tripProvider,
      ) async {
    final device = context.read<DeviceProvider>();
    final packingProvider = context.read<PackingProvider>();

    final hasDeviceHeaders =
        device.deviceUuid != null && device.deviceToken != null;
    final isLastTrip = tripProvider.trips.length <= 1;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('여행 삭제'),
          content: Text(
            !hasDeviceHeaders
                ? '기기 정보가 없어 서버와 통신할 수 없어요.\n앱을 다시 실행해 주세요.'
                : isLastTrip
                ? '"${trip.name}" 여행을 삭제하면\n등록된 여행이 모두 삭제돼요.\n그래도 삭제할까요?'
                : '"${trip.name}" 여행을 삭제할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            if (hasDeviceHeaders)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () async {
                  // 다이얼로그 먼저 닫기
                  Navigator.pop(context);

                  try {
                    // 1) 서버 + 로컬에서 여행 삭제
                    await tripProvider.deleteTrip(
                      deviceUuid: device.deviceUuid!,
                      deviceToken: device.deviceToken!,
                      tripId: trip.id,
                      purge: true,
                    );

                    // 2) 새 currentTrip 기준으로 짐 목록 다시 로딩
                    final newCurrentTrip = tripProvider.currentTrip;
                    if (newCurrentTrip != null) {
                      await packingProvider.loadBagsFromServer(
                        deviceUuid: device.deviceUuid!,
                        deviceToken: device.deviceToken!,
                        tripId: int.parse(newCurrentTrip.id),
                      );
                    } else {
                      // 남은 여행이 하나도 없으면 여행 추가 화면으로
                      if (!context.mounted) return;
                      context.go('/initial-trip');
                    }
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('여행 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.'),
                      ),
                    );
                  }
                },
                child: const Text('삭제'),
              ),
          ],
        );
      },
    );
  }
}
