import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationService = context.read<NotificationService>();
    final enabled = await notificationService.areNotificationsEnabled();

    setState(() {
      _notificationsEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);

    final notificationService = context.read<NotificationService>();
    await notificationService.setNotificationsEnabled(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable/Disable Toggle
          Card(
            child: SwitchListTile(
              title: const Text(
                'Enable Notifications',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Receive alerts for license renewals and compliance updates',
              ),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),

          const SizedBox(height: 16),

          // Notification Types
          const Text(
            'Notification Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications_active,
                    color: _notificationsEnabled ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Renewal Alerts'),
                  subtitle: const Text('30, 15, 7 days before expiry'),
                  trailing: Icon(
                    _notificationsEnabled ? Icons.check_circle : Icons.cancel,
                    color: _notificationsEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.update,
                    color: _notificationsEnabled ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Compliance Updates'),
                  subtitle: const Text('Rule changes and new requirements'),
                  trailing: Icon(
                    _notificationsEnabled ? Icons.check_circle : Icons.cancel,
                    color: _notificationsEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.warning_amber,
                    color: _notificationsEnabled ? Colors.orange : Colors.grey,
                  ),
                  title: const Text('Expiry Warnings'),
                  subtitle: const Text('Immediate alerts for expired licenses'),
                  trailing: Icon(
                    _notificationsEnabled ? Icons.check_circle : Icons.cancel,
                    color: _notificationsEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Text(
                      'About Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Renewal alerts help you stay compliant\n'
                  '• Notifications are sent at optimal times\n'
                  '• You can disable them anytime\n'
                  '• Critical alerts may still appear',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[900],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
