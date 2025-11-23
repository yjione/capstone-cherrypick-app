// lib/providers/packing_provider.dart
import 'package:flutter/material.dart';

import '../models/packing_item.dart' as item;
import '../models/bag.dart' as bag;
import '../service/bag_api.dart';

class PackingProvider extends ChangeNotifier {
  final List<bag.Bag> _bags = [];
  final BagApiService _bagApi = BagApiService();

  String _selectedBag = "";
  String _searchQuery = "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<bag.Bag> get bags => _bags;
  String get selectedBag => _selectedBag;
  String get searchQuery => _searchQuery;

  /// ✅ 서버에서 가방 + 아이템 목록 한 번에 불러오기
  Future<void> loadBagsFromServer({
    required int tripId,
    required String deviceUuid,
    required String deviceToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final serverBags = await _bagApi.listBagsWithItems(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        tripId: tripId,
      );

      _bags
        ..clear()
        ..addAll(serverBags);

      // 선택된 가방 없으면 첫 번째를 기본 선택
      if (_bags.isNotEmpty) {
        _selectedBag = _bags.first.id;
      }
    } catch (e) {
      debugPrint('loadBagsFromServer error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ 서버에 가방 생성 + 로컬 리스트에 추가
  Future<void> createBagOnServer({
    required int tripId,
    required String deviceUuid,
    required String deviceToken,
    required String name,
    required String bagType, // 'carry_on' | 'checked' | 'custom'
  }) async {
    try {
      final newBag = await _bagApi.createBag(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        tripId: tripId,
        name: name,
        bagType: bagType,
      );
      _bags.add(newBag);

      // 새로 추가한 가방 선택
      _selectedBag = newBag.id;
      notifyListeners();
    } catch (e) {
      debugPrint('createBagOnServer error: $e');
      rethrow;
    }
  }

  void setSelectedBag(String bagId) {
    _selectedBag = bagId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// ⏳ 지금은 로컬 상태만 바꾸고, 나중에 PATCH /v1/bag-items/{item_id} 붙이면 됨
  void toggleItemPacked(String bagId, String itemId) {
    final bagIndex = _bags.indexWhere((b) => b.id == bagId);
    if (bagIndex != -1) {
      final itemIndex =
      _bags[bagIndex].items.indexWhere((i) => i.id == itemId);
      if (itemIndex != -1) {
        final oldItem = _bags[bagIndex].items[itemIndex];
        final updatedItem = oldItem.copyWith(packed: !oldItem.packed);
        _bags[bagIndex] = _bags[bagIndex].copyWith(
          items: List<item.PackingItem>.from(_bags[bagIndex].items)
            ..[itemIndex] = updatedItem,
        );
        notifyListeners();
      }
    }
  }

  /// (지금은 로컬 전용) 아이템 추가
  void addItem(item.PackingItem newItem) {
    final bagIndex = _bags.indexWhere((b) => b.id == newItem.bagId);
    if (bagIndex != -1) {
      _bags[bagIndex] = _bags[bagIndex].copyWith(
        items: List<item.PackingItem>.from(_bags[bagIndex].items)
          ..add(newItem),
      );
      notifyListeners();
    }
  }

  /// (지금은 로컬 전용) 아이템 삭제
  void removeItem(String bagId, String itemId) {
    final bagIndex = _bags.indexWhere((b) => b.id == bagId);
    if (bagIndex != -1) {
      _bags[bagIndex] = _bags[bagIndex].copyWith(
        items:
        _bags[bagIndex].items.where((i) => i.id != itemId).toList(),
      );
      notifyListeners();
    }
  }

  /// (fallback 용) 서버 안 붙고 로컬에서만 가방 추가할 때 사용
  void addBag(bag.Bag newBag) {
    _bags.add(newBag);
    if (_selectedBag.isEmpty) {
      _selectedBag = newBag.id;
    }
    notifyListeners();
  }

  List<item.PackingItem> getFilteredItems(String bagId) {
    final b = _bags.firstWhere((b) => b.id == bagId);
    if (_searchQuery.isEmpty) return b.items;

    final q = _searchQuery.toLowerCase();
    return b.items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          (i.location?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  int getPackingProgress(String bagId) {
    final b = _bags.firstWhere((b) => b.id == bagId);
    if (b.items.isEmpty) return 0;

    final packedItems = b.items.where((i) => i.packed).length;
    return ((packedItems / b.items.length) * 100).round();
  }
}
