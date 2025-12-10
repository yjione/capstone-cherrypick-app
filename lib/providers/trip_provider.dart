// lib/providers/trip_provider.dart
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../service/trip_api.dart';

class TripProvider extends ChangeNotifier {
  final TripApiService _api = TripApiService();

  final List<Trip> _trips = [];
  String? _currentTripId;

  bool _isLoading = false;
  bool _hasLoadedOnce = false; // 서버에서 한 번이라도 불러왔는지
  String? _error;

  List<Trip> get trips => _trips;
  String? get currentTripId => _currentTripId;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
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

  Future<void> deleteTrip({
    required String deviceUuid,
    required String deviceToken,
    required String tripId,
    bool purge = false,
  }) async {
    try {
      await _api.deleteTrip(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        tripId: int.parse(tripId),
        purge: purge,
      );

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
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  Trip _mapTripListItemToTrip(TripListItem item) {
    final start = item.startDate ?? '';
    final end = item.endDate ?? '';
    final duration = _calcDuration(start, end);

    return Trip(
      id: item.tripId.toString(),
      name: item.title,
      destination: item.toAirport ?? '',
      startDate: start,
      duration: duration,
    );
  }

  Future<void> updateDurationOnServer({
    required String deviceUuid,
    required String deviceToken,
    required String tripId,
    required String startDate,
    required String endDate,
  }) async {
    final info = await _api.updateTripDuration(
      deviceUuid: deviceUuid,
      deviceToken: deviceToken,
      tripId: int.parse(tripId),
      startDate: startDate,
      endDate: endDate,
    );

    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      final durationText = _calcDuration(info.startDate, info.endDate);
      _trips[idx] = _trips[idx].copyWith(
        startDate: info.startDate,
        duration: durationText,
      );
      notifyListeners();
    }
  }

  String _calcDuration(String start, String end) {
    if (start.isEmpty || end.isEmpty) return '';

    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final nights = e.difference(s).inDays;
      if (nights <= 0) {
        return '당일치기';
      }
      return '${nights}박 ${nights + 1}일';
    } catch (_) {
      return '';
    }
  }
}
