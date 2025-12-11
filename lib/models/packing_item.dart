// lib/models/packing_item.dart

class PackingItem {
  final String id;       // 서버 item_id (string 으로 변환)
  final String name;     // 사람이 읽는 이름
  final String category; // 서버 category 없으면 "기타"
  final bool packed;     // status == done/packed
  final String bagId;    // 서버 bag_id (문자열)
  final String? location;
  final String? weight;
  final String? notes;

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

  /// ========= 서버 JSON 파서 (핵심 수정) =========
  factory PackingItem.fromServerJson(Map<String, dynamic> json) {
    // preview_snapshot
    final previewSnapshot =
    json['preview_snapshot'] as Map<String, dynamic>?;

    final previewResponse =
    previewSnapshot?['preview_response'] as Map<String, dynamic>?;

    // resolved { label, canonical }
    final resolved =
    previewResponse?['resolved'] as Map<String, dynamic>?;
    final resolvedLabel = resolved?['label']?.toString();
    final resolvedCanonical = resolved?['canonical']?.toString();

    // narration.title
    final narration =
    previewResponse?['narration'] as Map<String, dynamic>?;
    final narrationTitle = narration?['title']?.toString();

    final snapshotNarration =
    previewSnapshot?['narration'] as Map<String, dynamic>?;
    final snapshotNarrationTitle =
    snapshotNarration?['title']?.toString();

    // engine canonical
    final engine =
    previewResponse?['engine'] as Map<String, dynamic>?;
    final engineCanonical = engine?['canonical']?.toString();

    final engineResponse =
    previewSnapshot?['engine_response'] as Map<String, dynamic>?;
    final engineResponseCanonical =
    engineResponse?['canonical']?.toString();

    // top-level
    final userLabel = json['user_label']?.toString();
    final label = json['label']?.toString();
    final topTitle = json['title']?.toString();
    final topCanonical = json['canonical']?.toString();

    // canonical 통합
    final canonical = resolvedCanonical ??
        engineCanonical ??
        engineResponseCanonical ??
        topCanonical ??
        topTitle ??
        '';

    // 화면 표시 이름 선택
    String displayName;

    if (userLabel != null && userLabel.trim().isNotEmpty) {
      displayName = userLabel.trim();
    } else if (label != null && label.trim().isNotEmpty) {
      displayName = label.trim();
    } else if (resolvedLabel != null && resolvedLabel.trim().isNotEmpty) {
      displayName = resolvedLabel.trim();
    } else if (narrationTitle != null && narrationTitle.trim().isNotEmpty) {
      displayName = narrationTitle.trim();
    } else if (snapshotNarrationTitle != null &&
        snapshotNarrationTitle.trim().isNotEmpty) {
      displayName = snapshotNarrationTitle.trim();
    } else if (topTitle != null && topTitle.trim().isNotEmpty) {
      displayName = topTitle.trim();
    } else {
      displayName = canonical;
    }

    // packed 여부 판정
    final status = json['status']?.toString() ?? 'todo';
    final isPacked =
        status == 'done' || status == 'packed' || status == 'complete';

    // 핵심: bag_id 반드시 문자열
    final bagId = (json['bag_id'] ?? '').toString();

    return PackingItem(
      id: (json['item_id'] ?? json['id']).toString(),
      name: displayName,
      category: json['category']?.toString() ?? '기타',
      packed: isPacked,
      bagId: bagId,
      location: json['location']?.toString(),
      weight: json['weight']?.toString(),
      notes: json['note']?.toString(),
    );
  }
}
