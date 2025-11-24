// lib/service/device_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/device_register.dart';

class DeviceApiService {
  // 로컬 서버 기준
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
        'Accept-Language': request.locale,
        // 웹에서만 쓰는 헤더는 굳이 안 보내도 됨 (ngrok-skip-browser-warning 같은 거)
      },
      body: jsonEncode(request.toJson()),
    );

    // ✅ 200, 201 둘 다 성공으로 인정
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Device register failed: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body =
    jsonDecode(response.body) as Map<String, dynamic>;
    return DeviceRegisterResponse.fromJson(body);
  }
}
