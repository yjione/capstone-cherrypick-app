// lib/models/bag.dart
import 'packing_item.dart';

class Bag {
  final String id;            // 서버 bag_id (string 으로 변환해서 사용)
  final String name;
  /// 서버 기준: 'carry_on', 'checked', 'custom'
  final String type;
  final String color;
  final List<PackingItem> items;

  Bag({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.items = const [],
  });

  Bag copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    List<PackingItem>? items,
  }) {
    return Bag(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory Bag.fromJson(Map<String, dynamic> json) {
    return Bag(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) =>
          PackingItem.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}
