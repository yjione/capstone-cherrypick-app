// lib/models/preview_response.dart

class PreviewResponse {
  final String state;
  final Resolved resolved;

  /// 엔진 정보는 fallback 상황에서 null 로 올 수 있음
  final Engine? engine;

  /// 내레이션도 LLM 오류 시 null 로 올 수 있음
  final Narration? narration;

  /// 상단 ai_tips (엔진 쪽과 별개로 올 수도 있음)
  final List<AiTip> aiTips;

  final Flags flags;

  PreviewResponse({
    required this.state,
    required this.resolved,
    this.engine,
    this.narration,
    required this.aiTips,
    required this.flags,
  });

  factory PreviewResponse.fromJson(Map<String, dynamic> json) {
    final engineJson = json['engine'];
    final narrationJson = json['narration'];

    return PreviewResponse(
      state: json['state'] as String? ?? '',
      resolved: Resolved.fromJson(json['resolved'] as Map<String, dynamic>),
      // 🔐 engine 이 null 이거나 이상한 타입이면 그냥 null 로 둔다
      engine: engineJson is Map<String, dynamic>
          ? Engine.fromJson(engineJson)
          : null,
      // 🔐 narration 도 마찬가지로 null-safe 파싱
      narration: narrationJson is Map<String, dynamic>
          ? Narration.fromJson(narrationJson)
          : null,
      aiTips: (json['ai_tips'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AiTip.fromJson(e))
          .toList(),
      // flags 가 null 이면 빈 맵으로 처리
      flags: Flags.fromJson(
        (json['flags'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'state': state,
      'resolved': resolved.toJson(),
      'ai_tips': aiTips.map((e) => e.toJson()).toList(),
      'flags': flags.toJson(),
    };

    if (engine != null) {
      data['engine'] = engine!.toJson();
    }
    if (narration != null) {
      data['narration'] = narration!.toJson();
    }

    return data;
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
      label: json['label'] as String? ?? '',
      canonical: json['canonical'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'canonical': canonical,
      'locale': locale,
    };
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
      reqId: json['req_id'] as String? ?? '',
      canonical: json['canonical'] as String? ?? '',
      decision: json['decision'] is Map<String, dynamic>
          ? Decision.fromJson(json['decision'] as Map<String, dynamic>)
          : Decision(
        carryOn: DecisionSide(status: '', badges: const [], reasonCodes: const []),
        checked: DecisionSide(status: '', badges: const [], reasonCodes: const []),
      ),
      conditions: json['conditions'] is Map<String, dynamic>
          ? Conditions.fromJson(json['conditions'] as Map<String, dynamic>)
          : Conditions(carryOn: const {}, checked: const {}, common: const {}),
      sources: (json['sources'] as List<dynamic>? ?? []),
      trace: (json['trace'] as List<dynamic>? ?? []),
      aiTips: (json['ai_tips'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => AiTip.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'req_id': reqId,
      'canonical': canonical,
      'decision': decision.toJson(),
      'conditions': conditions.toJson(),
      'sources': sources,
      'trace': trace,
      'ai_tips': aiTips.map((e) => e.toJson()).toList(),
    };
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
      carryOn: DecisionSide.fromJson(
        json['carry_on'] as Map<String, dynamic>,
      ),
      checked: DecisionSide.fromJson(
        json['checked'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carry_on': carryOn.toJson(),
      'checked': checked.toJson(),
    };
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
      status: json['status'] as String? ?? '',
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      reasonCodes: (json['reason_codes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'badges': badges,
      'reason_codes': reasonCodes,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'carry_on': carryOn,
      'checked': checked,
      'common': common,
    };
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
      title: json['title'] as String? ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'carry_on_card': carryOnCard.toJson(),
      'checked_card': checkedCard.toJson(),
      'bullets': bullets,
      'badges': badges,
      'footnote': footnote,
      'sources': sources,
    };
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
      statusLabel: json['status_label'] as String? ?? '',
      shortReason: json['short_reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_label': statusLabel,
      'short_reason': shortReason,
    };
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
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'tags': tags,
      'relevance': relevance,
    };
  }
}

// ---------- flags ----------
class Flags {
  final String? fallback; // 예: "classic_pipeline"
  final String? llmError; // 예: "LLM output is not valid JSON"
  final bool needsReview;

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

  Map<String, dynamic> toJson() {
    return {
      if (fallback != null) 'fallback': fallback,
      if (llmError != null) 'llm_error': llmError,
      'needs_review': needsReview,
    };
  }
}
