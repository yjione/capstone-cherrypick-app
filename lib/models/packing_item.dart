// lib/models/packing_item.dart

class PackingItem {
  final String id;       // 서버 item_id (string 으로 변환)
  final String name;     // 서버 title
  final String category; // 서버에는 없어서 기본값 '기타' 등으로 세팅
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
}
