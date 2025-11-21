// lib/models/device_register.dart
class DeviceRegisterRequest {
  final String appVersion;
  final String os;
  final String model;
  final String locale;
  final String timezone;
  final String deviceUuid;

  DeviceRegisterRequest({
    required this.appVersion,
    required this.os,
    required this.model,
    required this.locale,
    required this.timezone,
    required this.deviceUuid,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion,
      'os': os,
      'model': model,
      'locale': locale,
      'timezone': timezone,
      'device_uuid': deviceUuid,
    };
  }
}

class DeviceRegisterResponse {
  final String deviceToken;
  final bool safetyMode;
  final bool tipsEnabled;
  final String abTestBucket;
  final int expiresIn;

  DeviceRegisterResponse({
    required this.deviceToken,
    required this.safetyMode,
    required this.tipsEnabled,
    required this.abTestBucket,
    required this.expiresIn,
  });

  factory DeviceRegisterResponse.fromJson(Map<String, dynamic> json) {
    final featureFlags = json['feature_flags'] as Map<String, dynamic>? ?? {};
    return DeviceRegisterResponse(
      deviceToken: json['device_token'] as String,
      safetyMode: featureFlags['safety_mode'] as bool? ?? true,
      tipsEnabled: featureFlags['tips_enabled'] as bool? ?? true,
      abTestBucket: json['ab_test_bucket'] as String? ?? 'control',
      expiresIn: json['expires_in'] as int? ?? 0,
    );
  }
}
