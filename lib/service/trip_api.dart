// lib/service/trip_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Flights + Trips 관련 API 호출 모음
class TripApiService {
  static const String _baseUrl =
      'https://unmatted-cecilia-criticizingly.ngrok-free.dev';

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
      },
      body: jsonEncode({
        'flight_code': flightCode,
        'code_type': codeType,
      }),
    );

    // 200 OK 또는 201 Created 둘 다 성공으로 인정
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Lookup flight failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final Map<String, dynamic> body =
    jsonDecode(resp.body) as Map<String, dynamic>;
    return FlightLookupResult.fromJson(body);
  }

  /// ---------------- Create Trip ----------------
  /// startDate, endDate → nullable 로 변경 (요청 바디에 null로 들어가게)
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

    // null 그대로 보내기 위해 Map으로 구성
    final Map<String, dynamic> body = {
      'title': title,
      'from_airport': fromAirport,
      'to_airport': toAirport,
      'start_date': startDate, // null 가능
      'end_date': endDate, // null 가능
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
      },
      body: jsonEncode(body),
    );

    // 200 OK 또는 201 Created 둘 다 성공
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        'Create trip failed: ${resp.statusCode} ${resp.body}',
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(resp.body) as Map<String, dynamic>;
    return CreatedTrip.fromJson(data);
  }
}

//// ==================== Models ====================

/// lookup-flight 응답용 간단 모델
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

    // departure UTC 선택: hint → dep.scheduled → 빈 문자열
    String _pickDepartureTime() {
      if (hint['departure_time_utc'] is String &&
          (hint['departure_time_utc'] as String).isNotEmpty) {
        return hint['departure_time_utc'] as String;
      }
      if (dep['scheduled_time_utc'] is String &&
          (dep['scheduled_time_utc'] as String).isNotEmpty) {
        return dep['scheduled_time_utc'] as String;
      }
      return '';
    }

    // arrival UTC 선택: hint → arr.scheduled → 빈 문자열
    String _pickArrivalTime() {
      if (hint['arrival_time_utc'] is String &&
          (hint['arrival_time_utc'] as String).isNotEmpty) {
        return hint['arrival_time_utc'] as String;
      }
      if (arr['scheduled_time_utc'] is String &&
          (arr['scheduled_time_utc'] as String).isNotEmpty) {
        return arr['scheduled_time_utc'] as String;
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
      departureTimeUtc: _pickDepartureTime(),
      arrivalAirportIata: arr['airport_iata'] as String? ?? '',
      arrivalAirportName: arr['airport_name'] as String? ?? '',
      arrivalCountry: arr['country'] as String? ?? '',
      arrivalTimeUtc: _pickArrivalTime(),
      leg: hint['leg'] as String?,
    );
  }

  /// `YYYY-MM-DD` 형식으로 변환 (실패 시 빈 문자열)
  String get departureDate {
    if (departureTimeUtc.isEmpty) return '';
    try {
      return DateTime.parse(departureTimeUtc)
          .toIso8601String()
          .split('T')
          .first;
    } catch (_) {
      return '';
    }
  }

  String get arrivalDate {
    if (arrivalTimeUtc.isEmpty) return '';
    try {
      return DateTime.parse(arrivalTimeUtc).toIso8601String().split('T').first;
    } catch (_) {
      return '';
    }
  }
}

/// Trip 생성 시 segments에 넣을 입력 모델
class TripSegmentInput {
  final String leg; // 예: "ICN-LAX"
  final String operating; // 항공사 IATA 코드 (KE, OZ 등)
  final String cabinClass; // economy, business 등

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

/// /v1/trips 응답의 중요한 부분만 사용
class CreatedTrip {
  final int tripId;
  final String title;
  final String startDate; // 서버가 null 주면 '' 로 들어옴
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
