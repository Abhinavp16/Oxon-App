import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../providers/auth_provider.dart';

/// Handles background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Ref _ref;
  String? _currentToken;

  NotificationService(this._ref);

  Future<void> initialize() async {
    // Request permission (Android 13+ requires explicit permission)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getAndRegisterToken();
      _setupTokenRefreshListener();
      _setupForegroundMessageHandler();
    }
  }

  Future<void> _getAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
        await _registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed');
      _currentToken = newToken;
      await _registerTokenWithBackend(newToken);
    });
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      // The notification will auto-display on Android via the system tray
      // For foreground, we can show a local snackbar or in-app banner if needed
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.data}');
      // Handle navigation based on message data if needed
    });
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.post('/notifications/register-token', data: {
        'fcmToken': token,
        'platform': 'android',
      });
      debugPrint('[FCM] Token registered with backend');
    } on DioException catch (e) {
      // Don't crash if backend is unavailable — token will be re-sent on next refresh
      debugPrint('[FCM] Failed to register token: ${e.message}');
    }
  }

  String? get currentToken => _currentToken;
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
