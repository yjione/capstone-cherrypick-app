// lib/service/trip_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class TripApiService {
  static const String _baseUrl = 'http://10.0.2.2:8001';

  /// ---------------- Lookup Flight ----------------
  Future<FlightLookupResult> lookupFlight({
    required String deviceUuid,
    required String deviceToken,
    required String flightCode,
    String codeType = 'iata',
  }) async {
    final url = Uri.parse('$_baseUrl/v1/trips/lookup-flight');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'flight_code': flightCode,
        'code_type': codeType,
      }),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Lookup flight failed: ${resp.statusCode} ${resp.body}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return FlightLookupResult.fromJson(body);
  }

  /// ---------------- Create Trip ----------------
  Future<CreatedTrip> createTrip({
    required String deviceUuid,
    required String deviceToken,
    required String title,
    required String fromAirport,
    required String toAirport,
    String? startDate,
    String? endDate,
    String note = '',
    List<String> tags = const [],
    List<String> viaAirports = const [],
    required List<TripSegmentInput> segments,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/trips');

    final body = <String, dynamic>{
      'title': title,
      'from_airport': fromAirport,
      'to_airport': toAirport,
      'start_date': startDate,
      'end_date': endDate,
      'note': note,
      'tags': tags,
      'via_airports': viaAirports,
      'segments': segments.map((s) => s.toJson()).toList(),
    };

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Create trip failed: ${resp.statusCode} ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return CreatedTrip.fromJson(data);
  }

  /// ---------------- List Trips ----------------
  Future<TripListResponse> listTrips({
    required String deviceUuid,
    required String deviceToken,
    String status = 'all',
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/trips').replace(queryParameters: {
      'status': status,
      'limit': '$limit',
      'offset': '$offset',
    });

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    // HTML 오면 강제 에러 처리
    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception(
          'Unexpected response (HTML instead of JSON):\n${resp.body}');
    }

    if (resp.statusCode != 200) {
      throw Exception('List trips failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TripListResponse.fromJson(json);
  }

  /// ---------------- Delete Trip ----------------
  Future<void> deleteTrip({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    bool purge = false,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/trips/$tripId')
        .replace(queryParameters: {'purge': purge.toString()});

    final resp = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('Delete trip failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// ---------------- Update Trip Duration ----------------
  ///
  /// PATCH /v1/trips/{trip_id}/duration
  Future<TripDurationInfo> updateTripDuration({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    required String startDate, // "YYYY-MM-DD"
    required String endDate,   // "YYYY-MM-DD"
  }) async {
    final url = Uri.parse('$_baseUrl/v1/trips/$tripId/duration');

    final resp = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'start_date': startDate,
        'end_date': endDate,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception(
          'Update duration failed: ${resp.statusCode} ${resp.body}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TripDurationInfo.fromJson(json);
  }
}

/// ================== 모델들 ==================

// 이하 모델들은 그대로
class FlightLookupResult {
  final String flightIata;
  final String airlineName;
  final String airlineIata;

  final String departureAirportIata;
  final String departureAirportName;
  final String departureCountry;
  final String departureTimeUtc;

  final String arrivalAirportIata;
  final String arrivalAirportName;
  final String arrivalCountry;
  final String arrivalTimeUtc;

  final String? leg;

  FlightLookupResult({
    required this.flightIata,
    required this.airlineName,
    required this.airlineIata,
    required this.departureAirportIata,
    required this.departureAirportName,
    required this.departureCountry,
    required this.departureTimeUtc,
    required this.arrivalAirportIata,
    required this.arrivalAirportName,
    required this.arrivalCountry,
    required this.arrivalTimeUtc,
    required this.leg,
  });

  factory FlightLookupResult.fromJson(Map<String, dynamic> json) {
    final dep = (json['departure'] ?? {}) as Map<String, dynamic>;
    final arr = (json['arrival'] ?? {}) as Map<String, dynamic>;
    final hint = (json['segment_hint'] ?? {}) as Map<String, dynamic>;

    String _pickTime(String key) {
      if (hint[key] is String && (hint[key] as String).isNotEmpty) {
        return hint[key] as String;
      }
      if (dep[key] is String && (dep[key] as String).isNotEmpty) {
        return dep[key] as String;
      }
      if (arr[key] is String && (arr[key] as String).isNotEmpty) {
        return arr[key] as String;
      }
      return '';
    }

    return FlightLookupResult(
      flightIata: json['flight_iata'] as String? ?? '',
      airlineName: json['airline_name'] as String? ?? '',
      airlineIata: json['airline_iata'] as String? ?? '',
      departureAirportIata: dep['airport_iata'] as String? ?? '',
      departureAirportName: dep['airport_name'] as String? ?? '',
      departureCountry: dep['country'] as String? ?? '',
      departureTimeUtc: _pickTime('scheduled_time_utc'),
      arrivalAirportIata: arr['airport_iata'] as String? ?? '',
      arrivalAirportName: arr['airport_name'] as String? ?? '',
      arrivalCountry: arr['country'] as String? ?? '',
      arrivalTimeUtc: _pickTime('scheduled_time_utc'),
      leg: hint['leg'] as String?,
    );
  }
}

class TripSegmentInput {
  final String leg;
  final String operating;
  final String cabinClass;

  TripSegmentInput({
    required this.leg,
    required this.operating,
    required this.cabinClass,
  });

  Map<String, dynamic> toJson() => {
    'leg': leg,
    'operating': operating,
    'cabin_class': cabinClass,
  };
}

class CreatedTrip {
  final int tripId;
  final String title;
  final String startDate;
  final String endDate;
  final String? from;
  final String? to;

  CreatedTrip({
    required this.tripId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.from,
    this.to,
  });

  factory CreatedTrip.fromJson(Map<String, dynamic> json) {
    final itinerary = (json['itinerary'] ?? {}) as Map<String, dynamic>;
    return CreatedTrip(
      tripId: json['trip_id'] as int,
      title: json['title'] as String? ?? '',
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      from: itinerary['from'] as String?,
      to: itinerary['to'] as String?,
    );
  }
}

class TripListItem {
  final int tripId;
  final String title;
  final String? startDate;
  final String? endDate;
  final String? fromAirport;
  final String? toAirport;
  final bool active;
  final String? archivedAt;

  TripListItem({
    required this.tripId,
    required this.title,
    this.startDate,
    this.endDate,
    this.fromAirport,
    this.toAirport,
    required this.active,
    this.archivedAt,
  });

  factory TripListItem.fromJson(Map<String, dynamic> json) {
    return TripListItem(
      tripId: json['trip_id'] as int,
      title: json['title'] as String? ?? '',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      fromAirport: json['from_airport'] as String?,
      toAirport: json['to_airport'] as String?,
      active: json['active'] as bool? ?? false,
      archivedAt: json['archived_at'] as String?,
    );
  }
}

class TripListResponse {
  final List<TripListItem> items;
  final int nextOffset;
  final bool hasMore;

  TripListResponse({
    required this.items,
    required this.nextOffset,
    required this.hasMore,
  });

  factory TripListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? [];
    return TripListResponse(
      items: rawItems
          .map((e) => TripListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextOffset: json['next_offset'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

/// PATCH /duration 응답용 모델
class TripDurationInfo {
  final int tripId;
  final String startDate;
  final String endDate;
  final bool needsDuration;

  TripDurationInfo({
    required this.tripId,
    required this.startDate,
    required this.endDate,
    required this.needsDuration,
  });

  factory TripDurationInfo.fromJson(Map<String, dynamic> json) {
    return TripDurationInfo(
      tripId: json['trip_id'] as int,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
      needsDuration: json['needs_duration'] as bool? ?? false,
    );
  }
}
