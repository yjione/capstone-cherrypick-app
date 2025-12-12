// lib/service/rules_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/preview_request.dart';

/// 규정 확인 API 응답 모델
class LabelCheckResult {
  final String label;
  final String? canonical;
  final bool carryOnAllowed;
  final bool checkedAllowed;
  final List<String> restrictions;
  final bool needsReview;
  final String? error;

  LabelCheckResult({
    required this.label,
    this.canonical,
    required this.carryOnAllowed,
    required this.checkedAllowed,
    required this.restrictions,
    required this.needsReview,
    this.error,
  });

  factory LabelCheckResult.fromJson(Map<String, dynamic> json) {
    return LabelCheckResult(
      label: json['label'] as String,
      canonical: json['canonical'] as String?,
      carryOnAllowed: json['carry_on_allowed'] as bool? ?? false,
      checkedAllowed: json['checked_allowed'] as bool? ?? false,
      restrictions: (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      needsReview: json['needs_review'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

class RulesCheckResponse {
  final List<LabelCheckResult> results;

  RulesCheckResponse({required this.results});

  factory RulesCheckResponse.fromJson(Map<String, dynamic> json) {
    return RulesCheckResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => LabelCheckResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 규정 확인 API 서비스
/// 
/// 백엔드의 `/v1/rules/check` API를 호출하여 라벨 리스트에 대한 규정 정보를 조회합니다.
class RulesApiService {
  // 백엔드 base URL
  // Android 에뮬레이터에서 로컬 서버 접근: 10.0.2.2
  static const String _baseUrl = 'http://10.0.2.2:8001';

  /// 라벨 리스트에 대한 규정 정보를 조회합니다.
  /// 
  /// [labels]: 확인할 라벨 리스트
  /// [itinerary]: 여정 정보 (출발지, 도착지 등)
  /// [segments]: 항공편 구간 정보
  /// [locale]: 로케일 (기본값: "ko-KR")
  /// [deviceUuid]: 디바이스 UUID (필수)
  /// [deviceToken]: 디바이스 인증 토큰 (필수)
  /// 
  /// Returns: 각 라벨별 규정 확인 결과
  /// 
  /// Throws: Exception (네트워크 오류, 서버 오류 등)
  Future<RulesCheckResponse> checkRules({
    required List<String> labels,
    required Itinerary itinerary,
    required List<Segment> segments,
    String locale = 'ko-KR',
    required String deviceUuid,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/rules/check');

    final requestBody = {
      'labels': labels,
      'itinerary': itinerary.toJson(),
      'segments': segments.map((e) => e.toJson()).toList(),
      'locale': locale,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-UUID': deviceUuid,
      'X-Device-Token': deviceToken,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Rules check API failed: ${response.statusCode} ${response.body}',
        );
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      return RulesCheckResponse.fromJson(body);
    } catch (e) {
      throw Exception('Failed to check rules: $e');
    }
  }
}

