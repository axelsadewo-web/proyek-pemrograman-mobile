import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/daily_habit_model.dart';
import '../db/sqlite_helper.dart';

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<DailyHabit>>>(
      (ref) => HabitsNotifier(),
    );

class HabitsNotifier extends StateNotifier<AsyncValue<List<DailyHabit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await SqliteHelper.instance.getAllHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      // Fallback to mock data on web/SQLite error
      if (kIsWeb) {
        final mockHabits = [
          DailyHabit(
            id: 'mock1',
            name: 'Demo Habit 1 (Web)',
            description: 'This is mock for web testing',
            category: 'Demo',
            target: 'Harian',
            isDoneToday: false,
            streak: 3,
          ),
          DailyHabit(
            id: 'mock2',
            name: 'Demo Habit 2 (Web)',
            description: 'SQLite works on Android/iOS',
            category: 'Demo',
            target: 'Harian',
            isDoneToday: true,
            streak: 5,
          ),
        ];
        state = AsyncValue.data(mockHabits);
        print('Web mock data loaded: SQLite error $e');
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addHabit(DailyHabit habit) async {
    await SqliteHelper.instance.insertHabit(habit);
    loadHabits();
  }

  Future<void> toggleHabit(String id) async {
    state = state.whenData((habits) {
      final index = habits.indexWhere((h) => h.id == id);
      if (index != -1) {
        final habit = habits[index];
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final isCompleting = !habit.isDoneToday;
        final updatedHabit = StreakService.updateStreakForHabit(
          habit,
          isCompleting,
        );
        final finalHabit = updatedHabit.copyWith(
          isDoneToday: isCompleting,
          lastCompletedDate: isCompleting ? today : null,
        );
        SqliteHelper.instance.updateHabit(finalHabit);
      }
      return habits;
    });
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await SqliteHelper.instance.deleteHabit(id);
    loadHabits();
  }
}

final progressProvider = Provider<Map<String, int>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  return habitsAsync.when(
    data: (habits) {
      final completed = habits.where((h) => h.isDoneToday).length;
      return {'completed': completed, 'total': habits.length};
    },
    loading: () => {'completed': 0, 'total': 0},
    error: (_, __) => {'completed': 0, 'total': 0},
  );
});

final statisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  return habitsAsync.when(
    data: (habits) => StreakService.getStreakStats(habits),
    loading: () => {},
    error: (_, __) => {},
  );
});
