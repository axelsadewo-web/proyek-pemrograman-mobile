import 'package:flutter/material.dart';
import '../models/habbits.dart';
import '../db/db_helper.dart';
import '../services/api_services.dart';
import 'package:intl/intl.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];

  String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future loadLocalHabits() async {
    habits = await DBHelper.instance.getHabits();
    notifyListeners();
  }

  Future addHabit(String title) async {
    final habit = Habit(title: title, date: today());
    await DBHelper.instance.insertHabit(habit);
    await loadLocalHabits();
  }

  Future toggleHabit(Habit habit) async {
    habit.isDone = habit.isDone == 0 ? 1 : 0;
    await DBHelper.instance.updateHabit(habit);
    await loadLocalHabits();
  }

  Future deleteHabit(int id) async {
    await DBHelper.instance.deleteHabit(id);
    await loadLocalHabits();
  }

  // 🔥 Ambil dari API lalu simpan ke lokal
  Future fetchFromApi() async {
    final data = await ApiService.fetchHabits();

    for (var item in data) {
      final habit = Habit(
        title: item['title'],
        date: today(),
        isDone: item['completed'] ? 1 : 0,
      );
      await DBHelper.instance.insertHabit(habit);
    }

    await loadLocalHabits();
  }

  int get streak {
    int count = 0;
    for (var h in habits) {
      if (h.isDone == 1) {
        count++;
      }
    }
    return count;
  }
}
