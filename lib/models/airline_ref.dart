// lib/models/airline_ref.dart
class AirlineRef {
  final String code; // 항공사 코드 (예: KE, OZ)
  final String name; // 항공사 이름 (예: 대한항공)

  AirlineRef({
    required this.code,
    required this.name,
  });

  factory AirlineRef.fromJson(Map<String, dynamic> json) {
    return AirlineRef(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
