// lib/service/fx_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FxApiService {
  final String baseUrl;
  final String apiKey;

  FxApiService({
    required this.baseUrl,
    required this.apiKey,
  });

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
  };

  /// GET /v1/fx/currencies
  Future<Map<String, String>> getCurrencies() async {
    final uri = Uri.parse('$baseUrl/v1/fx/currencies');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('통화 리스트 조회 실패: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final map = (data['currencies'] as Map).cast<String, String>();
    return map;
  }

  /// POST /v1/fx/convert
  Future<FxConvertResult> convert({
    required double amount,
    required String base,
    required String symbol,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/fx/convert');

    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'amount': amount,
        'base': base,
        'symbol': symbol,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('환율 변환 실패: ${res.statusCode} ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return FxConvertResult.fromJson(json);
  }
}

class FxConvertResult {
  final String base;
  final String symbol;
  final double amount;
  final double rate;
  final double converted;
  final String asOf;
  final String source;

  FxConvertResult({
    required this.base,
    required this.symbol,
    required this.amount,
    required this.rate,
    required this.converted,
    required this.asOf,
    required this.source,
  });

  factory FxConvertResult.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) => v is int ? v.toDouble() : (v as num).toDouble();

    return FxConvertResult(
      base: json['base'] as String,
      symbol: json['symbol'] as String,
      amount: _d(json['amount']),
      rate: _d(json['rate']),
      converted: _d(json['converted']),
      asOf: json['as_off'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }
}
