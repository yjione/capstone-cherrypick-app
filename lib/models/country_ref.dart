//lib/models/country_ref.dart
// lib/models/country_ref.dart

class CountryRef {
  final String code;        // 예: KR
  final String nameEn;
  final String nameKo;
  final String regionGroup;

  CountryRef({
    required this.code,
    required this.nameEn,
    required this.nameKo,
    required this.regionGroup,
  });

  factory CountryRef.fromJson(Map<String, dynamic> json) {
    return CountryRef(
      code: json['code'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameKo: json['name_ko'] as String? ?? '',
      regionGroup: json['region_group'] as String? ?? '',
    );
  }
}
