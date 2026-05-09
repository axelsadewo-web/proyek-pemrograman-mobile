import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../db/sqlite_helper.dart';
import '../models/daily_habit_model.dart';

/// Riverpod untuk daily habits + streak/history
final dailyHabitsProvider =
    StateNotifierProvider<DailyHabitsNotifier, AsyncValue<List<DailyHabit>>>(
      (ref) => DailyHabitsNotifier(),
    );

class DailyHabitsNotifier extends StateNotifier<AsyncValue<List<DailyHabit>>> {
  DailyHabitsNotifier() : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await SqliteHelper.instance.getAllHabits();

      _resetDailyStatusIfNeeded(habits);
      _recalculateStreaks(habits);

      state = AsyncValue.data(habits);
    } catch (e, st) {
      if (kIsWeb) {
        // fallback biar web tetap jalan
        state = AsyncValue.data([
          DailyHabit(
            id: 'demo1',
            name: 'Web Demo: Berlari Pagi',
            description: '30 menit berlari setiap pagi',
            category: 'Olahraga',
            target: 'Harian',
            streak: 7,
            isDoneToday: false,
            historyDates: [],
          ),
          DailyHabit(
            id: 'demo2',
            name: 'Web Demo: Baca Buku',
            description: '20 halaman setiap hari',
            category: 'Belajar',
            target: 'Harian',
            streak: 12,
            isDoneToday: true,
            lastCompletedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            historyDates: [DateFormat('yyyy-MM-dd').format(DateTime.now())],
          ),
        ]);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> loadHabits() => _loadHabits();

  void _resetDailyStatusIfNeeded(List<DailyHabit> habits) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final habit in habits) {
      if (habit.lastCompletedDate != today && habit.isDoneToday) {
        habit.isDoneToday = false;
      }
    }
  }

  void _recalculateStreaks(List<DailyHabit> habits) {
    for (final habit in habits) {
      habit.streak = StreakService.calculateStreak(habit.historyDates);
    }
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final current = state;
    final habits = current.value ?? [];
    final idx = habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;

    final habit = habits[idx];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Tidak boleh double check dalam 1 hari
    if (habit.lastCompletedDate == today && habit.isDoneToday) {
      return;
    }

    final isCompleting = !habit.isDoneToday;

    final updatedHabit = StreakService.updateStreakForHabit(
      habit,
      isCompleting,
    );

    final finalHabit = updatedHabit.copyWith(
      isDoneToday: isCompleting,
      lastCompletedDate: isCompleting ? today : updatedHabit.lastCompletedDate,
    );

    if (!kIsWeb) {
      await SqliteHelper.instance.updateHabit(finalHabit);
    }

    final updatedHabits = [...habits];
    updatedHabits[idx] = finalHabit;
    state = AsyncValue.data(updatedHabits);
  }

  Future<void> addHabit(DailyHabit habit) async {
    try {
      if (kIsWeb) {
        // For web, just add to current state since sqflite doesn't work on web
        final current = state;
        final currentHabits = current.value ?? <DailyHabit>[];
        final habits = [...currentHabits, habit];
        state = AsyncValue.data(habits);
        debugPrint('Added habit (web mode): ${habit.name}');
      } else {
        await SqliteHelper.instance.insertHabit(habit);
        await _loadHabits();
      }
    } catch (e, st) {
      debugPrint('Error adding habit: $e');
      debugPrint('Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      if (kIsWeb) {
        // For web, just remove from current state
        final current = state;
        final currentHabits = current.value ?? <DailyHabit>[];
        final habits = currentHabits.where((h) => h.id != habitId).toList();
        state = AsyncValue.data(habits);
        debugPrint('Deleted habit (web mode): $habitId');
      } else {
        await SqliteHelper.instance.deleteHabit(habitId);
        await _loadHabits();
      }
    } catch (e, st) {
      debugPrint('Error deleting habit: $e');
      debugPrint('Stack trace: $st');
      state = AsyncValue.error(e, st);
    }
  }
}

/// Progress hari ini: completed/total
final dailyProgressProvider = Provider<Map<String, int>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.maybeWhen(
    data: (habits) => {
      'completed': habits.where((h) => h.isDoneToday).length,
      'total': habits.length,
    },
    orElse: () => {'completed': 0, 'total': 0},
  );
});
