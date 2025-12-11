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

      // ⭐ 이 여행에 아직 가방이 하나도 없으면 기본 가방 2개 생성
      if (_bags.isEmpty) {
        final carryOn = await _bagApi.createBag(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          tripId: tripId,
          name: '기내 수하물',
          bagType: 'carry_on',
        );

        final checked = await _bagApi.createBag(
          deviceUuid: deviceUuid,
          deviceToken: deviceToken,
          tripId: tripId,
          name: '위탁 수하물',
          bagType: 'checked',
        );

        _bags
          ..add(carryOn)
          ..add(checked);
      }

      _selectedBag = _bags.isNotEmpty ? _bags.first.id : "";
    } catch (e) {
      debugPrint('loadBagsFromServer error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBagOnServer({
    required int tripId,
    required String deviceUuid,
    required String deviceToken,
    required String name,
    required String bagType,
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

      _selectedBag = newBag.id;
      notifyListeners();
    } catch (e) {
      debugPrint('createBagOnServer error: $e');
      rethrow;
    }
  }

  Future<void> renameBagOnServer({
    required String deviceUuid,
    required String deviceToken,
    required String bagId,
    required String newName,
  }) async {
    try {
      final updated = await _bagApi.updateBag(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        bagId: int.parse(bagId),
        name: newName,
      );

      final index = _bags.indexWhere((b) => b.id == bagId);
      if (index != -1) {
        _bags[index] = _bags[index].copyWith(name: updated.name);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('renameBagOnServer error: $e');
      rethrow;
    }
  }

  Future<void> deleteBagOnServer({
    required String deviceUuid,
    required String deviceToken,
    required String bagId,
  }) async {
    try {
      await _bagApi.deleteBag(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        bagId: int.parse(bagId),
      );

      _bags.removeWhere((b) => b.id == bagId);

      if (_selectedBag == bagId) {
        _selectedBag = _bags.isNotEmpty ? _bags.first.id : "";
      }

      notifyListeners();
    } catch (e) {
      debugPrint('deleteBagOnServer error: $e');
      rethrow;
    }
  }

  void setSelectedBag(String bagId) {
    _selectedBag = bagId;
    notifyListeners();
  }

  /// ✅ 검색어를 바꾸면서, 그 검색어를 포함한 아이템이 있는
  /// 첫 번째 가방으로 _selectedBag 을 자동 이동시킴
  void setSearchQuery(String query) {
    _searchQuery = query;

    final q = query.trim().toLowerCase();

    if (q.isNotEmpty && _bags.isNotEmpty) {
      String? matchedBagId;

      for (final b in _bags) {
        final hasMatch = b.items.any((i) {
          final name = i.name.toLowerCase();
          final category = i.category.toLowerCase();
          final location = i.location?.toLowerCase() ?? '';
          return name.contains(q) ||
              category.contains(q) ||
              location.contains(q);
        });

        if (hasMatch) {
          matchedBagId = b.id;
          break;
        }
      }

      if (matchedBagId != null && matchedBagId != _selectedBag) {
        _selectedBag = matchedBagId;
      }
    }

    // 검색어를 지웠을 때는 현재 선택된 가방을 그대로 두고 싶어서 따로 리셋하지 않음
    notifyListeners();
  }

  /// 🔹 기존: 로컬 state만 토글 (임시로 남겨두기)
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

  void removeItem(String bagId, String itemId) {
    final bagIndex = _bags.indexWhere((b) => b.id == bagId);
    if (bagIndex != -1) {
      _bags[bagIndex] = _bags[bagIndex].copyWith(
        items: _bags[bagIndex].items.where((i) => i.id != itemId).toList(),
      );
      notifyListeners();
    }
  }

  void addBag(bag.Bag newBag) {
    _bags.add(newBag);
    if (_selectedBag.isEmpty) {
      _selectedBag = newBag.id;
    }
    notifyListeners();
  }

  /// 각 가방 탭 안에서는 "그 가방 안의 아이템"만 필터링
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

  /// 체크/체크해제 + 서버 PATCH 연동
  Future<void> toggleItemPackedOnServer({
    required String deviceUuid,
    required String deviceToken,
    required String bagId,
    required String itemId,
  }) async {
    final bagIndex = _bags.indexWhere((b) => b.id == bagId);
    if (bagIndex == -1) return;

    final currentItems =
    List<item.PackingItem>.from(_bags[bagIndex].items);
    final itemIndex =
    currentItems.indexWhere((it) => it.id == itemId);
    if (itemIndex == -1) return;

    final oldItem = currentItems[itemIndex];
    final newPacked = !oldItem.packed;
    final newStatus = newPacked ? 'packed' : 'todo';

    // 1) 낙관적 업데이트 (UI 먼저 반영)
    final updatedLocal = oldItem.copyWith(packed: newPacked);
    currentItems[itemIndex] = updatedLocal;
    _bags[bagIndex] =
        _bags[bagIndex].copyWith(items: currentItems);
    notifyListeners();

    try {
      // 2) 서버 PATCH
      final updatedFromServer = await _bagApi.updateBagItem(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        itemId: int.parse(itemId),
        status: newStatus,
      );

      // 3) 서버 응답 기준으로 다시 확정
      final items2 =
      List<item.PackingItem>.from(_bags[bagIndex].items);
      final idx2 = items2.indexWhere((it) => it.id == itemId);
      if (idx2 != -1) {
        items2[idx2] = updatedFromServer;
        _bags[bagIndex] =
            _bags[bagIndex].copyWith(items: items2);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('toggleItemPackedOnServer error: $e');

      // 4) 실패 시 롤백
      final rollbackItems =
      List<item.PackingItem>.from(_bags[bagIndex].items);
      final idx3 = rollbackItems.indexWhere((it) => it.id == itemId);
      if (idx3 != -1) {
        rollbackItems[idx3] = oldItem;
        _bags[bagIndex] =
            _bags[bagIndex].copyWith(items: rollbackItems);
        notifyListeners();
      }

      rethrow;
    }
  }
}
