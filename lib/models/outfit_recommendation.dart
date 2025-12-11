// lib/models/outfit_recommendation.dart

class OutfitRecommendation {
  final String title;
  final String description;
  final List<OutfitItem> items;
  final OutfitFacts facts;

  OutfitRecommendation({
    required this.title,
    required this.description,
    required this.items,
    required this.facts,
  });

  factory OutfitRecommendation.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendation(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OutfitItem.fromJson(e))
          .toList(),
      facts: OutfitFacts.fromJson(json['facts'] ?? {}),
    );
  }
}

class OutfitItem {
  final String key;
  final String label;
  final String priority; // high / medium / low
  final String why;

  OutfitItem({
    required this.key,
    required this.label,
    required this.priority,
    required this.why,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) {
    return OutfitItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      why: json['why'] as String? ?? '',
    );
  }
}

class OutfitFacts {
  final List<String> dateSpan;
  final TemperatureInfo tempC;
  final double precipMm;

  OutfitFacts({
    required this.dateSpan,
    required this.tempC,
    required this.precipMm,
  });

  factory OutfitFacts.fromJson(Map<String, dynamic> json) {
    return OutfitFacts(
      dateSpan: (json['date_span'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      tempC: TemperatureInfo.fromJson(json['temp_c'] ?? {}),
      precipMm: (json['precip_mm'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TemperatureInfo {
  final double min;
  final double max;
  final double mean;

  TemperatureInfo({
    required this.min,
    required this.max,
    required this.mean,
  });

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) {
    return TemperatureInfo(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      max: (json['max'] as num?)?.toDouble() ?? 0,
      mean: (json['mean'] as num?)?.toDouble() ?? 0,
    );
  }
}
