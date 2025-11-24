// lib/models/airport_ref.dart

class AirportRef {
  final String iataCode;
  final String icaoCode;
  final String nameEn;
  final String nameKo;
  final String cityEn;
  final String cityKo;
  final String countryCode;
  final String regionGroup;

  AirportRef({
    required this.iataCode,
    required this.icaoCode,
    required this.nameEn,
    required this.nameKo,
    required this.cityEn,
    required this.cityKo,
    required this.countryCode,
    required this.regionGroup,
  });

  factory AirportRef.fromJson(Map<String, dynamic> json) {
    return AirportRef(
      iataCode: json['iata_code'] as String? ?? '',
      icaoCode: json['icao_code'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameKo: json['name_ko'] as String? ?? '',
      cityEn: json['city_en'] as String? ?? '',
      cityKo: json['city_ko'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      regionGroup: json['region_group'] as String? ?? '',
    );
  }
}
