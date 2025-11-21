// lib/models/preview_response.dart
class PreviewResponse {
  final String state;
  final Resolved resolved;
  final Engine engine;
  final Narration? narration;
  final List<AiTip> aiTips;
  final Flags flags;

  PreviewResponse({
    required this.state,
    required this.resolved,
    required this.engine,
    required this.narration,
    required this.aiTips,
    required this.flags,
  });

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    return PreviewResponse(
      state: json['state'] as String,
      resolved: Resolved.fromJson(json['resolved'] as Map<String, dynamic>),
      engine: Engine.fromJson(json['engine'] as Map<String, dynamic>),
      narration: json['narration'] != null
          ? Narration.fromJson(json['narration'] as Map<String, dynamic>)
          : null,
      aiTips: (json['ai_tips'] as List<dynamic>? ?? [])
          .map((e) => AiTip.fromJson(e as Map<String, dynamic>))
          .toList(),
      flags: Flags.fromJson(json['flags'] as Map<String, dynamic>),
    );
  }
}

// ---------- resolved ----------
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

// ---------- engine ----------
class Engine {
  final String reqId;
  final String canonical;
  final Decision decision;
  final Conditions conditions;
  final List<dynamic> sources;
  final List<dynamic> trace;
  final List<AiTip> aiTips;

  Engine({
    required this.reqId,
    required this.canonical,
    required this.decision,
    required this.conditions,
    required this.sources,
    required this.trace,
    required this.aiTips,
  });

  factory Engine.fromJson(Map<String, dynamic> json) {
    return Engine(
      reqId: json['req_id'] as String,
      canonical: json['canonical'] as String,
      decision: Decision.fromJson(json['decision'] as Map<String, dynamic>),
      conditions:
      Conditions.fromJson(json['conditions'] as Map<String, dynamic>),
      sources: (json['sources'] as List<dynamic>? ?? []),
      trace: (json['trace'] as List<dynamic>? ?? []),
      aiTips: (json['ai_tips'] as List<dynamic>? ?? [])
          .map((e) => AiTip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Decision {
  final DecisionSide carryOn;
  final DecisionSide checked;

  Decision({
    required this.carryOn,
    required this.checked,
  });

  factory Decision.fromJson(Map<String, dynamic> json) {
    return Decision(
      carryOn:
      DecisionSide.fromJson(json['carry_on'] as Map<String, dynamic>),
      checked: DecisionSide.fromJson(json['checked'] as Map<String, dynamic>),
    );
  }
}

class DecisionSide {
  final String status;
  final List<String> badges;
  final List<String> reasonCodes;

  DecisionSide({
    required this.status,
    required this.badges,
    required this.reasonCodes,
  });

  factory DecisionSide.fromJson(Map<String, dynamic> json) {
    return DecisionSide(
      status: json['status'] as String,
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      reasonCodes: (json['reason_codes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class Conditions {
  final Map<String, dynamic> carryOn;
  final Map<String, dynamic> checked;
  final Map<String, dynamic> common;

  Conditions({
    required this.carryOn,
    required this.checked,
    required this.common,
  });

  factory Conditions.fromJson(Map<String, dynamic> json) {
    return Conditions(
      carryOn: (json['carry_on'] as Map<String, dynamic>? ?? {}),
      checked: (json['checked'] as Map<String, dynamic>? ?? {}),
      common: (json['common'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// ---------- narration ----------
class Narration {
  final String title;
  final CardInfo carryOnCard;
  final CardInfo checkedCard;
  final List<dynamic> bullets;
  final List<dynamic> badges;
  final String footnote;
  final List<dynamic> sources;

  Narration({
    required this.title,
    required this.carryOnCard,
    required this.checkedCard,
    required this.bullets,
    required this.badges,
    required this.footnote,
    required this.sources,
  });

  factory Narration.fromJson(Map<String, dynamic> json) {
    return Narration(
      title: json['title'] as String,
      carryOnCard:
      CardInfo.fromJson(json['carry_on_card'] as Map<String, dynamic>),
      checkedCard:
      CardInfo.fromJson(json['checked_card'] as Map<String, dynamic>),
      bullets: (json['bullets'] as List<dynamic>? ?? []),
      badges: (json['badges'] as List<dynamic>? ?? []),
      footnote: json['footnote'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>? ?? []),
    );
  }
}

class CardInfo {
  final String statusLabel;
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

// ---------- ai tips ----------
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
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      relevance: (json['relevance'] as num).toDouble(),
    );
  }
}

// ---------- flags ----------
class Flags {
  final String? fallback;     // "classic_pipeline"
  final String? llmError;     // "LLM output is not valid JSON"
  final bool needsReview;     // false

  Flags({
    this.fallback,
    this.llmError,
    required this.needsReview,
  });

  factory Flags.fromJson(Map<String, dynamic> json) {
    return Flags(
      fallback: json['fallback'] as String?,
      llmError: json['llm_error'] as String?,
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }
}
