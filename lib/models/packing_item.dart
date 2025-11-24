// lib/models/packing_item.dart

class PackingItem {
  final String id;       // 서버 item_id (string 으로 변환)
  /// ✅ 화면에 보여줄 이름
  ///    우선순위: user_label > label > resolved_label > title > canonical
  final String name;
  final String category; // 서버에 없으면 '기타'
  final bool packed;     // 서버 status == 'done'/'packed' 일 때 true
  final String bagId;    // 서버 bag_id
  final String? location;
  final String? weight;
  final String? notes;   // 서버 note

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.packed,
    required this.bagId,
    this.location,
    this.weight,
    this.notes,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? packed,
    String? bagId,
    String? location,
    String? weight,
    String? notes,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      packed: packed ?? this.packed,
      bagId: bagId ?? this.bagId,
      location: location ?? this.location,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'packed': packed,
      'bagId': bagId,
      'location': location,
      'weight': weight,
      'notes': notes,
    };
  }

  /// ✅ 앱 내부에서만 쓰던 단순 JSON용 (필요하면 유지)
  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      packed: json['packed'] as bool,
      bagId: json['bagId'] as String,
      location: json['location'] as String?,
      weight: json['weight'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// ✅ 서버에서 내려오는 아이템 JSON 파서
  ///  - user_label → label → resolved_label → title → canonical 순으로
  ///    사람이 읽기 좋은 이름을 선택
  /// ✅ 서버에서 내려오는 아이템 JSON 파서
  ///  - 우선순위: user_label → label → resolved.label → narration.title → title → canonical
  factory PackingItem.fromServerJson(Map<String, dynamic> json) {
    // ---------- 1. preview_snapshot 꺼내기 ----------
    final previewSnapshot =
    json['preview_snapshot'] as Map<String, dynamic>?;

    final previewResponse =
    previewSnapshot?['preview_response'] as Map<String, dynamic>?;

    // resolved { label, canonical, ... }
    final resolved =
    previewResponse?['resolved'] as Map<String, dynamic>?;

    final resolvedLabel = resolved?['label']?.toString();
    final resolvedCanonical = resolved?['canonical']?.toString();

    // narration.title (preview_response 안쪽)
    final narration =
    previewResponse?['narration'] as Map<String, dynamic>?;
    final narrationTitle = narration?['title']?.toString();

    // narration.title (preview_snapshot 바로 아래쪽)
    final snapshotNarration =
    previewSnapshot?['narration'] as Map<String, dynamic>?;
    final snapshotNarrationTitle =
    snapshotNarration?['title']?.toString();

    // engine/engine_response 쪽 canonical
    final engine =
    previewResponse?['engine'] as Map<String, dynamic>?;
    final engineCanonical = engine?['canonical']?.toString();

    final engineResponse =
    previewSnapshot?['engine_response'] as Map<String, dynamic>?;
    final engineResponseCanonical =
    engineResponse?['canonical']?.toString();

    // 리스트 응답 top-level 값들
    final userLabel = json['user_label']?.toString(); // 미래 대비
    final label = json['label']?.toString();
    final topTitle = json['title']?.toString(); // 현재는 apparel_clothing 같은 값
    final topCanonical = json['canonical']?.toString();

    // ---------- 2. canonical 추출 (내부용) ----------
    final canonical = resolvedCanonical ??
        engineCanonical ??
        engineResponseCanonical ??
        topCanonical ??
        topTitle ??
        '';

    // ---------- 3. 화면에 보여줄 이름(displayName) 결정 ----------
    String displayName;

    if (userLabel != null && userLabel.trim().isNotEmpty) {
      displayName = userLabel.trim();
    } else if (label != null && label.trim().isNotEmpty) {
      displayName = label.trim();
    } else if (resolvedLabel != null && resolvedLabel.trim().isNotEmpty) {
      displayName = resolvedLabel.trim(); // "맨투맨", "충전기", "후드집업"
    } else if (narrationTitle != null &&
        narrationTitle.trim().isNotEmpty) {
      displayName = narrationTitle.trim();
    } else if (snapshotNarrationTitle != null &&
        snapshotNarrationTitle.trim().isNotEmpty) {
      displayName = snapshotNarrationTitle.trim();
    } else if (topTitle != null && topTitle.trim().isNotEmpty) {
      displayName = topTitle.trim();
    } else {
      displayName = canonical; // 그래도 없으면 마지막으로 canonical
    }

    // ---------- 4. packed 여부 ----------
    final status = json['status']?.toString() ?? 'todo';
    final isPacked =
        status == 'done' || status == 'packed' || status == 'complete';

    // ---------- 5. 최종 PackingItem 생성 ----------
    return PackingItem(
      id: (json['item_id'] ?? json['id']).toString(),
      name: displayName,
      category: json['category']?.toString() ?? '기타',
      packed: isPacked,
      bagId: (json['bag_id'] ?? '').toString(),
      location: json['location']?.toString(),
      weight: json['weight']?.toString(),
      notes: json['note']?.toString(),
    );
  }

}
