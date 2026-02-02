import 'package:awesome/core/di/injection.dart';
import 'package:awesome/core/routes/app_router.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>();
    return MaterialApp.router(routerConfig: router.config());
  }
}
