// lib/service/reference_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/country_ref.dart';
import '../models/airport_ref.dart';
import '../models/airline_ref.dart';
import '../models/cabin_class_ref.dart';

class ReferenceApiService {
  static const String _baseUrl = 'http://10.0.2.2:8001';
  /// GET /v1/reference/countries
  Future<List<CountryRef>> listCountries({
    required String deviceUuid,
    required String deviceToken,
    String? q,
    String? region,
    bool activeOnly = false,  // 테스트용: 모든 국가 표시
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/reference/countries').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (region != null && region.isNotEmpty) 'region': region,
        'active_only': activeOnly.toString(),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response (not JSON): ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('List countries failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> items = json['items'] as List<dynamic>? ?? [];

    return items
        .map((e) => CountryRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/reference/airports
  Future<List<AirportRef>> listAirports({
    required String deviceUuid,
    required String deviceToken,
    String? q,
    String? countryCode,
    int limit = 100,
    bool activeOnly = false,  // 테스트용: 모든 공항 표시
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/reference/airports').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (countryCode != null && countryCode.isNotEmpty)
          'country_code': countryCode,
        'limit': '$limit',
        'active_only': activeOnly.toString(),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response (not JSON): ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('List airports failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> items = json['items'] as List<dynamic>? ?? [];

    return items
        .map((e) => AirportRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/reference/airlines
  Future<List<AirlineRef>> listAirlines({
    required String deviceUuid,
    required String deviceToken,
    String? q,
    bool activeOnly = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/reference/airlines').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        'active_only': activeOnly.toString(),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response (not JSON): ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('List airlines failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> items = json['items'] as List<dynamic>? ?? [];

    return items
        .map((e) => AirlineRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /v1/reference/cabin_classes
  Future<List<CabinClassRef>> listCabinClasses({
    required String deviceUuid,
    required String deviceToken,
    String? airlineCode, // 없으면 기본 좌석 등급 목록
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/reference/cabin_classes').replace(
      queryParameters: {
        if (airlineCode != null && airlineCode.isNotEmpty)
          'airline_code': airlineCode,
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true', // ⭐ 중요
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response (not JSON): ${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception(
          'List cabin classes failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> items = json['items'] as List<dynamic>? ?? [];

    return items
        .map((e) => CabinClassRef.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
