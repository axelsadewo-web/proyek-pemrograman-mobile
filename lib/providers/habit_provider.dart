import 'package:flutter/foundation.dart';
// NOTE: ChangeNotifier provider ini tidak dipakai UI saat ini.
// Disimpan agar tidak mengganggu build bila ada referensi lama.

import '../models/daily_habit_model.dart';
import '../db/sqlite_helper.dart';
import 'package:intl/intl.dart';

class HabitProvider extends ChangeNotifier {
  List<DailyHabit> habits = [];

  String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> loadLocalHabits() async {
    try {
      habits = await SqliteHelper.instance.getAllHabits();
    } catch (e) {
      if (kIsWeb) {
        habits = [
          DailyHabit(
            id: 'web1',
            name: 'Web Mock Habit',
            category: 'Demo',
            target: 'Harian',
          ),
        ];
        print('Loaded web mock habits: $e');
      } else {
        rethrow;
      }
    }
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    String description = '',
    required String category,
    required String target,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final habit = DailyHabit(
      id: id,
      name: name,
      description: description,
      category: category,
      target: target,
    );
    await SqliteHelper.instance.insertHabit(habit);
    await loadLocalHabits();
  }

  Future<void> toggleHabit(DailyHabit habit) async {
    final isCompleting = !habit.isDoneToday;
    final updatedHabit = StreakService.updateStreakForHabit(
      habit,
      isCompleting,
    );
    final finalHabit = updatedHabit.copyWith(
      isDoneToday: isCompleting,
      lastCompletedDate: isCompleting ? today() : null,
    );
    await SqliteHelper.instance.updateHabit(finalHabit);
    await loadLocalHabits();
  }

  Future<void> deleteHabit(String id) async {
    await SqliteHelper.instance.deleteHabit(id);
    await loadLocalHabits();
  }

  // 🔥 Ambil dari API lalu simpan ke lokal
  Future<void> fetchFromApi() async {
    await loadLocalHabits();
  }

  int get streak {
    return habits.where((h) => h.isDoneToday).length;
  }

  int get totalHabits => habits.length;
  double get completionRate => totalHabits > 0 ? streak / totalHabits : 0;
}
