// lib/models/item_preview_models.dart
import 'dart:convert';

class PreviewResponse {
  final Resolved resolved;
  final Narration? narration;
  final List<AiTip> aiTips;

  PreviewResponse({
    required this.resolved,
    required this.narration,
    required this.aiTips,
  });

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    return PreviewResponse(
      resolved: Resolved.fromJson(json['resolved'] as Map<String, dynamic>),
      narration: json['narration'] != null
          ? Narration.fromJson(json['narration'] as Map<String, dynamic>)
          : null,
      aiTips: (json['ai_tips'] as List<dynamic>? ?? [])
          .map((e) => AiTip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static PreviewResponse fromJsonString(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return PreviewResponse.fromJson(map);
  }
}

class Resolved {
  final String label;
  final String canonical;
  final String locale;

  Resolved({
    required this.label,
    required this.canonical,
    required this.locale,
  });

  factory Resolved.fromJson(Map<String, dynamic> json) {
    return Resolved(
      label: json['label'] as String,
      canonical: json['canonical'] as String,
      locale: json['locale'] as String,
    );
  }
}

class Narration {
  final String title;
  final CardInfo carryOnCard;
  final CardInfo checkedCard;
  final List<String> bullets;
  final List<String> badges;
  final String? footnote;
  final List<String> sources;

  Narration({
    required this.title,
    required this.carryOnCard,
    required this.checkedCard,
    required this.bullets,
    required this.badges,
    this.footnote,
    required this.sources,
  });

  factory Narration.fromJson(Map<String, dynamic> json) {
    return Narration(
      title: json['title'] as String,
      carryOnCard:
      CardInfo.fromJson(json['carry_on_card'] as Map<String, dynamic>),
      checkedCard:
      CardInfo.fromJson(json['checked_card'] as Map<String, dynamic>),
      bullets: (json['bullets'] as List<dynamic>).cast<String>(),
      badges: (json['badges'] as List<dynamic>).cast<String>(),
      footnote: json['footnote'] as String?,
      sources: (json['sources'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}

class CardInfo {
  final String statusLabel; // "허용" | "조건부 허용" | "금지"
  final String shortReason;

  CardInfo({
    required this.statusLabel,
    required this.shortReason,
  });

  factory CardInfo.fromJson(Map<String, dynamic> json) {
    return CardInfo(
      statusLabel: json['status_label'] as String,
      shortReason: json['short_reason'] as String,
    );
  }
}

class AiTip {
  final String id;
  final String text;
  final List<String> tags;
  final double relevance;

  AiTip({
    required this.id,
    required this.text,
    required this.tags,
    required this.relevance,
  });

  factory AiTip.fromJson(Map<String, dynamic> json) {
    return AiTip(
      id: json['id'] as String,
      text: json['text'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      relevance: (json['relevance'] as num).toDouble(),
    );
  }
}
