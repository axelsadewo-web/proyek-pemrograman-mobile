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

  final List<String> _titles = [
    'Daily Habits',
    'Statistics',
    'Settings',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
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
        // Convert Habit to DailyHabit
        final dailyHabit = DailyHabit(
          id: result.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: result.name,
          description: result.description,
          category: result.category,
          target: result.target,
        );

        // Add to provider (this would need to be implemented in the provider)
        // For now, just show success message
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

// ============================================================================
// EXTENDED DAILY HABIT TRACKER SCREEN WITH STREAK
// ============================================================================

class DailyHabitTrackerScreen extends ConsumerStatefulWidget {
  const DailyHabitTrackerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyHabitTrackerScreen> createState() =>
      _DailyHabitTrackerScreenState();
}

class _DailyHabitTrackerScreenState
    extends ConsumerState<DailyHabitTrackerScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  /// Initialize demo data jika belum ada
  Future<void> _initializeDemoData() async {
    final habits =
        await HabitStorageService.getAllHabits();
    if (habits.isEmpty) {
      final demoHabits = [
        DailyHabit(
          id: '1',
          name: 'Berlari Pagi',
          description: '30 menit berlari',
          category: 'Olahraga',
          target: 'Harian',
        ),
        DailyHabit(
          id: '2',
          name: 'Baca Buku',
          description: 'Membaca minimal 20 halaman',
          category: 'Belajar',
          target: 'Harian',
        ),
        DailyHabit(
          id: '3',
          name: 'Minum Air',
          description: 'Minum 8 gelas air',
          category: 'Kesehatan',
          target: 'Harian',
        ),
        DailyHabit(
          id: '4',
          name: 'Meditasi',
          description: '10 menit meditasi pagi',
          category: 'Spiritual',
          target: 'Harian',
        ),
        DailyHabit(
          id: '5',
          name: 'Review Kode',
          description: 'Review project Flutter',
          category: 'Produktivitas',
          target: 'Harian',
        ),
      ];

      for (final habit in demoHabits) {
        await HabitStorageService.saveHabit(habit);
      }

      if (mounted) {
        ref.refresh(dailyHabitsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(dailyHabitsProvider);
    final progress = ref.watch(dailyProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Habit Tracker'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/statistics'),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) => SingleChildScrollView(
          child: Column(
            children: [
              // Progress Section
              _buildProgressSection(progress),
              const SizedBox(height: 16),

              // Streak Summary
              _buildStreakSummary(habits),
              const SizedBox(height: 16),

              // Habits List
              if (habits.isEmpty)
                _buildEmptyState()
              else
                _buildHabitsList(habits),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, st) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  /// Build progress section di atas
  Widget _buildProgressSection(Map<String, int> progress) {
    final completed = progress['completed'] ?? 0;
    final total = progress['total'] ?? 0;
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Hari Ini',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar dengan animasi
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Motivasi text
          Text(
            _getMotivationText(completed, total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build streak summary section
  Widget _buildStreakSummary(List<DailyHabit> habits) {
    final stats = StreakService.getStreakStats(habits);
    final longestStreak = stats['longestStreak'] as int;
    final activeStreaks = stats['activeStreaks'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakItem('🔥 Longest', '$longestStreak hari'),
          _buildStreakItem('⚡ Active', '$activeStreaks habit'),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  /// Get motivation text berdasarkan progress
  String _getMotivationText(int completed, int total) {
    if (total == 0) return 'Belum ada kebiasaan';
    if (completed == 0) return 'Mulai dari satu kebiasaan 💪';
    if (completed == total) return 'Sempurna! Semua kebiasaan selesai ✨';
    final remaining = total - completed;
    return 'Lanjutkan! Tinggal $remaining kebiasaan lagi 🎯';
  }

  /// Build list of habits
  Widget _buildHabitsList(List<DailyHabit> habits) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return _buildHabitItem(habits[index], index);
      },
    );
  }

  /// Build individual habit item dengan animasi dan streak
  Widget _buildHabitItem(DailyHabit habit, int index) {
    final canCheck = habit.canCheckTodayByDate();

    return GestureDetector(
      onTap: canCheck
          ? () => ref
              .read(dailyHabitsProvider.notifier)
              .toggleHabitCompletion(habit.id)
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: habit.isDoneToday ? 4 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: habit.isDoneToday
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: habit.isDoneToday
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    habit.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: habit.isDoneToday
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: habit.isDoneToday
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
                if (habit.streak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔥 ${habit.streak}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (habit.description.isNotEmpty)
                  Text(
                    habit.description,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Terakhir: ${habit.getLastCompletedDateFormatted()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (habit.getAchievementBadge().isNotEmpty)
                      Text(
                        habit.getAchievementBadge(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: _buildCheckboxAnimated(habit, canCheck),
          ),
        ),
      ),
    );
  }

  /// Build animated checkbox
  Widget _buildCheckboxAnimated(DailyHabit habit, bool canCheck) {
    return AnimatedScale(
      scale: habit.isDoneToday ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: habit.isDoneToday ? Colors.green : Colors.grey.shade200,
        ),
        child: Checkbox(
          value: habit.isDoneToday,
          onChanged: canCheck
              ? (_) => ref
                  .read(dailyHabitsProvider.notifier)
                  .toggleHabitCompletion(habit.id)
              : null,
          fillColor: MaterialStateProperty.all(
            habit.isDoneToday ? Colors.green : Colors.transparent,
          ),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada kebiasaan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat kebiasaan baru untuk memulai',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}