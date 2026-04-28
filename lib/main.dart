import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/daily_habit_model.dart';
import 'screens/daily_habit_tracker_screen.dart';
import 'screens/add_edit_habit_screen.dart';
import 'screens/statistics_screen.dart';

// ============================================================================
// MAIN APP
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await HabitStorageService.initializeBox();

  // Request notification permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _requestPermissions() async {
  // Request notification permission
  final notificationStatus = await Permission.notification.request();

  // Request exact alarm permission for Android 12+
  if (await Permission.scheduleExactAlarm.isGranted == false) {
    await Permission.scheduleExactAlarm.request();
  }

  debugPrint('Notification permission: $notificationStatus');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      routes: {
        '/add-habit': (context) => const AddEditHabitScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/reminder-settings': (context) => const ReminderSettingsScreen(),
      },
    );
  }
}

// ============================================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DailyHabitTrackerScreen(),
    const StatisticsScreen(),
    const ReminderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Habits',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminder',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _addNewHabit(context),
              child: const Icon(Icons.add),
              tooltip: 'Tambah Habit Baru',
            )
          : null,
    );
  }

  void _addNewHabit(BuildContext context) {
    Navigator.pushNamed(context, '/add-habit').then((result) {
      if (result is Habit) {
        // Habit returned from AddEditHabitScreen.
        // For now, just show success message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}
