// lib/widgets/packing_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/item_list.dart';
import '../widgets/add_bag_dialog.dart';
import '../models/trip.dart';
import '../models/packing_item.dart';

class PackingManager extends StatelessWidget {
  final bool showSearch;
  const PackingManager({super.key, this.showSearch = true});

  @override
  Widget build(BuildContext context) {
    // ✈️ 현재 여행 정보
    final tripProvider = context.watch<TripProvider>();
    final Trip? currentTrip = tripProvider.currentTrip;

    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bags = packingProvider.bags;
        final isLoading = packingProvider.isLoading;

        // 서버에서 가방/아이템 로딩 중 + 아직 데이터 없음 → 로딩 스피너
        if (isLoading && bags.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 가방이 하나도 없을 때: 빈 상태 + 가방 추가 버튼
        if (bags.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.luggage, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    '아직 짐을 안 싸셨네요!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이번 여행에 꼭 챙길 물건들을\n하나씩 추가해 보세요.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddBagDialog(),
                      );
                    },
                    child: const Text('첫 가방 추가하기'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ 가방이 1개 이상일 때: 검색(옵션) + 여행 요약 카드 + 탭
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSearch) ...[
                const _SearchBar(),
                const SizedBox(height: 16),
              ],

              if (currentTrip != null) ...[
                TripSummaryCard(
                  trip: currentTrip,
                  packing: packingProvider,
                  onManageBags: () => _showBagManageBottomSheet(context),
                ),
                const SizedBox(height: 16),
              ],

              const Expanded(
                child: _BagTabs(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ 여행 카드의 ⋯ → "가방 관리"에서 호출되는 바텀시트
  void _showBagManageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<PackingProvider>(
          builder: (sheetContext, packingProvider, child) {
            final bags = packingProvider.bags;
            final cs = Theme.of(sheetContext).colorScheme;

            if (bags.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '이 여행에 등록된 가방이 없어요.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                itemCount: bags.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bag = bags[index];
                  final itemCount = bag.items.length;

                  return ListTile(
                    leading: const Icon(Icons.luggage_rounded),
                    title: Text(bag.name),
                    subtitle: Text('아이템 $itemCount개'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: '이름 변경',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () {
                            _showRenameBagDialog(context, bag.id);
                          },
                        ),
                        IconButton(
                          tooltip: '삭제',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            _confirmDeleteBag(context, bag.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ✏️ 가방 이름 변경 (서버 + 로컬)
  Future<void> _showRenameBagDialog(BuildContext context, String bagId) async {
    final packingProvider = context.read<PackingProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    final bag = packingProvider.bags.firstWhere((b) => b.id == bagId);

    final textController = TextEditingController(text: bag.name);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('가방 이름 변경'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '가방 이름',
              hintText: '예: 기내 수하물, 위탁 수하물',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == bag.name) return;

    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 정보가 없어 가방 이름을 바꿀 수 없어요.'),
        ),
      );
      return;
    }

    try {
      await packingProvider.renameBagOnServer(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        bagId: bagId,
        newName: trimmed,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${bag.name}" → "$trimmed" 로 이름을 바꿨어요.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가방 이름 변경에 실패했어요: $e')),
      );
    }
  }

  // 🗑 가방 삭제 (서버 + 로컬)
  Future<void> _confirmDeleteBag(BuildContext context, String bagId) async {
    final packingProvider = context.read<PackingProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    final bag = packingProvider.bags.firstWhere((b) => b.id == bagId);

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('가방 삭제'),
          content: Text(
            '"${bag.name}" 가방을 삭제할까요?\n'
                '이 가방에 담긴 아이템도 함께 삭제돼요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (deviceUuid == null || deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 정보가 없어 가방을 삭제할 수 없어요.'),
        ),
      );
      return;
    }

    try {
      await packingProvider.deleteBagOnServer(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        bagId: bagId,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${bag.name}" 가방을 삭제했어요.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가방 삭제에 실패했어요: $e')),
      );
    }
  }
}

/// 검색창 (상단 AppBar에서 이미 검색을 보여주면 showSearch=false로 숨김)
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.onSurface;

    final neutralBorder = scheme.outline.withOpacity(0.6);
    final neutralBorderFocused = scheme.outline;

    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        return TextField(
          decoration: InputDecoration(
            hintText: '물건 검색...',
            hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceVariant.withOpacity(0.12),
            prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: neutralBorderFocused, width: 1),
            ),
          ),
          cursorColor: textColor.withOpacity(0.8),
          onChanged: packingProvider.setSearchQuery,
        );
      },
    );
  }
}

/// 상단 여행 요약 카드 (여행 이름 / 목적지 / 가방·아이템 개수 표시 + ⋯)
class TripSummaryCard extends StatelessWidget {
  final Trip trip;
  final PackingProvider packing;
  final VoidCallback onManageBags;

  const TripSummaryCard({
    super.key,
    required this.trip,
    required this.packing,
    required this.onManageBags,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalItems =
    packing.bags.fold<int>(0, (sum, b) => sum + b.items.length);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: cs.primaryContainer.withOpacity(0.14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 왼쪽 아이콘 뱃지
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.luggage_rounded,
                size: 22,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),

            // 가운데 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.destination,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '가방 ${packing.bags.length}개 · 아이템 $totalItems개',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 오른쪽 ⋯ 버튼 (바로 가방 관리 바텀시트 열기)
            IconButton(
              tooltip: '가방 관리',
              icon: const Icon(Icons.more_vert),
              color: cs.onSurfaceVariant,
              onPressed: onManageBags,
            ),
          ],
        ),
      ),
    );
  }
}

/// 가방 탭 + TabBarView(아이템 리스트)
class _BagTabs extends StatelessWidget {
  const _BagTabs();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bags = packingProvider.bags;

        // DefaultTabController 없으면 렌더하지 않음
        final controller = DefaultTabController.maybeOf(context);
        if (controller == null) return const SizedBox.shrink();

        // 1) 기본 선택 인덱스는 selectedBag 기준
        final selectedId = packingProvider.selectedBag;
        int selectedIndex = 0;
        if (selectedId.isNotEmpty) {
          final idx = bags.indexWhere((b) => b.id == selectedId);
          if (idx >= 0) selectedIndex = idx;
        }

        // 2) 검색어가 있을 경우, 검색 결과가 있는 첫 가방으로 선택 인덱스를 덮어쓴다
        final q = packingProvider.searchQuery.trim().toLowerCase();
        if (q.isNotEmpty) {
          for (int i = 0; i < bags.length; i++) {
            final bag = bags[i];
            final hasMatch = bag.items.any((PackingItem item) {
              final name = item.name.toLowerCase();
              final category = item.category.toLowerCase();
              final location = item.location?.toLowerCase() ?? '';
              return name.contains(q) ||
                  category.contains(q) ||
                  location.contains(q);
            });
            if (hasMatch) {
              selectedIndex = i;
              break;
            }
          }
        }

        // 3) TabController와 Provider 의 선택 상태를 실제로 동기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.length == bags.length &&
              controller.index != selectedIndex) {
            controller.index = selectedIndex;

            final newId = bags[selectedIndex].id;
            if (packingProvider.selectedBag != newId) {
              packingProvider.setSelectedBag(newId);
            }
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 탭 + 오른쪽 가방 추가 버튼
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    isScrollable: true,
                    tabs: [
                      for (final bag in bags) Tab(text: bag.name),
                    ],
                    onTap: (index) =>
                        packingProvider.setSelectedBag(bags[index].id),
                  ),
                ),
                IconButton(
                  tooltip: '가방 추가',
                  icon: const Icon(Icons.add),
                  color: cs.primary,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddBagDialog(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 아래는 탭별 아이템 리스트 (화면 나머지 전체 차지)
            Expanded(
              child: TabBarView(
                children: [
                  for (final bag in bags) ItemList(bagId: bag.id),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
