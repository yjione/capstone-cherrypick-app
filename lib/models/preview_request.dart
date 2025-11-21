// lib/models/preview_request.dart
class PreviewRequest {
  final String label;
  final String locale;
  final String reqId;
  final Itinerary itinerary;
  final List<Segment> segments;
  final ItemParams itemParams;
  final DutyFree dutyFree;

  PreviewRequest({
    required this.label,
    required this.locale,
    required this.reqId,
    required this.itinerary,
    required this.segments,
    required this.itemParams,
    required this.dutyFree,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'locale': locale,
      'req_id': reqId,
      'itinerary': itinerary.toJson(),
      'segments': segments.map((e) => e.toJson()).toList(),
      'item_params': itemParams.toJson(),
      'duty_free': dutyFree.toJson(),
    };
  }
}

class Itinerary {
  final String from;
  final String to;
  final List<String> via;
  final bool rescreening;

  Itinerary({
    required this.from,
    required this.to,
    required this.via,
    required this.rescreening,
  });

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'via': via,
      'rescreening': rescreening,
    };
  }
}

class Segment {
  final String leg;
  final String operating;
  final String cabinClass;

  Segment({
    required this.leg,
    required this.operating,
    required this.cabinClass,
  });

  Map<String, dynamic> toJson() {
    return {
      'leg': leg,
      'operating': operating,
      'cabin_class': cabinClass,
    };
  }
}

class ItemParams {
  final int volumeMl;
  final int wh;
  final int count;
  final double abvPercent;
  final double weightKg;
  final double bladeLengthCm;

  ItemParams({
    required this.volumeMl,
    required this.wh,
    required this.count,
    required this.abvPercent,
    required this.weightKg,
    required this.bladeLengthCm,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume_ml': volumeMl,
      'wh': wh,
      'count': count,
      'abv_percent': abvPercent,
      'weight_kg': weightKg,
      'blade_length_cm': bladeLengthCm,
    };
  }
}

class DutyFree {
  final bool isDf;
  final bool stebSealed;

  DutyFree({
    required this.isDf,
    required this.stebSealed,
  });

  Map<String, dynamic> toJson() {
    return {
      'is_df': isDf,
      'steb_sealed': stebSealed,
    };
  }
}
