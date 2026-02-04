import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:awesome/core/di/injection.dart';
import 'package:awesome/core/services/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _notificationService = getIt<LocalNotificationService>();

  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  // ─────────────────────────────────────────────────────────────
  // Local notifications
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() => _pendingNotifications = pending);
    } catch (e) {
      _showSnackBar('Failed to load notifications: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showInstantNotification() async {
    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Instant Notification',
      body: 'This is a local notification',
      payload: 'instant',
    );
    _showSnackBar('Instant notification shown');
  }

  Future<void> _scheduleNotification(int seconds) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));

    await _notificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Scheduled Notification',
      body: 'Scheduled after $seconds seconds',
      scheduledDate: scheduledTime,
      payload: 'scheduled_$seconds',
    );

    _showSnackBar('Scheduled in $seconds seconds');
    await _loadPendingNotifications();
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    _showSnackBar('All notifications cancelled');
    await _loadPendingNotifications();
  }

  // ─────────────────────────────────────────────────────────────
  // Push notification helper (FCM)
  // ─────────────────────────────────────────────────────────────

  Future<void> _showFcmToken() async {
    late String? token;
    if (Platform.isIOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
    } else if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('FCM Token'),
        content: SelectableText(token ?? 'Token not available'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // UI helpers
  // ─────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPendingNotifications)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('Local Notifications'),

                  ElevatedButton(onPressed: _showInstantNotification, child: const Text('Show Instant Notification')),
                  const SizedBox(height: 12),

                  ElevatedButton(onPressed: () => _scheduleNotification(5), child: const Text('Schedule in 5 seconds')),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: _cancelAllNotifications,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancel All Notifications'),
                  ),

                  const SizedBox(height: 32),
                  _sectionTitle('Push Notifications'),

                  ElevatedButton(onPressed: _showFcmToken, child: const Text('Show FCM Token')),

                  const SizedBox(height: 32),
                  _sectionTitle('Pending Notifications (${_pendingNotifications.length})'),

                  if (_pendingNotifications.isEmpty)
                    const Text('No pending notifications')
                  else
                    ..._pendingNotifications.map(
                      (n) => ListTile(
                        title: Text(n.title ?? 'No title'),
                        subtitle: Text(n.body ?? 'No body'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _notificationService.cancelNotification(n.id);
                            await _loadPendingNotifications();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
