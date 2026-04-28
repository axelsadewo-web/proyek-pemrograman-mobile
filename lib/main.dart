import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/daily_habit_model.dart';
import 'screens/daily_habit_tracker_screen.dart';
import 'screens/add_edit_habit_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'services/home_widget_service.dart';

// ============================================================================
// MAIN APP
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();
  await HabitStorageService.initializeBox();

  // Initialize Home Widget
  await HomeWidget.setAppGroupId('group.habit_tracker_widget');

  // Initialize Localization
  await LocalizationService.initialize();

  // Request permissions
  await _requestPermissions();

  runApp(
    const ProviderScope(
      child: LocalizedApp(
        child: MyApp(),
      ),
    ),
  );
}

Future<void> _requestPermissions() async {
  // Request notification permission
  final notificationStatus = await Permission.notification.request();

  // Request exact alarm permission for Android 12+
  if (await Permission.scheduleExactAlarm.isGranted == false) {
    await Permission.scheduleExactAlarm.request();
  }

  // Request storage permission for exports
  await Permission.storage.request();

  debugPrint('Notification permission: $notificationStatus');
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to determine initial screen
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Habit Tracker Pro',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
<<<<<<< HEAD
        cardTheme: CardThemeData(
          elevation: 4,
=======
        scaffoldBackgroundColor: const Color(0xFFF7F9FF),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo.shade700,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          elevation: 10,
        ),
        cardTheme: CardTheme(
          elevation: 3,
>>>>>>> ac332bd445d439c07c48f34b6d3bc410dd4bf9b9
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo.shade600,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
<<<<<<< HEAD
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        cardTheme: CardThemeData(
          elevation: 4,
=======
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.indigo.shade200,
          unselectedItemColor: Colors.grey.shade500,
          showUnselectedLabels: true,
          elevation: 10,
        ),
        cardTheme: CardTheme(
          elevation: 3,
>>>>>>> ac332bd445d439c07c48f34b6d3bc410dd4bf9b9
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          color: const Color(0xFF1F1F1F),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo.shade300,
          foregroundColor: Colors.black,
          elevation: 6,
        ),
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      home: authState.when(
        data: (user) => user != null ? const MainScreen() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, st) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
      routes: {
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/add-habit': (context) => const AddEditHabitScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
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
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Habits',
    'Statistics',
    'Profile',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Handle widget tap when app is launched from widget
    HomeWidgetService.handleWidgetTap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
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
