/// API Configuration
/// Change these values based on your environment
library;

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Override at build/run time:
  // flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:5000/api/v1
  // or
  // flutter run --dart-define=API_LOCAL_IP=<YOUR_IP>
  static const String _explicitBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _localIp = String.fromEnvironment(
    'API_LOCAL_IP',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) {
      return _explicitBaseUrl;
    }

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:5000/api/v1';
    }

    if (_localIp.isNotEmpty) {
      return 'http://$_localIp:5000/api/v1';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return emulatorUrl;
    }

    return localhostUrl;
  }

  // Alternative URLs for reference
  static const String emulatorUrl = 'http://10.0.2.2:5000/api/v1';
  static const String localhostUrl = 'http://localhost:5000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
