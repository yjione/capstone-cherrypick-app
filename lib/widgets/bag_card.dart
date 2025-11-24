// lib/widgets/bag_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bag.dart' as model;
import '../providers/packing_provider.dart';
import '../providers/device_provider.dart';

enum _BagMenuAction { edit, delete }

class BagCard extends StatefulWidget {
  final model.Bag bag;
  final bool isSelected;
  final VoidCallback onTap;

  const BagCard({
    super.key,
    required this.bag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<BagCard> createState() => _BagCardState();
}

class _BagCardState extends State<BagCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final packedCount = widget.bag.items.where((item) => item.packed).length;
    final totalCount = widget.bag.items.length;
    final progress =
    totalCount > 0 ? (packedCount / totalCount * 100).round() : 0;

    // 선택/비선택 스타일 (중립색)
    final Color borderColor = widget.isSelected
        ? cs.outlineVariant.withOpacity(0.55)
        : cs.outlineVariant.withOpacity(0.28);
    final double borderWidth = widget.isSelected ? 2.0 : 1.0;
    final double blur = widget.isSelected ? 10 : 4;
    final Color shadow =
    Colors.black.withOpacity(widget.isSelected ? 0.08 : 0.04);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: blur,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: cs.primary.withOpacity(0.06),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 가방 이름 + 더보기(...)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        widget.bag.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<_BagMenuAction>(
                      icon: Icon(
                        Icons.more_vert,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      onSelected: (action) async {
                        switch (action) {
                          case _BagMenuAction.edit:
                            await _showRenameDialog(context);
                            break;
                          case _BagMenuAction.delete:
                            await _confirmDeleteBag(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _BagMenuAction.edit,
                          child: Text('수정하기'),
                        ),
                        PopupMenuItem(
                          value: _BagMenuAction.delete,
                          child: Text('삭제하기'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 진행 상태 배지
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: progress == 100 && totalCount > 0
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$packedCount/$totalCount 완료',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: progress == 100 && totalCount > 0
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 이름 수정 다이얼로그 + 서버 연동
  Future<void> _showRenameDialog(BuildContext context) async {
    final packingProvider = context.read<PackingProvider>();
    final device = context.read<DeviceProvider>();
    final cs = Theme.of(context).colorScheme;

    if (device.deviceUuid == null || device.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 정보가 없어 서버와 통신할 수 없어요. 앱을 다시 실행해 주세요.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: widget.bag.name);

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('가방 이름 수정'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '가방 이름을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  // 빈 이름은 허용하지 않음
                  return;
                }
                Navigator.pop(context, text);
              },
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result == null) return; // 사용자가 취소

    try {
      await packingProvider.renameBagOnServer(
        deviceUuid: device.deviceUuid!,
        deviceToken: device.deviceToken!,
        bagId: widget.bag.id,
        newName: result,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('가방 이름 수정에 실패했어요. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }

  /// 삭제 확인 다이얼로그 + 서버 연동
  Future<void> _confirmDeleteBag(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final packingProvider = context.read<PackingProvider>();
    final device = context.read<DeviceProvider>();

    if (device.deviceUuid == null || device.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기기 정보가 없어 서버와 통신할 수 없어요. 앱을 다시 실행해 주세요.'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('가방 삭제'),
          content: Text('"${widget.bag.name}" 가방을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
              ),
              onPressed: () async {
                Navigator.pop(context); // 다이얼로그 닫기

                try {
                  await packingProvider.deleteBagOnServer(
                    deviceUuid: device.deviceUuid!,
                    deviceToken: device.deviceToken!,
                    bagId: widget.bag.id,
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('가방 삭제에 실패했어요. 잠시 후 다시 시도해 주세요.'),
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
