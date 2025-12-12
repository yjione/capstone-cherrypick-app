// lib/service/item_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/preview_response.dart';

/// 다른 ApiService 들과 동일한 baseUrl
const String kCherryPickApiBaseUrl =
    'https://gutturalized-london-unmistakingly.ngrok-free.dev';

class ItemApiService {
  final String baseUrl;

  /// baseUrl 을 선택 파라미터로 두고,
  /// 안 넘기면 kCherryPickApiBaseUrl 을 쓰게.
  ItemApiService({String? baseUrl})
      : baseUrl = baseUrl ?? kCherryPickApiBaseUrl;

  /// /v1/items/save : preview 결과를 서버에 저장
  Future<void> saveItem({
    required String deviceUuid,
    required String deviceToken,
    required int bagId,
    required int tripId,
    required PreviewResponse preview,
    required String reqId,
    String? userLabel, // ⭐ 사용자가 입력한 이름(옵션)
    int? imageId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/items/save');

    final body = <String, dynamic>{
      'req_id': reqId,
      'preview': preview.toJson(),
      'bag_id': bagId,
      'trip_id': tripId,
      // ✅ 사용자가 입력한 이름이 있으면 user_label 로 보내기
      if (userLabel != null && userLabel.trim().isNotEmpty)
        'user_label': userLabel.trim(),
      if (imageId != null) 'image_id': imageId,
    };

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('saveItem 실패: ${res.statusCode} ${res.body}');
    }
  }

  /// /v1/bag-items/{item_id} : 저장된 아이템 1개 + preview_snapshot 가져오기
  Future<PreviewResponse> getItemPreview({
    required String deviceUuid,
    required String deviceToken,
    required int itemId,
  }) async {
    final uri = Uri.parse('$baseUrl/v1/bag-items/$itemId');

    final res = await http.get(
      uri,
      headers: {
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('getItemPreview 실패: ${res.statusCode} ${res.body}');
    }

    final jsonBody = jsonDecode(res.body) as Map<String, dynamic>;

    // 1) preview_snapshot 꺼냄
    final snapshot = jsonBody['preview_snapshot'];
    if (snapshot == null) {
      throw Exception('preview_snapshot 필드가 없습니다.');
    }

    // 2) snapshot 안의 preview_response 꺼냄
    final previewJson = snapshot['preview_response'];
    if (previewJson == null) {
      throw Exception('preview_response 필드가 preview_snapshot 안에 없습니다.');
    }

    // 3) preview_response 를 PreviewResponse 로 파싱
    return PreviewResponse.fromJson(previewJson as Map<String, dynamic>);
  }
}
