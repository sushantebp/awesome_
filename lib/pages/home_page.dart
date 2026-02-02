import 'package:auto_route/auto_route.dart';
import 'package:awesome/core/di/injection.dart';
import 'package:awesome/core/services/local_notification_service.dart';
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
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    try {
      await _notificationService.init();
      await _loadPendingNotifications();
    } catch (e) {
      _showSnackBar('Error initializing notifications: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() => _pendingNotifications = pending);
    } catch (e) {
      _showSnackBar('Error loading notifications: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showInstantNotification() async {
    try {
      await _notificationService.showNotification(
        id: 0,
        title: 'Instant Notification',
        body: 'This notification appears immediately!',
        payload: 'instant',
      );
      _showSnackBar('Instant notification sent!');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _scheduleNotification(int seconds, String label) async {
    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
      await _notificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '$label Notification',
        body: 'This notification was scheduled $seconds seconds ago',
        scheduledDate: scheduledTime,
        payload: 'scheduled_$seconds',
      );
      _showSnackBar('Notification scheduled for ${seconds}s from now');
      await _loadPendingNotifications();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _scheduleDailyNotification() async {
    try {
      await _notificationService.scheduleDailyNotification(
        id: 100,
        title: 'Daily Reminder',
        body: 'Good morning! Time to start your day',
        time: const TimeOfDayValue(hour: 9, minute: 0),
        payload: 'daily_morning',
      );
      _showSnackBar('Daily notification scheduled for 9:00 AM');
      await _loadPendingNotifications();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _scheduleWeeklyNotification() async {
    try {
      await _notificationService.scheduleWeeklyNotification(
        id: 200,
        title: 'Weekly Reminder',
        body: 'Start your week strong! 💪',
        weekday: DateTime.monday,
        time: const TimeOfDayValue(hour: 10, minute: 0),
        payload: 'weekly_monday',
      );
      _showSnackBar('Weekly notification scheduled for Mondays at 10:00 AM');
      await _loadPendingNotifications();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _showCustomDateTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final scheduledDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        try {
          await _notificationService.scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: 'Custom Scheduled Notification',
            body: 'Scheduled for ${_formatDateTime(scheduledDateTime)}',
            scheduledDate: scheduledDateTime,
            payload: 'custom_schedule',
          );
          _showSnackBar('Notification scheduled successfully');
          await _loadPendingNotifications();
        } catch (e) {
          _showSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      _showSnackBar('All notifications cancelled');
      await _loadPendingNotifications();
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instant Notifications Section
                  _buildSectionTitle('Instant Notifications'),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.notifications_active,
                    label: 'Show Instant Notification',
                    onPressed: _showInstantNotification,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  // Scheduled Notifications Section
                  _buildSectionTitle('Scheduled Notifications'),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.access_time,
                    label: 'Schedule in 3 Seconds',
                    onPressed: () => _scheduleNotification(3, '3 Second'),
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.schedule,
                    label: 'Schedule in 10 Seconds',
                    onPressed: () => _scheduleNotification(10, '10 Second'),
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.timer,
                    label: 'Schedule in 1 Minute',
                    onPressed: () => _scheduleNotification(60, '1 Minute'),
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 24),

                  // Recurring Notifications Section
                  _buildSectionTitle('Recurring Notifications'),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.today,
                    label: 'Daily at 9:00 AM',
                    onPressed: _scheduleDailyNotification,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.calendar_today,
                    label: 'Weekly (Monday 10:00 AM)',
                    onPressed: _scheduleWeeklyNotification,
                    color: Colors.teal,
                  ),

                  const SizedBox(height: 24),

                  // Custom Date/Time Section
                  _buildSectionTitle('Custom Schedule'),
                  const SizedBox(height: 12),
                  _buildNotificationButton(
                    icon: Icons.event,
                    label: 'Pick Custom Date & Time',
                    onPressed: _showCustomDateTimePicker,
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 32),

                  // Cancel All Button
                  _buildNotificationButton(
                    icon: Icons.cancel,
                    label: 'Cancel All Notifications',
                    onPressed: _cancelAllNotifications,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 32),

                  // Pending Notifications List
                  _buildSectionTitle(
                    'Pending Notifications (${_pendingNotifications.length})',
                  ),
                  const SizedBox(height: 12),

                  if (_pendingNotifications.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending notifications',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._pendingNotifications.map((notification) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.blue,
                            ),
                          ),
                          title: Text(
                            notification.title ?? 'No title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            notification.body ?? 'No body',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _notificationService.cancelNotification(
                                notification.id,
                              );
                              _showSnackBar('Notification cancelled');
                              await _loadPendingNotifications();
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
