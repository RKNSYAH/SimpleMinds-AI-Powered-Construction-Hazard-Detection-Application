import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static const bool _devBackendBypassFlag =
      bool.fromEnvironment('DEV_BACKEND_BYPASS', defaultValue: false);
  static const String _backendEnabledKey = 'backend_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static bool get allowsBackendBypass =>
      kDebugMode && _devBackendBypassFlag;

  static Future<bool> isBackendEnabled() async {
    if (!allowsBackendBypass) {
      return true;
    }

    final value = await _storage.read(key: _backendEnabledKey);
    if (value == null) {
      return true;
    }
    return value == 'true';
  }

  static Future<void> setBackendEnabled(bool enabled) {
    if (!allowsBackendBypass) {
      return Future.value();
    }

    return _storage.write(
      key: _backendEnabledKey,
      value: enabled.toString(),
    );
  }
}