// lib/service/recommendation_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/outfit_recommendation.dart';

const String kCherryPickApiBaseUrl =
    'https://unmatted-cecilia-criticizingly.ngrok-free.dev';

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

  // -------------------------
  // 1) 기간 업데이트 API
  // -------------------------
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

  // -------------------------
  // 2) 옷차림 추천 생성 API
  // -------------------------
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

    if (resp.statusCode == 409) {
      throw Exception('trip_duration_required');
    }

    if (resp.statusCode == 503) {
      try {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body['detail']?.toString() == 'meteostat_no_data') {
          throw Exception('meteostat_no_data');
        }
      } catch (_) {}
      throw Exception('service_unavailable');
    }

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Generate outfit failed: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  // -------------------------
  // 3) 통합 여행 추천 조회 API
  // -------------------------
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

  // -------------------------
  // 4) 최근 기후 정보 API
  // -------------------------
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
  // FX 환율 관련 API
  // =========================================================

  Future<Map<String, dynamic>> getFxQuote({
    required String deviceUuid,
    required String deviceToken,
    required String base,
    required String quote,
  }) async {
    final url =
    Uri.parse('$baseUrl/v1/fx/quote?base=$base&symbol=$quote');

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

  Future<Map<String, dynamic>> convertFx({
    required String deviceUuid,
    required String deviceToken,
    required String from,
    required String to,
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
}

// ---------------------------------------------------------------------
// TripRecommendation 모델 확장 (OutfitRecommendation 포함)
// ---------------------------------------------------------------------

class TripRecommendation {
  final int tripId;
  final String city;
  final String countryCode;

  // 기존 필드 유지
  final List<String> popularItems;
  final String outfitTip;
  final String shoppingGuide;

  // 새로 추가된 outfit 추천 블록
  final OutfitRecommendation? outfit;

  // 날씨 정보
  final WeatherSummary weather;

  // 환율 정보
  final ExchangeRateInfo exchangeRate;

  TripRecommendation({
    required this.tripId,
    required this.city,
    required this.countryCode,
    required this.popularItems,
    required this.outfitTip,
    required this.shoppingGuide,
    required this.weather,
    required this.exchangeRate,
    required this.outfit,
  });

  factory TripRecommendation.fromJson(Map<String, dynamic> json) {
    final weatherJson = json['weather'] as Map<String, dynamic>? ?? {};
    final fxJson = json['exchange_rate'] as Map<String, dynamic>? ?? {};

    return TripRecommendation(
      tripId: json['trip_id'] ?? 0,
      city: json['city'] ?? '',
      countryCode: json['country_code'] ?? '',
      popularItems: (json['popular_items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      outfitTip: json['outfit_tip'] ?? '',
      shoppingGuide: json['shopping_guide'] ?? '',
      weather: WeatherSummary.fromJson(weatherJson),
      exchangeRate: ExchangeRateInfo.fromJson(fxJson),
      outfit: json['recommendation'] != null
          ? OutfitRecommendation.fromJson(json['recommendation'])
          : null,
    );
  }
}

// ---------------- Weather Summary ----------------

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
      summary: json['summary'] ?? '',
      temperatureC: (json['temperature_c'] ?? 0).toDouble(),
      feelsLikeC: (json['feels_like_c'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toInt(),
      icon: json['icon'] ?? '',
    );
  }
}

// ---------------- Exchange ----------------

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
      currencyCode: json['currency_code'] ?? '',
      currencyName: json['currency_name'] ?? '',
      baseCurrency: json['base_currency'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      lastUpdated: json['last_updated'] ?? '',
    );
  }
}

// ---------------- Climate ----------------

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
    return TripClimate(
      tripId: json['trip_id'] ?? 0,
      recentStats: ClimateRecentStats.fromJson(json['recent_stats'] ?? {}),
      usedYears: (json['used_years'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      degraded: json['degraded'] ?? false,
      generatedAt: json['generated_at'] ?? '',
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
      tMeanC: (json['t_mean_c'] ?? 0).toDouble(),
      tMinC: (json['t_min_c'] ?? 0).toDouble(),
      tMaxC: (json['t_max_c'] ?? 0).toDouble(),
      precipSumMm: (json['precip_sum_mm'] ?? 0).toDouble(),
    );
  }
}
