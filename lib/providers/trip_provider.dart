// lib/providers/trip_provider.dart
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../service/trip_api.dart';

class TripProvider extends ChangeNotifier {
  final TripApiService _api = TripApiService();

  final List<Trip> _trips = [];
  String? _currentTripId;

  bool _isLoading = false;
  bool _hasLoadedOnce = false; // ⭐ 서버에서 한 번이라도 불러왔는지
  String? _error;

  List<Trip> get trips => _trips;

  String? get currentTripId => _currentTripId;

  bool get isLoading => _isLoading;

  bool get hasLoadedOnce => _hasLoadedOnce; // ⭐ getter
  String? get error => _error;

  Trip? get currentTrip {
    if (_currentTripId == null) {
      return _trips.isNotEmpty ? _trips.first : null;
    }
    try {
      return _trips.firstWhere((t) => t.id == _currentTripId);
    } catch (_) {
      return _trips.isNotEmpty ? _trips.first : null;
    }
  }

  void setCurrentTrip(String tripId) {
    _currentTripId = tripId;
    notifyListeners();
  }

  void addTrip(Trip trip) {
    _trips.add(trip);
    _currentTripId = trip.id;
    notifyListeners();
  }

  /// 서버 + 로컬에서 여행 삭제
  Future<void> deleteTrip({
    required String deviceUuid,
    required String deviceToken,
    required String tripId,
    bool purge = false,
  }) async {
    try {
      // 1) 서버에 삭제 요청
      await _api.deleteTrip(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        tripId: int.parse(tripId),
        purge: purge,
      );

      // 2) 삭제 성공하면 로컬 목록에서도 제거
      if (_trips.length > 1) {
        _trips.removeWhere((trip) => trip.id == tripId);

        if (_currentTripId == tripId) {
          _currentTripId = _trips.isNotEmpty ? _trips.first.id : null;
        }

        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// --------- 서버에서 Trip 리스트 불러오기 ---------
  Future<void> fetchTripsFromServer({
    required String deviceUuid,
    required String deviceToken,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.listTrips(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        status: 'all',
        limit: 20,
        offset: 0,
      );

      _trips.clear();
      for (final item in res.items) {
        _trips.add(_mapTripListItemToTrip(item));
      }

      if (_trips.isNotEmpty && _currentTripId == null) {
        _currentTripId = _trips.first.id;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true; // ⭐ 서버 호출은 한 번 끝났다!
      notifyListeners();
    }
  }

  Trip _mapTripListItemToTrip(TripListItem item) {
    final start = item.startDate ?? '';
    final end = item.endDate ?? '';

    // 🔹 제목이 없으면 공항 정보로 이름 만들어주기
    String name = item.title;
    if (name.isEmpty) {
      final from = item.fromAirport ?? '';
      final to = item.toAirport ?? '';
      if (from.isNotEmpty || to.isNotEmpty) {
        name = '$from → $to';
      } else {
        name = '새 여행';
      }
    }

    // 🔹 도착 공항이 없으면 출발 공항, 그것도 없으면 기본값
    final destination = item.toAirport ??
        item.fromAirport ??
        '여행';

    // 🔹 기간(몇 박 몇 일) 계산 – 날짜 없으면 빈 문자열
    String duration = '';
    if (start.isNotEmpty && end.isNotEmpty) {
      try {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        final days = e
            .difference(s)
            .inDays;
        if (days <= 0) {
          duration = '당일치기';
        } else {
          duration = '${days}박 ${days + 1}일';
        }
      } catch (_) {
        duration = '';
      }
    }

    return Trip(
      id: item.tripId.toString(),
      name: name,
      destination: destination,
      startDate: start,
      duration: duration,
    );
  }
}
