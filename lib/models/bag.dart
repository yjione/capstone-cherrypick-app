// lib/models/bag.dart
import 'packing_item.dart';

class Bag {
  final String id;            // 서버 bag_id (string)
  final String name;
  final String type;          // 'carry_on' | 'checked' | 'custom'
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

  factory Bag.fromServerJson(Map<String, dynamic> json) {
    return Bag(
      id: (json['bag_id'] ?? json['id']).toString(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'custom',
      color: json['color']?.toString() ?? '#FFFFFF',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((itemJson) =>
          PackingItem.fromServerJson(itemJson as Map<String, dynamic>))
          .toList(),
    );
  }
}
