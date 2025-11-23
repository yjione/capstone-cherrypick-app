// lib/providers/trip_provider.dart
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../service/trip_api.dart';

class TripProvider extends ChangeNotifier {
  final TripApiService _api = TripApiService();

  final List<Trip> _trips = [];
  String? _currentTripId;

  bool _isLoading = false;
  bool _hasLoadedOnce = false;          // ⭐ 서버에서 한 번이라도 불러왔는지
  String? _error;

  List<Trip> get trips => _trips;
  String? get currentTripId => _currentTripId;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;   // ⭐ getter
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

  void deleteTrip(String tripId) {
    if (_trips.length > 1) {
      _trips.removeWhere((trip) => trip.id == tripId);
      if (_currentTripId == tripId) {
        _currentTripId = _trips.first.id;
      }
      notifyListeners();
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
      _hasLoadedOnce = true;     // ⭐ 서버 호출은 한 번 끝났다!
      notifyListeners();
    }
  }

  Trip _mapTripListItemToTrip(TripListItem item) {
    final start = item.startDate ?? '';
    final end = item.endDate ?? '';

    String duration = '';
    if (start.isNotEmpty && end.isNotEmpty) {
      try {
        final s = DateTime.parse(start);
        final e = DateTime.parse(end);
        final days = e.difference(s).inDays;
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
      name: item.title,
      destination: item.toAirport ?? '',
      startDate: start,
      duration: duration,
    );
  }
}
