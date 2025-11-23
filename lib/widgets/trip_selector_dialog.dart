// lib/widgets/trip_selector_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import '../providers/device_provider.dart';
import '../models/trip.dart';
import '../widgets/add_trip_dialog.dart';

class TripSelectorDialog extends StatelessWidget {
  const TripSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        return Dialog(
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '여행 선택',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // 여행 리스트
                ...tripProvider.trips.map(
                      (trip) => _TripItem(
                    trip: trip,
                    isSelected: tripProvider.currentTripId == trip.id,
                    onTap: () {
                      tripProvider.setCurrentTrip(trip.id);
                      Navigator.of(context).pop();
                    },
                    onDelete: tripProvider.trips.length > 1
                        ? () => _handleDeleteTrip(context, trip, tripProvider)
                        : null,
                  ),
                ),

                const SizedBox(height: 8),

                // 새 여행 추가 버튼
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => const AddTripDialog(),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withOpacity(0.28),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          '새 여행 추가',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 서버 삭제 + 확인 다이얼로그
Future<void> _handleDeleteTrip(
    BuildContext context,
    Trip trip,
    TripProvider tripProvider,
    ) async {
  final device = context.read<DeviceProvider>();

  final canDeleteLocally = tripProvider.trips.length > 1;
  final hasDeviceHeaders =
      device.deviceUuid != null && device.deviceToken != null;
  final canDelete = canDeleteLocally && hasDeviceHeaders;

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text('여행 삭제'),
        content: Text(
          !canDeleteLocally
              ? '마지막 남은 여행은 삭제할 수 없어요.\n새 여행을 추가한 후에 삭제해 주세요.'
              : !hasDeviceHeaders
              ? '기기 정보가 없어 서버와 통신할 수 없어요.\n앱을 다시 실행해 주세요.'
              : '"${trip.name}" 여행을 삭제할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          if (canDelete)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('삭제'),
              onPressed: () async {
                Navigator.pop(context); // 확인 다이얼로그 닫기

                try {
                  await tripProvider.deleteTrip(
                    deviceUuid: device.deviceUuid!,
                    deviceToken: device.deviceToken!,
                    tripId: trip.id,
                    purge: true,
                  );
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
            ),
        ],
      );
    },
  );
}

class _TripItem extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function()? onDelete;

  const _TripItem({
    required this.trip,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withOpacity(0.08) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? cs.primary.withOpacity(0.35) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(
          trip.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(trip.destination),
        trailing: onDelete != null
            ? IconButton(
          icon: const Icon(Icons.delete_outline),
          color: cs.error,
          onPressed: () async {
            await onDelete!();
          },
        )
            : null,
      ),
    );
  }
}
