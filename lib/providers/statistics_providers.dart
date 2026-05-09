import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder provider agar [StatisticsScreen] bisa compile dulu.
/// Nanti bisa dihubungkan ke SQLite/API untuk data real.
final statisticsProvider = Provider<Map<String, dynamic>>((ref) {
  return const {
    'totalHabits': 0,
    'completedToday': 0,
  };
});

final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return const {
    'dailyCompleted': <String, int>{},
    'totalCompleted': 0,
    'totalPossible': 0,
    'completionRate': 0.0,
    'weekDates': <String>[],
  };
});

final monthlyStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return const {
    'dailyCompleted': <String, int>{},
    'totalCompleted': 0,
    'totalPossible': 0,
    'completionRate': 0.0,
    'monthDates': <String>[],
  };
});
