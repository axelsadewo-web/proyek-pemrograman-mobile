import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

// ============================================================================
// UPDATED MODEL HABIT WITH STREAK & HISTORY
// ============================================================================

/// Model Habit dengan tracking harian, streak, dan history
class DailyHabit {
  String id;
  String name;
  String description;
  String category;
  String target; // 'Harian' atau 'Mingguan'
  bool isDoneToday;
  String? lastCompletedDate; // Format: yyyy-MM-dd
  int streak; // Jumlah hari berturut-turut
  List<String> historyDates; // List tanggal penyelesaian (yyyy-MM-dd)
  DateTime createdAt;

  DailyHabit({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.target,
    this.isDoneToday = false,
    this.lastCompletedDate,
    this.streak = 0,
    List<String>? historyDates,
    DateTime? createdAt,
  }) :
    historyDates = historyDates ?? [],
    createdAt = createdAt ?? DateTime.now();

  /// Konversi ke Map untuk Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'target': target,
      'isDoneToday': isDoneToday,
      'lastCompletedDate': lastCompletedDate,
      'streak': streak,
      'historyDates': historyDates,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create dari Map (Hive)
  factory DailyHabit.fromMap(Map<String, dynamic> map) {
    return DailyHabit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Olahraga',
      target: map['target'] ?? 'Harian',
      isDoneToday: map['isDoneToday'] ?? false,
      lastCompletedDate: map['lastCompletedDate'],
      streak: map['streak'] ?? 0,
      historyDates: List<String>.from(map['historyDates'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Copy with
  DailyHabit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? target,
    bool? isDoneToday,
    String? lastCompletedDate,
    int? streak,
    List<String>? historyDates,
    DateTime? createdAt,
  }) {
    return DailyHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      target: target ?? this.target,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      streak: streak ?? this.streak,
      historyDates: historyDates ?? this.historyDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Cek apakah bisa dicentang hari ini (belum dilakukan hari ini)
  bool canCheckTodayByDate() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastCompletedDate != today;
  }

  /// Get tanggal terakhir dalam format readable
  String getLastCompletedDateFormatted() {
    if (lastCompletedDate == null) {
      return 'Belum pernah dilakukan';
    }
    try {
      final date = DateFormat('yyyy-MM-dd').parse(lastCompletedDate!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (lastCompletedDate == today) {
        return 'Hari ini';
      }
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return lastCompletedDate ?? 'Tidak diketahui';
    }
  }

  /// Get streak badge text
  String getStreakBadge() {
    if (streak == 0) return '';
    if (streak >= 30) return '🔥 $streak hari (Master!)';
    if (streak >= 7) return '🔥 $streak hari (Weekly!)';
    return '🔥 $streak hari';
  }

  /// Get achievement badge berdasarkan streak
  String getAchievementBadge() {
    if (streak >= 100) return '🏆 Century Champion';
    if (streak >= 50) return '⭐ Golden Streak';
    if (streak >= 30) return '🎯 Monthly Master';
    if (streak >= 7) return '⚡ Weekly Warrior';
    if (streak >= 3) return '🌟 Getting Started';
    return '';
  }
}

// ============================================================================
// STREAK CALCULATION SERVICE
// ============================================================================

/// Service untuk menghitung dan manage streak
class StreakService {
  /// Calculate streak berdasarkan history dates
  static int calculateStreak(List<String> historyDates) {
    if (historyDates.isEmpty) return 0;

    // Sort dates descending (terbaru dulu)
    final sortedDates = List<String>.from(historyDates)
      ..sort((a, b) => b.compareTo(a));

    // Remove duplicates dan sort ascending
    final uniqueDates = sortedDates.toSet().toList()..sort();

    if (uniqueDates.isEmpty) return 0;

    int currentStreak = 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Cek apakah hari ini atau kemarin ada di history
    final hasToday = uniqueDates.contains(today);
    final hasYesterday = uniqueDates.contains(yesterday);

    if (!hasToday && !hasYesterday) {
      // Tidak ada activity hari ini atau kemarin, streak berhenti
      return 0;
    }

    // Hitung streak dari tanggal terakhir
    DateTime currentDate = hasToday
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      if (!uniqueDates.contains(dateStr)) {
        break;
      }
      currentStreak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return currentStreak;
  }

  /// Update streak untuk habit tertentu
  static DailyHabit updateStreakForHabit(DailyHabit habit, bool isCompleting) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<String> updatedHistory = List.from(habit.historyDates);

    if (isCompleting) {
      // Tambah ke history jika belum ada
      if (!updatedHistory.contains(today)) {
        updatedHistory.add(today);
      }
    } else {
      // Remove dari history jika uncheck
      updatedHistory.remove(today);
    }

    // Calculate new streak
    final newStreak = calculateStreak(updatedHistory);

    return habit.copyWith(
      streak: newStreak,
      historyDates: updatedHistory,
    );
  }

  /// Get streak statistics untuk semua habits
  static Map<String, dynamic> getStreakStats(List<DailyHabit> habits) {
    if (habits.isEmpty) {
      return {
        'totalStreaks': 0,
        'averageStreak': 0.0,
        'longestStreak': 0,
        'activeStreaks': 0,
      };
    }

    final streaks = habits.map((h) => h.streak).toList();
    final activeStreaks = habits.where((h) => h.streak > 0).length;

    return {
      'totalStreaks': streaks.reduce((a, b) => a + b),
      'averageStreak': streaks.reduce((a, b) => a + b) / habits.length,
      'longestStreak': streaks.isEmpty ? 0 : streaks.reduce((a, b) => a > b ? a : b),
      'activeStreaks': activeStreaks,
    };
  }
}

// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================

class NotificationService {
  static const String channelId = 'habit_reminder_channel';
  static const String channelName = 'Habit Reminders';
  static const String channelDescription = 'Daily habit completion reminders';

  // static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  // /// Initialize notifications
  // static Future<void> initialize() async {
  //   _notificationsPlugin = FlutterLocalNotificationsPlugin();

  //   // Android initialization
  //   const AndroidInitializationSettings androidSettings =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');

  //   // iOS initialization
  //   const DarwinInitializationSettings iosSettings =
  //       DarwinInitializationSettings();

  //   const InitializationSettings settings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );

  //   await _notificationsPlugin?.initialize(settings);
  // }

  // /// Request permissions
  // static Future<bool> requestPermissions() async {
  //   final androidPlugin = _notificationsPlugin?.resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>();

  //   final iosPlugin = _notificationsPlugin?.resolvePlatformSpecificImplementation<
  //       IOSFlutterLocalNotificationsPlugin>();

  //   final androidGranted = await androidPlugin?.requestNotificationsPermission() ?? false;
  //   final iosGranted = await iosPlugin?.requestPermissions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   ) ?? false;

  //   return androidGranted || iosGranted;
  // }

  // /// Schedule daily reminder
  // static Future<void> scheduleDailyReminder({
  //   required TimeOfDay time,
  //   required String title,
  //   required String body,
  // }) async {
  //   if (_notificationsPlugin == null) return;

  //   final now = DateTime.now();
  //   final scheduledTime = DateTime(
  //     now.year,
  //     now.month,
  //     now.day,
  //     time.hour,
  //     time.minute,
  //   );

  //   // Jika waktu sudah lewat hari ini, schedule untuk besok
  //   final reminderTime = scheduledTime.isBefore(now)
  //       ? scheduledTime.add(const Duration(days: 1))
  //       : scheduledTime;

  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     channelId,
  //     channelName,
  //     channelDescription: channelDescription,
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     sound: AndroidNotificationSound.defaultSound,
  //     enableVibration: true,
  //   );

  //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  //     sound: 'default.wav',
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   const NotificationDetails details = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );

  //   await _notificationsPlugin?.zonedSchedule(
  //     0, // notification id
  //     title,
  //     body,
  //     tz.TZDateTime.from(reminderTime, tz.local),
  //     details,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //     matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
  //   );
  // }

  // /// Cancel all notifications
  // static Future<void> cancelAllNotifications() async {
  //   await _notificationsPlugin?.cancelAll();
  // }

  // /// Cancel specific notification
  // static Future<void> cancelNotification(int id) async {
  //   await _notificationsPlugin?.cancel(id);
  // }

  // /// Get pending notifications
  // static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
  //   return await _notificationsPlugin?.pendingNotificationRequests() ?? [];
  // }

  // /// Show test notification
  // static Future<void> showTestNotification() async {
  //   if (_notificationsPlugin == null) return;

  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     channelId,
  //     channelName,
  //     channelDescription: channelDescription,
  //   );

  //   const NotificationDetails details = NotificationDetails(
  //     android: androidDetails,
  //     iOS: const DarwinNotificationDetails(),
  //   );

  //   await _notificationsPlugin?.show(
  //     999,
  //     'Test Reminder',
  //     'Ini adalah notifikasi test untuk habit tracker!',
  //     details,
  //   );
  // }
}

// ============================================================================
// STATISTICS SERVICE
// ============================================================================

/// Service untuk menghitung statistik dan progress
class StatisticsService {
  /// Get weekly statistics
  static Map<String, dynamic> getWeeklyStats(List<DailyHabit> habits) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

    final weekDates = <String>[];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      weekDates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    final dailyCompleted = <String, int>{};
    int totalCompletedThisWeek = 0;
    int totalPossibleThisWeek = 0;

    for (final date in weekDates) {
      int completedCount = 0;
      for (final habit in habits) {
        if (habit.historyDates.contains(date)) {
          completedCount++;
          totalCompletedThisWeek++;
        }
      }
      dailyCompleted[date] = completedCount;
      totalPossibleThisWeek += habits.length;
    }

    final completionRate = totalPossibleThisWeek > 0
        ? (totalCompletedThisWeek / totalPossibleThisWeek * 100)
        : 0.0;

    return {
      'dailyCompleted': dailyCompleted,
      'totalCompleted': totalCompletedThisWeek,
      'totalPossible': totalPossibleThisWeek,
      'completionRate': completionRate,
      'weekDates': weekDates,
    };
  }

  /// Get monthly statistics
  static Map<String, dynamic> getMonthlyStats(List<DailyHabit> habits) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final monthDates = <String>[];
    for (int i = 0; i < endOfMonth.day; i++) {
      final date = startOfMonth.add(Duration(days: i));
      monthDates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    final dailyCompleted = <String, int>{};
    int totalCompletedThisMonth = 0;
    int totalPossibleThisMonth = 0;

    for (final date in monthDates) {
      int completedCount = 0;
      for (final habit in habits) {
        if (habit.historyDates.contains(date)) {
          completedCount++;
          totalCompletedThisMonth++;
        }
      }
      dailyCompleted[date] = completedCount;
      totalPossibleThisMonth += habits.length;
    }

    final completionRate = totalPossibleThisMonth > 0
        ? (totalCompletedThisMonth / totalPossibleThisMonth * 100)
        : 0.0;

    return {
      'dailyCompleted': dailyCompleted,
      'totalCompleted': totalCompletedThisMonth,
      'totalPossible': totalPossibleThisMonth,
      'completionRate': completionRate,
      'monthDates': monthDates,
    };
  }

  /// Get overall statistics
  static Map<String, dynamic> getOverallStats(List<DailyHabit> habits) {
    final streakStats = StreakService.getStreakStats(habits);

    final totalHabits = habits.length;
    final activeHabits = habits.where((h) => h.streak > 0).length;
    final completedToday = habits.where((h) => h.isDoneToday).length;

    final allHistoryDates = habits
        .expand((habit) => habit.historyDates)
        .toSet()
        .toList()
      ..sort();

    final totalCompletions = allHistoryDates.length;

    return {
      'totalHabits': totalHabits,
      'activeHabits': activeHabits,
      'completedToday': completedToday,
      'totalCompletions': totalCompletions,
      'completionRateToday': totalHabits > 0 ? (completedToday / totalHabits * 100) : 0.0,
      ...streakStats,
    };
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider untuk daily habits list dengan streak support
final dailyHabitsProvider =
    StateNotifierProvider<DailyHabitsNotifier, AsyncValue<List<DailyHabit>>>(
  (ref) => DailyHabitsNotifier(),
);

/// StateNotifier untuk manage daily habits dengan streak
class DailyHabitsNotifier extends StateNotifier<AsyncValue<List<DailyHabit>>> {
  DailyHabitsNotifier() : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  /// Load habits dari Hive
  Future<void> _loadHabits() async {
    try {
      final habits = await HabitStorageService.getAllHabits();
      // Reset isDoneToday jika bukan hari yang sama
      _resetDailyStatusIfNeeded(habits);
      // Recalculate streaks
      _recalculateStreaks(habits);
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset isDoneToday jika tanggal berbeda
  void _resetDailyStatusIfNeeded(List<DailyHabit> habits) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final habit in habits) {
      if (habit.lastCompletedDate != today && habit.isDoneToday) {
        habit.isDoneToday = false;
      }
    }
  }

  /// Recalculate streaks untuk semua habits
  void _recalculateStreaks(List<DailyHabit> habits) {
    for (final habit in habits) {
      habit.streak = StreakService.calculateStreak(habit.historyDates);
    }
  }

  /// Toggle habit completion status dengan streak update
  Future<void> toggleHabitCompletion(String habitId) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    final habitIndex = habits.indexWhere((h) => h.id == habitId);

    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Cek validasi: tidak boleh double checklist dalam 1 hari
      if (habit.lastCompletedDate == today && habit.isDoneToday) {
        // Sudah dilakukan hari ini, tidak bisa dicentang lagi
        return;
      }

      // Toggle status
      final isCompleting = !habit.isDoneToday;

      // Update habit dengan streak calculation
      final updatedHabit = StreakService.updateStreakForHabit(habit, isCompleting);
      final finalHabit = updatedHabit.copyWith(
        isDoneToday: isCompleting,
        lastCompletedDate: isCompleting ? today : updatedHabit.lastCompletedDate,
      );

      // Update list
      final updatedHabits = [...habits];
      updatedHabits[habitIndex] = finalHabit;

      // Save ke Hive
      await HabitStorageService.saveHabit(finalHabit);

      // Update state
      state = AsyncValue.data(updatedHabits);
    }
  }

  /// Add habit baru
  Future<void> addHabit(DailyHabit habit) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    habits.add(habit);

    await HabitStorageService.saveHabit(habit);
    state = AsyncValue.data(habits);
  }

  /// Delete habit
  Future<void> deleteHabit(String habitId) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    habits.removeWhere((h) => h.id == habitId);

    await HabitStorageService.deleteHabit(habitId);
    state = AsyncValue.data(habits);
  }
}

/// Provider untuk hitung progress hari ini
final dailyProgressProvider = Provider<Map<String, int>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.when(
    data: (habits) {
      final completed = habits.where((h) => h.isDoneToday).length;
      final total = habits.length;
      return {'completed': completed, 'total': total};
    },
    loading: () => {'completed': 0, 'total': 0},
    error: (_, __) => {'completed': 0, 'total': 0},
  );
});

/// Provider untuk statistics
final statisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.when(
    data: (habits) => StatisticsService.getOverallStats(habits),
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider untuk weekly stats
final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.when(
    data: (habits) => StatisticsService.getWeeklyStats(habits),
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Provider untuk monthly stats
final monthlyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.when(
    data: (habits) => StatisticsService.getMonthlyStats(habits),
    loading: () => {},
    error: (_, __) => {},
  );
});

// ============================================================================
// HIVE BOX INITIALIZATION & PROVIDER
// ============================================================================

/// Hive adapter untuk Hive persisten storage
class HabitStorageService {
  static const String boxName = 'daily_habits';

  /// Initialize Hive box
  static Future<Box<Map>> initializeBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<Map>(boxName);
    }
    return Hive.box<Map>(boxName);
  }

  /// Get all habits dari Hive
  static Future<List<DailyHabit>> getAllHabits() async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    return box.values
        .map((e) => DailyHabit.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Save habit ke Hive
  static Future<void> saveHabit(DailyHabit habit) async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.put(habit.id, habit.toMap());
  }

  /// Delete habit dari Hive
  static Future<void> deleteHabit(String habitId) async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.delete(habitId);
  }

  /// Clear all habits
  static Future<void> clearAllHabits() async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.clear();
  }
}
