import 'dart:convert';
import 'package:intl/intl.dart';

class Habit {
  String id;
  String name;
  String description;
  String category;
  String target;
  bool isDoneToday;
  String? lastCompletedDate;
  int streak;
  List<String> historyDates;
  DateTime createdAt;

  Habit({
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
  }) : historyDates = historyDates ?? [],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'target': target,
      'is_done_today': isDoneToday ? 1 : 0,
      'last_completed_date': lastCompletedDate,
      'streak': streak,
      'history_dates': jsonEncode(historyDates),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      target: map['target'] ?? 'Daily',
      isDoneToday: (map['is_done_today'] ?? 0) == 1,
      lastCompletedDate: map['last_completed_date'],
      streak: map['streak'] ?? 0,
      historyDates: List<String>.from(jsonDecode(map['history_dates'] ?? '[]')),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Habit copyWith({
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
    return Habit(
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

  bool canCheckTodayByDate() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastCompletedDate != today;
  }

  String getLastCompletedDateFormatted() {
    if (lastCompletedDate == null) return 'Never';
    try {
      final date = DateFormat('yyyy-MM-dd').parse(lastCompletedDate!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (lastCompletedDate == today) return 'Today';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return lastCompletedDate ?? 'Unknown';
    }
  }

  String getStreakBadge() {
    if (streak == 0) return '';
    return '🔥 $streak days';
  }

  String getAchievementBadge() {
    if (streak >= 30) return '🏆 Master';
    if (streak >= 7) return '⭐ Weekly';
    if (streak >= 3) return '🌟 Starter';
    return '';
  }
}

class StreakService {
  static int calculateStreak(List<String> historyDates) {
    if (historyDates.isEmpty) return 0;
    final sortedDates = List<String>.from(historyDates)..sort();
    final uniqueDates = sortedDates.toSet().toList()..sort();
    if (uniqueDates.isEmpty) return 0;

    int currentStreak = 0;
    DateTime currentDate = DateTime.now();

    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      if (!uniqueDates.contains(dateStr)) break;
      currentStreak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    return currentStreak;
  }

  static Habit updateStreakForHabit(Habit habit, bool isCompleting) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<String> updatedHistory = List.from(habit.historyDates);

    if (isCompleting && !updatedHistory.contains(today)) {
      updatedHistory.add(today);
    } else if (!isCompleting) {
      updatedHistory.remove(today);
    }

    final newStreak = calculateStreak(updatedHistory);
    return habit.copyWith(streak: newStreak, historyDates: updatedHistory);
  }

  static Map<String, dynamic> getStreakStats(List<Habit> habits) {
    if (habits.isEmpty) return {};
    final streaks = habits.map((h) => h.streak).toList();
    return {
      'totalStreaks': streaks.reduce((a, b) => a + b),
      'averageStreak': streaks.reduce((a, b) => a + b) / habits.length,
      'longestStreak': streaks.reduce((a, b) => a > b ? a : b),
    };
  }
}
