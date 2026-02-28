/// API Configuration
/// Change these values based on your environment
library;

class ApiConfig {
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use localhost or 127.0.0.1
  // For Physical Device: use your computer's local IP (e.g., 192.168.1.100)
  // Run 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux) to find your IP
  // CURRENT IP (Check 'ipconfig' in Windows)
  static const String localIp = '192.168.1.14';

  // Base URL - Change this based on where you are running the app
  static const String baseUrl = 'http://$localIp:5000/api/v1';

  // Alternative URLs for reference
  static const String emulatorUrl = 'http://10.0.2.2:5000/api/v1';
  static const String localhostUrl = 'http://localhost:5000/api/v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
