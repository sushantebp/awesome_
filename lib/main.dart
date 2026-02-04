import 'package:awesome/app/app.dart';
import 'package:awesome/core/di/injection.dart';
import 'package:awesome/core/services/background_handler.dart';
import 'package:awesome/core/services/firebase_messaging_service.dart';
import 'package:awesome/core/services/local_notification_service.dart';
import 'package:awesome/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  configureDependencies();
  getIt<LocalNotificationService>().init();
  getIt<FirebaseMessagingService>().init();

  runApp(const App());
}
