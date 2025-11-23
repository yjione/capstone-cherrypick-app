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
        await packingProvider.loadBagsFromServer(
          deviceUuid: device.deviceUuid!,
          deviceToken: device.deviceToken!,
          tripId: int.parse(currentTrip.id),
        );
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
    final hasLoadedTrips = tripProvider.hasLoadedOnce;   // ⭐

    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    /// 0) 서버에서 여행 목록 로딩 중이면 로딩 화면
    if (isLoadingTrips) {
      return Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('cherry pick'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      );
    }

    /// 1) 서버에서 한 번이라도 불러봤고, 등록된 여행이 하나도 없음 → initial-trip 으로 보내기
    if (hasLoadedTrips && trips.isEmpty) {             // ⭐ 조건 수정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/initial-trip');
      });
      return const SizedBox.shrink();
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

    // ---------- 아래는 기존 코드 그대로 ----------
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
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'cherry pick',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
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

                // 🔎 상단 검색창 → PackingProvider.searchQuery 와 연결
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '물건 검색...',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceVariant.withOpacity(0.12),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor.withOpacity(0.5),
                    ),
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

// 🔻 여행 선택/추가/삭제 바텀시트
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

  // 🔻 여행 삭제 확인 다이얼로그 (서버 연동은 아직 없이 로컬만)
  Future<void> _confirmDeleteTrip(
      BuildContext context,
      Trip trip,
      TripProvider tripProvider,
      ) async {
    final canDelete = tripProvider.trips.length > 1;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('여행 삭제'),
          content: Text(
            canDelete
                ? '"${trip.name}" 여행을 삭제할까요?'
                : '마지막 남은 여행은 삭제할 수 없어요.\n새 여행을 추가한 후에 삭제해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            if (canDelete)
              TextButton(
                onPressed: () {
                  tripProvider.deleteTrip(trip.id);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('삭제'),
              ),
          ],
        );
      },
    );
  }
}
