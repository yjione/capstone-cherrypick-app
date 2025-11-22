// lib/providers/device_provider.dart
import 'package:flutter/foundation.dart';

import '../models/device_register.dart';
import '../service/device_api.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceApiService api;

  DeviceProvider({required this.api});

  String? _deviceUuid;          // ✅ UUID 보관
  String? _deviceToken;
  bool _isRegistering = false;
  String? _error;

  String? get deviceUuid => _deviceUuid;
  String? get deviceToken => _deviceToken;
  bool get isRegistering => _isRegistering;
  String? get error => _error;

  // 앱 시작 시 한 번만 호출해두면 됨
  Future<void> registerIfNeeded({
    required String appVersion,
    required String os,
    required String model,
    required String locale,
    required String timezone,
    required String deviceUuid,
  }) async {
    // ✅ uuid는 항상 저장해두자 (헤더에 써야 해서)
    _deviceUuid ??= deviceUuid;

    // 이미 토큰이 있거나 등록 중이면 다시 호출하지 않음
    if (_deviceToken != null || _isRegistering) {
      return;
    }

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
        deviceUuid: deviceUuid,
      );

      final res = await api.registerDevice(req);
      _deviceToken = res.deviceToken;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRegistering = false;
      notifyListeners();
    }
  }
}
