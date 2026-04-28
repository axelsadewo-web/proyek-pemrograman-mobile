import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';

// ============================================================================
// SETTINGS SERVICES
// ============================================================================

/// Service untuk mengelola settings aplikasi
class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _notificationTimeKey = 'notification_time';

  static late SharedPreferences _prefs;

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Theme Mode
  static ThemeMode getThemeMode() {
    final value = _prefs.getString(_themeKey) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await _prefs.setString(_themeKey, value);
  }

  /// Notification Settings
  static bool getNotificationEnabled() {
    return _prefs.getBool(_notificationEnabledKey) ?? false;
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs.setBool(_notificationEnabledKey, enabled);
  }

  static TimeOfDay getNotificationTime() {
    final timeString = _prefs.getString(_notificationTimeKey) ?? '09:00';
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static Future<void> setNotificationTime(TimeOfDay time) async {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await _prefs.setString(_notificationTimeKey, timeString);
  }
}

/// Service untuk backup dan restore data
class BackupService {
  /// Backup data ke file JSON
  static Future<String?> backupData(List<dynamic> habits) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'habit_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'habits': habits.map((habit) => habit.toMap()).toList(),
        'version': '1.0',
      };

      await file.writeAsString(jsonEncode(backupData));
      return file.path;
    } catch (e) {
      debugPrint('Backup failed: $e');
      return null;
    }
  }

  /// Restore data dari file JSON
  static Future<Map<String, dynamic>?> restoreData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup format
      if (!data.containsKey('habits') || !data.containsKey('version')) {
        throw Exception('Invalid backup format');
      }

      return data;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return null;
    }
  }

  /// Get list backup files
  static Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = Directory(directory.path)
          .listSync()
          .where((file) => file.path.contains('habit_backup_') && file.path.endsWith('.json'))
          .toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  /// Export data ke CSV
  static Future<String?> exportToCSV(List<dynamic> habits) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'habit_export_$timestamp.csv';
      final file = File('${directory.path}/$fileName');

      // CSV Header
      final headers = [
        'ID',
        'Name',
        'Description',
        'Category',
        'Target',
        'Streak',
        'Last Completed',
        'Created At',
        'History Count'
      ];

      final csvContent = StringBuffer();
      csvContent.writeln(headers.join(','));

      // CSV Data
      for (final habit in habits) {
        final row = [
          habit.id,
          '"${habit.name.replaceAll('"', '""')}"',
          '"${habit.description.replaceAll('"', '""')}"',
          habit.category,
          habit.target,
          habit.streak,
          habit.lastCompletedDate ?? '',
          habit.createdAt.toIso8601String(),
          habit.historyDates.length,
        ];
        csvContent.writeln(row.join(','));
      }

      await file.writeAsString(csvContent.toString());
      return file.path;
    } catch (e) {
      debugPrint('CSV export failed: $e');
      return null;
    }
  }
}

/// Service untuk notifikasi
class NotificationService {
  static const String channelId = 'habit_reminder_channel';
  static const String channelName = 'Habit Reminders';
  static const String channelDescription = 'Daily habit completion reminders';

  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  /// Initialize notifications
  static Future<void> initialize() async {
    _notificationsPlugin ??= FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin?.initialize(settings);
  }

  /// Request permissions
  static Future<bool> requestPermissions() async {
    final androidPlugin = _notificationsPlugin?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final iosPlugin = _notificationsPlugin?.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await androidPlugin?.requestNotificationsPermission() ?? false;
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    ) ?? false;

    return androidGranted || iosGranted;
  }

  /// Schedule daily reminder
  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    if (_notificationsPlugin == null) return;

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika waktu sudah lewat hari ini, schedule untuk besok
    final reminderTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      sound: AndroidNotificationSound.defaultSound,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'default.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin?.zonedSchedule(
      0, // notification id
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin?.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin?.cancel(id);
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin?.pendingNotificationRequests() ?? [];
  }

  /// Show test notification
  static Future<void> showTestNotification() async {
    if (_notificationsPlugin == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin?.show(
      999,
      'Test Reminder',
      'Ini adalah notifikasi test untuk habit tracker!',
      details,
    );
  }
}

// ============================================================================
// RIVERPOD PROVIDERS FOR SETTINGS
// ============================================================================

/// Provider untuk theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    await SettingsService.initialize();
    state = SettingsService.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await SettingsService.setThemeMode(mode);
  }
}

/// Provider untuk notification settings
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, Map<String, dynamic>>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  NotificationSettingsNotifier() : super({
    'enabled': false,
    'time': const TimeOfDay(hour: 9, minute: 0),
  }) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await SettingsService.initialize();
    state = {
      'enabled': SettingsService.getNotificationEnabled(),
      'time': SettingsService.getNotificationTime(),
    };
  }

  Future<void> setEnabled(bool enabled) async {
    state = {...state, 'enabled': enabled};
    await SettingsService.setNotificationEnabled(enabled);

    if (enabled) {
      await NotificationService.initialize();
      await NotificationService.requestPermissions();
      await _scheduleNotification();
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  Future<void> setTime(TimeOfDay time) async {
    state = {...state, 'time': time};
    await SettingsService.setNotificationTime(time);

    if (state['enabled'] == true) {
      await _scheduleNotification();
    }
  }

  Future<void> _scheduleNotification() async {
    final time = state['time'] as TimeOfDay;
    await NotificationService.scheduleDailyReminder(
      time: time,
      title: 'Habit Reminder',
      body: 'Jangan lupa selesaikan kebiasaan harian Anda!',
    );
  }
}

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildAppearanceSettings(themeMode),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildNotificationSettings(notificationSettings),

          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildDataManagementSettings(),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(ThemeMode currentTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeModeText(currentTheme)),
            trailing: DropdownButton<ThemeMode>(
              value: currentTheme,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: const Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: const Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: const Text('Dark'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(Map<String, dynamic> settings) {
    final enabled = settings['enabled'] as bool;
    final time = settings['time'] as TimeOfDay;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Daily Reminders'),
            subtitle: const Text('Get notified to complete your habits'),
            value: enabled,
            onChanged: (value) {
              ref.read(notificationSettingsProvider.notifier).setEnabled(value);
            },
          ),
          if (enabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Reminder Time'),
              subtitle: Text(time.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(context, time),
            ),
          if (enabled)
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Test Notification'),
              subtitle: const Text('Send a test reminder'),
              trailing: const Icon(Icons.send),
              onTap: () => NotificationService.showTestNotification(),
            ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Save habits data to local file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _backupData(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Load habits data from backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _restoreData(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export to CSV'),
            subtitle: const Text('Export habits data as CSV file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportToCSV(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Tracker Pro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A comprehensive habit tracking app with streaks, statistics, and daily reminders.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      default:
        return 'System Default';
    }
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay currentTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && picked != currentTime) {
      ref.read(notificationSettingsProvider.notifier).setTime(picked);
    }
  }

  Future<void> _backupData() async {
    try {
      // Get habits data (you would get this from your provider)
      final habits = []; // TODO: Get from provider

      final backupPath = await BackupService.backupData(habits);

      if (backupPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup berhasil: ${backupPath.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreData() async {
    try {
      final backupFiles = await BackupService.getBackupFiles();

      if (backupFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada file backup ditemukan'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show file picker (simplified - in real app use file_picker)
      final filePath = backupFiles.first.path; // Use first file for demo

      final backupData = await BackupService.restoreData(filePath);

      if (backupData != null) {
        // TODO: Restore habits data to provider
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil direstore'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore gagal - format file tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Get habits data (you would get this from your provider)
      final habits = []; // TODO: Get from provider

      final csvPath = await BackupService.exportToCSV(habits);

      if (csvPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export berhasil: ${csvPath.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}