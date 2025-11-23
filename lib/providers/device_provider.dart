// lib/providers/device_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_register.dart';
import '../service/device_api.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceApiService api;

  DeviceProvider({required this.api});

  String? _deviceUuid;
  String? _deviceToken;
  bool _isRegistering = false;
  String? _error;

  String? get deviceUuid => _deviceUuid;
  String? get deviceToken => _deviceToken;
  bool get isRegistering => _isRegistering;
  String? get error => _error;

  /// 앱 시작할 때 저장된 uuid/token을 불러오기
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceUuid = prefs.getString('deviceUuid');
    _deviceToken = prefs.getString('deviceToken');
    notifyListeners();
  }

  /// uuid/token 저장
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_deviceUuid != null) {
      await prefs.setString('deviceUuid', _deviceUuid!);
    }
    if (_deviceToken != null) {
      await prefs.setString('deviceToken', _deviceToken!);
    }
  }

  /// 앱 설치 이후 최초 1회만 register 호출됨
  Future<void> registerIfNeeded({
    required String appVersion,
    required String os,
    required String model,
    required String locale,
    required String timezone,
    required String deviceUuid,
  }) async {
    // 저장된 uuid/token 로드
    await loadFromStorage();

    // uuid는 항상 저장해두자 (헤더에 필요)
    _deviceUuid ??= deviceUuid;

    // 이미 등록되어 있다면 호출 종료
    if (_deviceToken != null) {
      return;
    }

    if (_isRegistering) return;

    _isRegistering = true;
    _error = null;
    notifyListeners();

    try {
      final req = DeviceRegisterRequest(
        appVersion: appVersion,
        os: os,
        model: model,
        locale: locale,
        timezone: timezone,
        deviceUuid: _deviceUuid!,
      );

      final res = await api.registerDevice(req);
      _deviceToken = res.deviceToken;

      // 로컬 저장
      await _saveToStorage();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }
}
