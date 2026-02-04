import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('FCM Background Message: ${message.messageId}');
  // ❌ DO NOT show local notification here
  // OS already displays it if payload has `notification`
}
