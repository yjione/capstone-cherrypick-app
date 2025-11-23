// lib/service/bag_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/bag.dart';
import '../models/packing_item.dart';

class BagApiService {
  static const String _baseUrl =
      'https://unmatted-cecilia-criticizingly.ngrok-free.dev';

  /// trip 하나에 속한 가방 목록 + 각 가방의 아이템까지 전부 가져오기
  Future<List<Bag>> listBagsWithItems({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
  }) async {
    final bags = await _listBags(
      deviceUuid: deviceUuid,
      deviceToken: deviceToken,
      tripId: tripId,
    );

    // 각 가방별 아이템 조회
    for (var i = 0; i < bags.length; i++) {
      final bag = bags[i];
      final items = await listBagItems(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        bagId: int.parse(bag.id),
      );
      bags[i] = bag.copyWith(items: items);
    }

    return bags;
  }

  /// GET /v1/trips/{trip_id}/bags
  Future<List<Bag>> _listBags({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/trips/$tripId/bags');

    final resp = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response: ${resp.body}');
    }
    if (resp.statusCode != 200) {
      throw Exception('List bags failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? [];

    return rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      final bagType = (m['bag_type'] as String? ?? 'custom');

      return Bag(
        id: (m['bag_id'] ?? '').toString(),
        name: m['name'] as String? ?? '',
        type: bagType,
        color: _colorForBagType(bagType),
        items: const [],
      );
    }).toList();
  }

  /// GET /v1/bags/{bag_id}/items
  Future<List<PackingItem>> listBagItems({
    required String deviceUuid,
    required String deviceToken,
    required int bagId,
    int limit = 100,
    int offset = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/bags/$bagId/items').replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    final resp = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response: ${resp.body}');
    }
    if (resp.statusCode != 200) {
      throw Exception('List bag items failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> json =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? [];

    return rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      final status = m['status'] as String? ?? 'todo';
      final packed = status == 'done' || status == 'packed';

      return PackingItem(
        id: (m['item_id'] ?? '').toString(),
        name: m['title'] as String? ?? '',
        category: '기타', // 서버에 카테고리 없어서 기본값
        packed: packed,
        bagId: (m['bag_id'] ?? '').toString(),
        location: null,
        weight: null,
        notes: m['note'] as String?,
      );
    }).toList();
  }

  /// POST /v1/trips/{trip_id}/bags
  Future<Bag> createBag({
    required String deviceUuid,
    required String deviceToken,
    required int tripId,
    required String name,
    required String bagType, // 'carry_on' | 'checked' | 'custom'
  }) async {
    final url = Uri.parse('$_baseUrl/v1/trips/$tripId/bags');

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
        'name': name,
        'bag_type': bagType,
        'sort_order': 10000,
        'is_default': false,
      }),
    );

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response: ${resp.body}');
    }
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Create bag failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> m =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final bagTypeResp = (m['bag_type'] as String? ?? bagType);

    return Bag(
      id: (m['bag_id'] ?? '').toString(),
      name: m['name'] as String? ?? name,
      type: bagTypeResp,
      color: _colorForBagType(bagTypeResp),
      items: const [],
    );
  }

  /// PATCH /v1/bags/{bag_id}  (이름/타입/정렬 순서 등 수정)
  Future<Bag> updateBag({
    required String deviceUuid,
    required String deviceToken,
    required int bagId,
    String? name,
    String? bagType, // 'carry_on' | 'checked' | 'custom'
    int? sortOrder,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/bags/$bagId');

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bagType != null) body['bag_type'] = bagType;
    if (sortOrder != null) body['sort_order'] = sortOrder;

    if (body.isEmpty) {
      throw Exception('Nothing to update');
    }

    final resp = await http.patch(
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

    final contentType = resp.headers['content-type'] ?? '';
    if (!contentType.startsWith('application/json')) {
      throw Exception('Unexpected response: ${resp.body}');
    }
    if (resp.statusCode != 200) {
      throw Exception('Update bag failed: ${resp.statusCode} ${resp.body}');
    }

    final Map<String, dynamic> m =
    jsonDecode(resp.body) as Map<String, dynamic>;
    final bagTypeResp = (m['bag_type'] as String? ?? bagType ?? 'custom');

    return Bag(
      id: (m['bag_id'] ?? '').toString(),
      name: m['name'] as String? ?? name ?? '',
      type: bagTypeResp,
      color: _colorForBagType(bagTypeResp),
      items: const [], // 아이템은 별도 호출로 관리
    );
  }

  /// DELETE /v1/bags/{bag_id}
  Future<void> deleteBag({
    required String deviceUuid,
    required String deviceToken,
    required int bagId,
  }) async {
    final url = Uri.parse('$_baseUrl/v1/bags/$bagId');

    final resp = await http.delete(
      url,
      headers: {
        'Accept': 'application/json',
        'X-Device-UUID': deviceUuid,
        'X-Device-Token': deviceToken,
        'ngrok-skip-browser-warning': 'true',
      },
    );

    // 204 No Content (또는 혹시 200 OK) 정도를 성공으로 허용
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Delete bag failed: ${resp.statusCode} ${resp.body}');
    }
  }

  String _colorForBagType(String type) {
    switch (type) {
      case 'carry_on':
      case 'carry-on':
        return 'blue';
      case 'checked':
        return 'green';
      case 'personal':
      case 'custom':
        return 'purple';
      default:
        return 'grey';
    }
  }
}
