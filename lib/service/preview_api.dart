// lib/service/preview_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/preview_request.dart';
import '../models/preview_response.dart';

class PreviewApiService {
  final String baseUrl;

  PreviewApiService({required this.baseUrl});

  Future<PreviewResponse> fetchPreview(PreviewRequest request) async {
    // TODO: 실제 엔드포인트로 수정
    final uri = Uri.parse('$baseUrl/v1/items/preview'); // 예: https://api.xxx.com/preview

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        // 필요하면 Authorization 같은 거 추가
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody =
      jsonDecode(response.body) as Map<String, dynamic>;
      return PreviewResponse.fromJson(jsonBody);
    } else {
      throw Exception(
          'Preview API 호출 실패: ${response.statusCode} ${response.body}');
    }
  }
}
