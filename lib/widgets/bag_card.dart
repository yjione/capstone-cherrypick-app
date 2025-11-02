// lib/widgets/bag_card.dart
import 'package:flutter/material.dart';
import '../models/bag.dart' as model;

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
    final progress = totalCount > 0 ? (packedCount / totalCount * 100).round() : 0;

    // 선택/비선택 스타일 (중립색)
    final Color borderColor = widget.isSelected
        ? cs.outlineVariant.withOpacity(0.55)
        : cs.outlineVariant.withOpacity(0.28);
    final double borderWidth = widget.isSelected ? 2.0 : 1.0;
    final double blur = widget.isSelected ? 10 : 4;
    final Color shadow = Colors.black.withOpacity(widget.isSelected ? 0.08 : 0.04);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        // ✔︎ 배경은 항상 하얀색으로 고정 (surface가 약간 톤이 있을 수 있어서 분리)
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
          splashColor: cs.primary.withOpacity(0.06), // 아주 은은한 터치 피드백
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 아이콘/이모지 제거 — 텍스트만 깔끔하게
                Text(
                  widget.bag.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
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
}
