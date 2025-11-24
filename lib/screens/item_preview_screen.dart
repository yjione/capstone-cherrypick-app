// lib/screens/item_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/preview_response.dart';
import '../widgets/item_status_styles.dart';
import '../service/item_api.dart';
import '../providers/packing_provider.dart';

class ItemPreviewScreen extends StatefulWidget {
  final PreviewResponse data;

  /// true : "아이템 리스트에 추가 / 취소" 버튼을 보여주고, 저장까지 담당
  /// false: 규정만 보여주는 읽기 전용 화면
  final bool allowSave;

  /// allowSave=true 일 때만 쓰는 값들
  final int? tripId;
  final int? bagId;
  final String? deviceUuid;
  final String? deviceToken;

  /// 사용자가 다이얼로그에서 직접 입력한 이름 (예: "옷")
  final String? userLabel;

  const ItemPreviewScreen({
    super.key,
    required this.data,
    this.allowSave = false,
    this.tripId,
    this.bagId,
    this.deviceUuid,
    this.deviceToken,
    this.userLabel,
  });

  @override
  State<ItemPreviewScreen> createState() => _ItemPreviewScreenState();
}

class _ItemPreviewScreenState extends State<ItemPreviewScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final narration = widget.data.narration;

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

    final tips = [...widget.data.aiTips]
      ..sort((a, b) => b.relevance.compareTo(a.relevance));

    // ✅ 화면에 보여줄 이름: 내가 입력한 userLabel > 엔진이 준 title
    final displayTitle =
    (widget.userLabel != null && widget.userLabel!.isNotEmpty)
        ? widget.userLabel!
        : narration.title;

    // ✅ 칩 텍스트들: userLabel → resolved.label → canonical (중복 제거)
    final String? userLabel = widget.userLabel?.trim();
    final String resolvedLabel = widget.data.resolved.label.trim();
    final String canonical = widget.data.resolved.canonical.trim();

    final List<String> chips = [];
    void addChip(String? value) {
      if (value == null) return;
      final v = value.trim();
      if (v.isEmpty) return;
      if (!chips.contains(v)) {
        chips.add(v);
      }
    }

    addChip(userLabel);
    addChip(resolvedLabel);
    addChip(canonical);

    return Scaffold(
      appBar: AppBar(title: const Text('아이템 규정 미리보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // A. 헤더 (이미지 제거 + 칩 중복 제거 버전)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (chips.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: chips.map((t) => _SmallChip(t)).toList(),
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
                        style: TextStyle(fontSize: 14, height: 1.4),
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
                  border: Border.all(color: Colors.grey.shade300),
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
          if (narration.sources.isNotEmpty || narration.footnote.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                if (narration.sources.isNotEmpty)
                  Text(
                    '출처: ${narration.sources.join(' · ')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                if (narration.footnote.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    narration.footnote,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),

      // 하단 버튼 영역
      bottomNavigationBar: widget.allowSave
          ? SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving ? null : _onConfirmSave,
                  child: _isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('아이템 리스트에 추가'),
                ),
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Future<void> _onConfirmSave() async {
    if (widget.tripId == null ||
        widget.bagId == null ||
        widget.deviceUuid == null ||
        widget.deviceToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('여행/기기 정보가 없어 저장할 수 없어요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ItemApiService();

      await api.saveItem(
        deviceUuid: widget.deviceUuid!,
        deviceToken: widget.deviceToken!,
        bagId: widget.bagId!,
        tripId: widget.tripId!,
        preview: widget.data,
        reqId: widget.data.engine.reqId,
        userLabel: widget.userLabel,
      );

      // 저장 후 가방/아이템 다시 로딩해서 리스트에도 반영
      final packingProvider = context.read<PackingProvider>();
      await packingProvider.loadBagsFromServer(
        tripId: widget.tripId!,
        deviceUuid: widget.deviceUuid!,
        deviceToken: widget.deviceToken!,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이템이 짐 리스트에 추가되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아이템 저장에 실패했어요: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _SmallChip extends StatelessWidget {
  final String text;
  const _SmallChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
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
