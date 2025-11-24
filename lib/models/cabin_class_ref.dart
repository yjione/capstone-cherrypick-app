// lib/models/cabin_class_ref.dart
class CabinClassRef {
  final String code;        // 예: "ECONOMY"
  final String name;        // 예: "Economy"
  final String? description;

  CabinClassRef({
    required this.code,
    required this.name,
    this.description,
  });

  factory CabinClassRef.fromJson(Map<String, dynamic> json) {
    return CabinClassRef(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
