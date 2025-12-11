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
        final bool isEmpty = filteredItems.isEmpty;
        final cs = Theme.of(context).colorScheme;

        // 리스트 / 빈 상태 본문
        Widget body;
        if (isEmpty) {
          body = Padding(
            // 아래쪽에 FAB가 있으니까 여백 조금 줌
            padding: const EdgeInsets.only(bottom: 96),
            child: _EmptyState(
              hasSearchQuery: packingProvider.searchQuery.isNotEmpty,
              onAddItem: () => _showAddItemDialog(context, bagId),
            ),
          );
        } else {
          body = ListView.builder(
            padding: const EdgeInsets.only(bottom: 96), // FAB 안 가리도록
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return ItemCard(
                item: item,
                bagId: bagId,
              );
            },
          );
        }

        return Stack(
          children: [
            // 본문(아이템 리스트 / 빈 상태)
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 상단에 "n개 아이템" 칩만 작게
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${bag.items.length}개 아이템',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Expanded(child: body),
                ],
              ),
            ),

            // 하단 중앙 FAB 스타일 아이템 추가 버튼
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // 👉 16 → 24 로 살짝 위로
                padding: const EdgeInsets.only(bottom: 24),
                child: FilledButton.icon(
                  onPressed: () => _showAddItemDialog(context, bagId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('아이템 추가'),
                  style: FilledButton.styleFrom(
                    // 👉 세로 패딩 살짝 줄여서 더 슬림하게
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 4,
                    shadowColor: cs.primary.withOpacity(0.25),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================== 아이템 추가 다이얼로그 + 미리보기 호출 ==================

  Future<void> _showAddItemDialog(BuildContext context, String bagId) async {
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

// ================== 빈 상태 위젯 ==================

class _EmptyState extends StatelessWidget {
  final bool hasSearchQuery;
  final VoidCallback onAddItem;

  const _EmptyState({
    required this.hasSearchQuery,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? '검색 결과가 없습니다' : '아직 짐을 안 싸셨네요!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery
                ? '다른 검색어를 시도해보세요'
                : '이번 여행에 꼭 챙길 물건들을\n하나씩 추가해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ================== 아이템 카드 ==================

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
    final cs = Theme.of(context).colorScheme;

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
                onChanged: (_) async {
                  // ✅ 로컬만 바꾸지 말고 서버까지 PATCH
                  final device = context.read<DeviceProvider>();
                  final uuid = device.deviceUuid;
                  final token = device.deviceToken;

                  if (uuid == null || token == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('기기 정보가 없어 상태를 저장할 수 없어요.'),
                      ),
                    );
                    return;
                  }

                  try {
                    await context.read<PackingProvider>().toggleItemPackedOnServer(
                      deviceUuid: uuid,
                      deviceToken: token,
                      bagId: bagId,
                      itemId: item.id,
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('짐 상태 저장에 실패했어요. 잠시 후 다시 시도해 주세요.'),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration:
                        item.packed ? TextDecoration.lineThrough : null,
                        color:
                        item.packed ? cs.onSurfaceVariant : cs.onSurface,
                      ),
                    ),
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
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
                color: cs.error,
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

    final api = ItemApiService();

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
