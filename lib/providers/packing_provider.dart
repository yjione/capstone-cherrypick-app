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

      // 선택된 가방 없으면 첫 번째를 기본 선택
      if (_bags.isNotEmpty) {
        _selectedBag = _bags.first.id;
      } else {
        _selectedBag = "";
      }
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

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
