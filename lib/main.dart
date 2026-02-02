import 'package:awesome/app/app.dart';
import 'package:awesome/core/di/injection.dart';
import 'package:awesome/core/services/local_notification_service.dart';
import 'package:awesome/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FirebaseMessaging.onBackgroundMessage();

  configureDependencies();
  getIt<LocalNotificationService>();

  runApp(const App());
}
