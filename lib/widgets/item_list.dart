// lib/widgets/item_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/packing_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../providers/preview_provider.dart';

import '../models/packing_item.dart' as model;
import '../models/preview_request.dart';
import '../models/preview_response.dart';

import '../widgets/add_item_dialog.dart';
import '../service/item_api.dart';
import '../screens/item_preview_screen.dart';

class ItemList extends StatelessWidget {
  final String bagId;

  const ItemList({super.key, required this.bagId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProvider>(
      builder: (context, packingProvider, child) {
        final bag = packingProvider.bags.firstWhere((bag) => bag.id == bagId);
        final filteredItems = packingProvider.getFilteredItems(bagId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      bag.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${bag.items.length}개 아이템',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(context, bagId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('아이템 추가'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyState(
                hasSearchQuery:
                packingProvider.searchQuery.isNotEmpty,
                onAddItem: () => _showAddItemDialog(context, bagId),
              )
                  : ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return ItemCard(
                    item: item,
                    bagId: bagId,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddItemDialog(BuildContext context, String bagId) async {
    // 1) 다이얼로그에서 입력값 받아오기
    final result = await showDialog<NewItemInput>(
      context: context,
      builder: (context) => AddItemDialog(bagId: bagId),
    );

    if (result == null) return;

    final tripProvider = context.read<TripProvider>();
    final deviceProvider = context.read<DeviceProvider>();
    final previewProvider = context.read<PreviewProvider>();

    final currentTrip = tripProvider.currentTrip;
    final deviceUuid = deviceProvider.deviceUuid;
    final deviceToken = deviceProvider.deviceToken;

    if (currentTrip == null || deviceUuid == null || deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행/기기 정보가 없어 아이템을 저장할 수 없어요.')),
      );
      return;
    }

    // 2) PreviewRequest 만들기
    String extractAirportCode(String destination) {
      final start = destination.indexOf('(');
      final end = destination.indexOf(')');
      if (start != -1 && end != -1 && end > start + 1) {
        final inside = destination.substring(start + 1, end).trim();
        final isCode =
            inside.length == 3 && RegExp(r'^[A-Za-z]+$').hasMatch(inside);
        if (isCode) return inside.toUpperCase();
      }
      final trimmed = destination.trim();
      if (trimmed.length >= 3) {
        return trimmed.substring(0, 3).toUpperCase();
      }
      return 'NRT';
    }

    const fromAirport = 'ICN';
    final toAirport = extractAirportCode(currentTrip.destination);
    const airlineCode = 'KE';
    const cabinClass = 'economy';

    final reqId = DateTime.now().millisecondsSinceEpoch.toString();

    final previewRequest = PreviewRequest(
      label: result.name,
      locale: 'ko-KR',
      reqId: reqId,
      itinerary: Itinerary(
        from: fromAirport,
        to: toAirport,
        via: const [],
        rescreening: false,
      ),
      segments: [
        Segment(
          leg: '$fromAirport-$toAirport',
          operating: airlineCode,
          cabinClass: cabinClass,
        ),
      ],
      itemParams: ItemParams(
        volumeMl: 0,
        wh: 0,
        count: 1,
        abvPercent: 0,
        weightKg: 0,
        bladeLengthCm: 0,
      ),
      dutyFree: DutyFree(
        isDf: false,
        stebSealed: false,
      ),
    );

    // 3) Preview API 호출
    try {
      await previewProvider.fetchPreview(previewRequest);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('미리보기 요청 실패: $e')),
      );
      return;
    }

    final PreviewResponse? preview = previewProvider.preview;
    if (preview == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미리보기 결과를 불러오지 못했어요.')),
      );
      return;
    }

    // 4) 미리보기 화면으로 이동 (여기서 "추가 / 취소" 선택)
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemPreviewScreen(
            data: preview,
            allowSave: true,
            tripId: int.parse(currentTrip.id),
            bagId: int.parse(bagId),
            deviceUuid: deviceUuid,
            deviceToken: deviceToken,
            userLabel: result.name,
          ),
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onAddItem;

  const _EmptyState({
    required this.hasSearchQuery,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? '검색 결과가 없습니다' : '아이템이 없습니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery ? '다른 검색어를 시도해보세요' : '첫 번째 아이템을 추가해보세요',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!hasSearchQuery) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('아이템 추가'),
            ),
          ],
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final model.PackingItem item;
  final String bagId;

  const ItemCard({
    super.key,
    required this.item,
    required this.bagId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openPreview(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: item.packed,
                onChanged: (_) {
                  Provider.of<PackingProvider>(context, listen: false)
                      .toggleItemPacked(bagId, item.id);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: item.packed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.packed
                                  ? Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                        // 카테고리 태그(예: '기타')는 당분간 숨김
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //       horizontal: 8, vertical: 2),
                        //   decoration: BoxDecoration(
                        //     color: Theme.of(context)
                        //         .colorScheme
                        //         .surfaceContainerHighest,
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   child: Text(
                        //     item.category,
                        //     style: TextStyle(
                        //       fontSize: 12,
                        //       color: Theme.of(context)
                        //           .colorScheme
                        //           .onSurfaceVariant,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  Provider.of<PackingProvider>(context, listen: false)
                      .removeItem(bagId, item.id);
                },
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) async {
    final device = context.read<DeviceProvider>();

    if (device.deviceUuid == null || device.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 정보가 없어 규정 미리보기를 열 수 없어요.'),
        ),
      );
      return;
    }

    final itemId = int.tryParse(item.id);
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버에 저장되지 않은 아이템입니다.'),
        ),
      );
      return;
    }

    final api = ItemApiService(); //baseUrl 인자 없이 사용

    try {
      final preview = await api.getItemPreview(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        itemId: itemId,
      );

      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ItemPreviewScreen(
            data: preview,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이템 규정을 불러오지 못했어요: $e')),
      );
    }
  }
}
