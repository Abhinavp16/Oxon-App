import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../providers/auth_provider.dart';
import '../router/app_router.dart';

const _notificationChannelId = 'veepee_default';
const _notificationChannelName = 'General notifications';

/// Handles background messages in a background isolate. Navigation must wait
/// until the app UI is active, where [onMessageOpenedApp] handles the tap.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationIntent {
  const NotificationIntent._(this.location);

  final String location;

  static NotificationIntent fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase() ?? '';
    final orderId = data['orderId']?.toString().trim() ?? '';
    final productId = data['productId']?.toString().trim() ?? '';

    if (orderId.isNotEmpty) {
      return NotificationIntent._('/tracking/${Uri.encodeComponent(orderId)}');
    }
    if (type == 'order_update' ||
        type == 'payment_verified' ||
        type == 'payment_rejected') {
      return const NotificationIntent._('/previous-orders');
    }
    if (type == 'price_change' && productId.isNotEmpty) {
      return NotificationIntent._('/product/${Uri.encodeComponent(productId)}');
    }
    return const NotificationIntent._('/notifications');
  }
}

class NotificationService {
  NotificationService(this._ref);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Ref _ref;

  static final List<NotificationIntent> _pendingIntents = [];
  static bool _navigationReady = false;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  bool _initialized = false;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );
    _listenForAuthentication();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getToken();
      _setupTokenRefreshListener();
      _setupMessageHandlers();
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            _handleNotificationData(Map<String, dynamic>.from(decoded));
          }
        } catch (error) {
          debugPrint('[Local notification] Invalid payload: $error');
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Order and product updates',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _listenForAuthentication() {
    _ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _registerCurrentToken();
      }
    });
  }

  Future<void> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        debugPrint('[FCM] Token obtained');
        await _registerCurrentToken();
      }
    } catch (error) {
      debugPrint('[FCM] Error getting token: $error');
    }
  }

  void _setupTokenRefreshListener() {
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerCurrentToken();
    });
  }

  void _setupMessageHandlers() {
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      await _showForegroundNotification(message);
      if (message.data['type'] == 'ROLE_UPDATED') {
        _ref.read(authProvider.notifier).fetchCurrentUser();
      }
    });
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('[FCM] Message opened app: ${message.data}');
      if (message.data['type'] == 'ROLE_UPDATED') {
        _ref.read(authProvider.notifier).fetchCurrentUser();
      }
      _handleNotificationData(message.data);
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final payload = jsonEncode(message.data);
    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: 'Order and product updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );

    scafoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationData(message.data),
        ),
      ),
    );
  }

  void handleNotificationData(Map<String, dynamic> data) {
    _handleNotificationData(data);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final intent = NotificationIntent.fromData(data);
    if (!_navigationReady) {
      _pendingIntents.add(intent);
      return;
    }
    appRouter.go(intent.location);
  }

  void markNavigationReady() {
    _navigationReady = true;
    if (_pendingIntents.isEmpty) return;
    final intent = _pendingIntents.removeLast();
    _pendingIntents.clear();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => appRouter.go(intent.location),
    );
  }

  Future<void> _registerCurrentToken() async {
    final token = _currentToken;
    if (token == null || !_ref.read(authProvider).isAuthenticated) return;
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(
        '/notifications/register-token',
        data: {
          'fcmToken': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      debugPrint('[FCM] Token registered with backend');
    } on DioException catch (error) {
      debugPrint('[FCM] Failed to register token: ${error.message}');
    }
  }

  String? get currentToken => _currentToken;

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedAppSubscription?.cancel();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
