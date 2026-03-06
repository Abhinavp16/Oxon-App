/// API Configuration
/// Change these values based on your environment
library;

class ApiConfig {
  // Override at build/run time:
  // flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:5000/api/v1
  // or
  // flutter run --dart-define=API_LOCAL_IP=<YOUR_IP>
  //
  // Current fallback host IP from local machine config.
  static const String localIp = String.fromEnvironment(
    'API_LOCAL_IP',
    defaultValue: '192.168.1.3',
  );

  // Base URL (can be overridden with API_BASE_URL).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://$localIp:5000/api/v1',
  );

  // Alternative URLs for reference
  static const String emulatorUrl = 'http://10.0.2.2:5000/api/v1';
  static const String localhostUrl = 'http://localhost:5000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
