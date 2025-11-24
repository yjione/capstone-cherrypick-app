// lib/providers/reference_provider.dart
import 'package:flutter/material.dart';
import '../service/reference_api.dart';
import '../models/country_ref.dart';
import '../models/airport_ref.dart';
import '../models/airline_ref.dart';
import '../models/cabin_class_ref.dart';

class ReferenceProvider extends ChangeNotifier {
  final ReferenceApiService api;

  ReferenceProvider({required this.api});

  // ------- Countries -------
  List<CountryRef> _countries = [];
  bool _isLoadingCountries = false;
  String? _countriesError;

  List<CountryRef> get countries => _countries;
  bool get isLoadingCountries => _isLoadingCountries;
  String? get countriesError => _countriesError;

  Future<void> fetchCountries({
    required String deviceUuid,
    required String deviceToken,
    String? q,
    String? region,
    bool activeOnly = true,
  }) async {
    _isLoadingCountries = true;
    _countriesError = null;
    notifyListeners();

    try {
      _countries = await api.listCountries(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        q: q,
        region: region,
        activeOnly: activeOnly,
      );
    } catch (e) {
      _countriesError = e.toString();
    } finally {
      _isLoadingCountries = false;
      notifyListeners();
    }
  }

  // ------- Airports (country별 캐시) -------

  final Map<String, List<AirportRef>> _airportsByCountry = {};
  bool _isLoadingAirports = false;
  String? _airportsError;

  bool get isLoadingAirports => _isLoadingAirports;
  String? get airportsError => _airportsError;

  List<AirportRef> airportsForCountry(String countryCode) {
    return _airportsByCountry[countryCode] ?? const [];
  }

  Future<void> fetchAirports({
    required String deviceUuid,
    required String deviceToken,
    required String countryCode,
    String? q,
    int limit = 100,
    bool activeOnly = true,
  }) async {
    _isLoadingAirports = true;
    _airportsError = null;
    notifyListeners();

    try {
      final airports = await api.listAirports(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        countryCode: countryCode,
        q: q,
        limit: limit,
        activeOnly: activeOnly,
      );
      _airportsByCountry[countryCode] = airports;
    } catch (e) {
      _airportsError = e.toString();
    } finally {
      _isLoadingAirports = false;
      notifyListeners();
    }
  }

  // ------- Airlines -------
  List<AirlineRef> _airlines = [];
  bool _isLoadingAirlines = false;
  String? _airlinesError;

  List<AirlineRef> get airlines => _airlines;
  bool get isLoadingAirlines => _isLoadingAirlines;
  String? get airlinesError => _airlinesError;

  Future<void> fetchAirlines({
    required String deviceUuid,
    required String deviceToken,
    String? q,
    bool activeOnly = true,
  }) async {
    _isLoadingAirlines = true;
    _airlinesError = null;
    notifyListeners();

    try {
      _airlines = await api.listAirlines(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        q: q,
        activeOnly: activeOnly,
      );
    } catch (e) {
      _airlinesError = e.toString();
    } finally {
      _isLoadingAirlines = false;
      notifyListeners();
    }
  }

  // ------- Cabin classes (airline별 캐시) -------
  final Map<String, List<CabinClassRef>> _cabinClassesByAirline = {};
  bool _isLoadingCabinClasses = false;
  String? _cabinClassesError;

  bool get isLoadingCabinClasses => _isLoadingCabinClasses;
  String? get cabinClassesError => _cabinClassesError;

  List<CabinClassRef> cabinClassesForAirline(String airlineCode) {
    return _cabinClassesByAirline[airlineCode] ?? const [];
  }

  Future<void> fetchCabinClasses({
    required String deviceUuid,
    required String deviceToken,
    required String airlineCode,
  }) async {
    _isLoadingCabinClasses = true;
    _cabinClassesError = null;
    notifyListeners();

    try {
      final result = await api.listCabinClasses(
        deviceUuid: deviceUuid,
        deviceToken: deviceToken,
        airlineCode: airlineCode,
      );
      _cabinClassesByAirline[airlineCode] = result;
    } catch (e) {
      _cabinClassesError = e.toString();
    } finally {
      _isLoadingCabinClasses = false;
      notifyListeners();
    }
  }
}
