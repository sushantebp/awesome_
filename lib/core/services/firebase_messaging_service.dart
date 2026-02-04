import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

import 'local_notification_service.dart';

@lazySingleton
class FirebaseMessagingService {
  FirebaseMessagingService(this._localNotificationService);

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotificationService;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1️⃣ Request permission (iOS + Android 13+)
    await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    late String? token;
    if (Platform.isIOS) {
      token = await _firebaseMessaging.getAPNSToken();
      if (token == null) {
        await Future<void>.delayed(const Duration(seconds: 3));
        token = await _firebaseMessaging.getAPNSToken();
      }
    } else {
      token = await _firebaseMessaging.getToken();
    }
    // 2️⃣ Get FCM token
    dev.log("Token = $token");

    // 3️⃣ Foreground message handling
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 4️⃣ Notification tap (background → app opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 5️⃣ Terminated state handling
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageClick(initialMessage);
    }

    _initialized = true;
  }

  /// FOREGROUND → must show local notification manually
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'Notification';
    final body = notification?.body ?? data['body'] ?? '';

    if (title.isEmpty && body.isEmpty) return;
    dev.log("Remote Message Received, Title = $title and Body = $body");

    await _localNotificationService.showNotification(
      id: _generateNotificationId(),
      title: title,
      body: body,
      payload: data.isNotEmpty ? data.toString() : null,
    );
    dev.log("After local notification is invoked");
  }

  /// BACKGROUND → user tapped system notification
  void _onMessageOpenedApp(RemoteMessage message) {
    dev.log('Notification opened from background');
    _handleMessageClick(message);
  }

  /// COMMON tap handler
  void _handleMessageClick(RemoteMessage message) {
    dev.log('Notification payload: ${message.data}');

    // TODO:
    // - Navigate to specific screen
    // - Use event bus / stream
  }

  int _generateNotificationId() => Random().nextInt(100000);
}
