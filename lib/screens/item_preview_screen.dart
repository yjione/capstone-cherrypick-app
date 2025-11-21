// lib/screens/item_preview_screen.dart
import 'package:flutter/material.dart';

// ✅ 여기만 수정: preview_response.dart로 변경
import '../models/preview_response.dart';

import '../widgets/item_status_styles.dart';

class ItemPreviewScreen extends StatelessWidget {
  final PreviewResponse data;

  const ItemPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final narration = data.narration;

    if (narration == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('아이템')),
        body: const Center(
          child: Text('판정 정보를 불러올 수 없습니다.'),
        ),
      );
    }

    final carryStatus =
    statusStyleMap[statusFromLabel(narration.carryOnCard.statusLabel)]!;
    final checkedStatus =
    statusStyleMap[statusFromLabel(narration.checkedCard.statusLabel)]!;

    final tips = [...data.aiTips]
      ..sort((a, b) => b.relevance.compareTo(a.relevance));

    return Scaffold(
      appBar: AppBar(title: const Text('아이템')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // A. 헤더
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽 썸네일: 헤어스프레이 실제 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/hairspray.png', // 이미지 경로
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              // 오른쪽 제목 + 뱃지
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      narration.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _SmallChip(data.resolved.label),
                        _SmallChip(data.resolved.canonical),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // B. 판정 카드 2개
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  label: '기내 수하물',
                  statusLabel: narration.carryOnCard.statusLabel,
                  shortReason: narration.carryOnCard.shortReason,
                  style: carryStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusCard(
                  label: '위탁 수하물',
                  statusLabel: narration.checkedCard.statusLabel,
                  shortReason: narration.checkedCard.shortReason,
                  style: checkedStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // C. 배지 영역
          if (narration.badges.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: narration.badges
                  .map(
                    (b) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    b,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // D. bullets
          if (narration.bullets.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: narration.bullets
                  .map(
                    (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style:
                        TextStyle(fontSize: 14, height: 1.4),
                      ),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // E. AI Tips
          if (tips.isNotEmpty) ...[
            const Text(
              '팁',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            ...tips.take(3).map(
                  (tip) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  tip.text,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // F. 출처 / 풋노트
          if (narration.sources.isNotEmpty || narration.footnote != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                if (narration.sources.isNotEmpty)
                  Text(
                    '출처: ${narration.sources.join(' · ')}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                if (narration.footnote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    narration.footnote!,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  const _SmallChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style:
        const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String statusLabel;
  final String shortReason;
  final StatusStyle style;

  const _StatusCard({
    required this.label,
    required this.statusLabel,
    required this.shortReason,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.text.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(style.icon, size: 16, color: style.text),
              const SizedBox(width: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: style.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shortReason,
            style: TextStyle(
              fontSize: 11,
              color: style.text.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
