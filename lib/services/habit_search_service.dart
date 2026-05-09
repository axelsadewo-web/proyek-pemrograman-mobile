import '../models/daily_habit_model.dart';
import '../providers/search_provider.dart';

class HabitSearchService {
  /// Filter habits berdasarkan search query
  static List<DailyHabit> searchHabits(List<DailyHabit> habits, String query) {
    if (query.isEmpty) return habits;

    query = query.toLowerCase();
    return habits
        .where(
          (habit) =>
              habit.name.toLowerCase().contains(query) ||
              habit.description.toLowerCase().contains(query) ||
              habit.category.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Filter habits berdasarkan kategori
  static List<DailyHabit> filterByCategory(
    List<DailyHabit> habits,
    String? category,
  ) {
    if (category == null || category.isEmpty) return habits;
    return habits.where((habit) => habit.category == category).toList();
  }

  /// Filter habits berdasarkan status completion
  static List<DailyHabit> filterByCompletionStatus(
    List<DailyHabit> habits,
    bool? isDone,
  ) {
    if (isDone == null) return habits;
    return habits.where((habit) => habit.isDoneToday == isDone).toList();
  }

  /// Filter habits berdasarkan streak minimum
  static List<DailyHabit> filterByMinStreak(
    List<DailyHabit> habits,
    int minStreak,
  ) {
    if (minStreak <= 0) return habits;
    return habits.where((habit) => habit.streak >= minStreak).toList();
  }

  /// Sort habits
  static List<DailyHabit> sortHabits(List<DailyHabit> habits, SortBy sortBy) {
    final sorted = List<DailyHabit>.from(habits);
    switch (sortBy) {
      case SortBy.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case SortBy.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
      case SortBy.streakDesc:
        sorted.sort((a, b) => b.streak.compareTo(a.streak));
      case SortBy.streakAsc:
        sorted.sort((a, b) => a.streak.compareTo(b.streak));
      case SortBy.createdNewest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortBy.createdOldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortBy.completedFirst:
        sorted.sort((a, b) {
          if (a.isDoneToday == b.isDoneToday) return 0;
          return a.isDoneToday ? -1 : 1;
        });
    }
    return sorted;
  }

  /// Combine search, filter, dan sort
  static List<DailyHabit> applyAllFilters(
    List<DailyHabit> habits, {
    String searchQuery = '',
    String? category,
    bool? isDone,
    int minStreak = 0,
    SortBy sortBy = SortBy.nameAsc,
  }) {
    var result = habits;

    // Apply search
    result = searchHabits(result, searchQuery);

    // Apply category filter
    result = filterByCategory(result, category);

    // Apply completion status filter
    result = filterByCompletionStatus(result, isDone);

    // Apply streak filter
    result = filterByMinStreak(result, minStreak);

    // Apply sorting
    result = sortHabits(result, sortBy);

    return result;
  }
}
