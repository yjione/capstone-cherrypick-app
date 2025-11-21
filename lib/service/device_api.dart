// lib/service/device_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device_register.dart';

class DeviceApiService {
  // TODO: 네 ngrok / 서버 base URL 로 바꿔줘
  static const String _baseUrl =
      'https://unmatted-cecilia-criticizingly.ngrok-free.dev';

  Future<DeviceRegisterResponse> registerDevice(
      DeviceRegisterRequest request) async {
    final url = Uri.parse('$_baseUrl/v1/devices/register');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Swagger에 Accept-Language 헤더 있었으니까 같이 보내기
        'Accept-Language': request.locale,
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Device register failed: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;
    return DeviceRegisterResponse.fromJson(body);
  }
}
