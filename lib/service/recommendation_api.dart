// lib/service/recommendation_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const String kCherryPickApiBaseUrl = 'http://10.0.2.2:8001';

class RecommendationApiService {
  final String baseUrl;

  RecommendationApiService({String? baseUrl})
      : baseUrl = baseUrl ?? kCherryPickApiBaseUrl;

  Map<String, String> _headers({
    required String deviceUuid,
    required String deviceToken,
  }) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-UUID': deviceUuid,
      'X-Device-Token': deviceToken,
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// 1) 여행 기간 업데이트
  Future<void> updateTripDuration({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse('$baseUrl/v1/trips/$tripId/duration');

    final resp = await http.patch(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
      body: jsonEncode({
        'start_date': startDate,
        'end_date': endDate,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Update duration failed: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  /// 2) 옷차림 추천 생성 (기후 분석 등 무거운 작업)
  Future<void> generateOutfitRecommendation({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    int years = 3,
    String aggregation = 'weighted',
    String locale = 'ko-KR',
  }) async {
    final url = Uri.parse('$baseUrl/v1/trips/$tripId/recommendations/outfit');

    final resp = await http.post(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
      body: jsonEncode({
        'years': years,
        'aggregation': aggregation,
        'locale': locale,
      }),
    );

    // 기간 부족
    if (resp.statusCode == 409) {
      throw Exception('trip_duration_required');
    }

    // 기상 데이터(meteostat) 없음 / 서비스 장애
    if (resp.statusCode == 503) {
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final detail = body['detail']?.toString();
        if (detail == 'meteostat_no_data') {
          throw Exception('meteostat_no_data');
        }
      } catch (_) {
        // 파싱 실패하면 일반 service_unavailable 로 처리
      }
      throw Exception('service_unavailable');
    }

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Generate outfit failed: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  /// 3) 여행 추천 조회
  Future<TripRecommendation> getTripRecommendation({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
  }) async {
    final url = Uri.parse('$baseUrl/v1/trips/$tripId/recommendation');

    final resp = await http.get(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Get recommendation failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TripRecommendation.fromJson(json);
  }

  /// 4) 최근 기후 정보 조회 (/v1/climate/trips/{trip_id}/recent)
  Future<TripClimate> getTripClimate({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    int years = 3,
    String aggregation = 'weighted',
  }) async {
    final url = Uri.parse(
      '$baseUrl/v1/climate/trips/$tripId/recent'
          '?years=$years&aggregation=$aggregation',
    );

    final resp = await http.get(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Get climate failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TripClimate.fromJson(json);
  }

  // =========================================================
  // ====== FX (환율) 관련 API ======
  // =========================================================

  /// FX-1) 현재 환율 조회: GET /v1/fx/quote
  /// swagger 기준: query = base, symbol
  Future<Map<String, dynamic>> getFxQuote({
    required String deviceUuid,
    required String deviceToken,
    required String base,
    required String quote,
  }) async {
    final url = Uri.parse(
      '$baseUrl/v1/fx/quote?base=$base&symbol=$quote',
    );

    final resp = await http.get(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Get FX quote failed: ${resp.statusCode} ${resp.body}',
      );
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// FX-2) 금액 변환: POST /v1/fx/convert
  /// swagger 스펙: { "amount": 1, "base": "KRW", "symbol": "USD" }
  Future<Map<String, dynamic>> convertFx({
    required String deviceUuid,
    required String deviceToken,
    required String from, // base 통화
    required String to,   // symbol(목적 통화)
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/v1/fx/convert');

    final resp = await http.post(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
      body: jsonEncode({
        'amount': amount,
        'base': from,
        'symbol': to,
      }),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Convert FX failed: ${resp.statusCode} ${resp.body}',
      );
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// FX-3) 특정 날짜 환율 조회: GET /v1/fx/quote/date
  Future<Map<String, dynamic>> getFxQuoteOnDate({
    required String deviceUuid,
    required String deviceToken,
    required String base,
    required String quote,
    required String date, // YYYY-MM-DD
  }) async {
    final url = Uri.parse(
      '$baseUrl/v1/fx/quote/date?base=$base&symbol=$quote&date=$date',
    );

    final resp = await http.get(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Get FX quote (date) failed: ${resp.statusCode} ${resp.body}',
      );
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// FX-4) 특정 날짜 기준 금액 변환: POST /v1/fx/convert/date
  Future<Map<String, dynamic>> convertFxOnDate({
    required String deviceUuid,
    required String deviceToken,
    required String from,
    required String to,
    required double amount,
    required String date, // YYYY-MM-DD
  }) async {
    final url = Uri.parse('$baseUrl/v1/fx/convert/date');

    final resp = await http.post(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
      body: jsonEncode({
        'amount': amount,
        'base': from,
        'symbol': to,
        'date': date,
      }),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Convert FX (date) failed: ${resp.statusCode} ${resp.body}',
      );
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// FX-5) 지원 통화 목록: GET /v1/fx/currencies
  Future<List<dynamic>> getFxCurrencies({
    required String deviceUuid,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$baseUrl/v1/fx/currencies');

    final resp = await http.get(
      url,
      headers: _headers(deviceUuid: deviceUuid, deviceToken: deviceToken),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Get FX currencies failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final json = jsonDecode(resp.body);
    // 스펙 예시: { "currencies": { "USD": "United States Dollar", ... } }
    if (json is Map && json['currencies'] is Map) {
      return (json['currencies'] as Map).entries.toList();
    }
    return [];
  }
}

/// ====== 모델 ======

class TripRecommendation {
  final int tripId;
  final String city;
  final String countryCode;
  final WeatherSummary weather;
  final ExchangeRateInfo exchangeRate;
  final List<String> popularItems;
  final String outfitTip;
  final String shoppingGuide;

  TripRecommendation({
    required this.tripId,
    required this.city,
    required this.countryCode,
    required this.weather,
    required this.exchangeRate,
    required this.popularItems,
    required this.outfitTip,
    required this.shoppingGuide,
  });

  factory TripRecommendation.fromJson(Map<String, dynamic> json) {
    final w = json['weather'] as Map<String, dynamic>? ?? {};
    final fx = json['exchange_rate'] as Map<String, dynamic>? ?? {};

    return TripRecommendation(
      tripId: json['trip_id'] as int? ?? 0,
      city: json['city'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      weather: WeatherSummary.fromJson(w),
      exchangeRate: ExchangeRateInfo.fromJson(fx),
      popularItems: (json['popular_items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      outfitTip: json['outfit_tip'] as String? ?? '',
      shoppingGuide: json['shopping_guide'] as String? ?? '',
    );
  }
}

class WeatherSummary {
  final String summary;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final String icon;

  WeatherSummary({
    required this.summary,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.icon,
  });

  factory WeatherSummary.fromJson(Map<String, dynamic> json) {
    return WeatherSummary(
      summary: json['summary'] as String? ?? '',
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (json['feels_like_c'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      icon: json['icon'] as String? ?? '',
    );
  }
}

class ExchangeRateInfo {
  final String currencyCode;
  final String currencyName;
  final String baseCurrency;
  final double rate;
  final String lastUpdated;

  ExchangeRateInfo({
    required this.currencyCode,
    required this.currencyName,
    required this.baseCurrency,
    required this.rate,
    required this.lastUpdated,
  });

  factory ExchangeRateInfo.fromJson(Map<String, dynamic> json) {
    return ExchangeRateInfo(
      currencyCode: json['currency_code'] as String? ?? '',
      currencyName: json['currency_name'] as String? ?? '',
      baseCurrency: json['base_currency'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }
}

// ====== 기후(날씨) 요약 모델 ======

class TripClimate {
  final int tripId;
  final ClimateRecentStats recentStats;
  final List<int> usedYears;
  final bool degraded;
  final String generatedAt;

  TripClimate({
    required this.tripId,
    required this.recentStats,
    required this.usedYears,
    required this.degraded,
    required this.generatedAt,
  });

  factory TripClimate.fromJson(Map<String, dynamic> json) {
    final rs = json['recent_stats'] as Map<String, dynamic>? ?? {};
    return TripClimate(
      tripId: json['trip_id'] as int? ?? 0,
      recentStats: ClimateRecentStats.fromJson(rs),
      usedYears: (json['used_years'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      degraded: json['degraded'] as bool? ?? false,
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }
}

class ClimateRecentStats {
  final double tMeanC;
  final double tMinC;
  final double tMaxC;
  final double precipSumMm;

  ClimateRecentStats({
    required this.tMeanC,
    required this.tMinC,
    required this.tMaxC,
    required this.precipSumMm,
  });

  factory ClimateRecentStats.fromJson(Map<String, dynamic> json) {
    return ClimateRecentStats(
      tMeanC: (json['t_mean_c'] as num?)?.toDouble() ?? 0,
      tMinC: (json['t_min_c'] as num?)?.toDouble() ?? 0,
      tMaxC: (json['t_max_c'] as num?)?.toDouble() ?? 0,
      precipSumMm: (json['precip_sum_mm'] as num?)?.toDouble() ?? 0,
    );
  }
}
