import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/daily_habit_model.dart';
import './habits_riverpod.dart';

/// Sort options untuk search/filter.
enum SortBy {
  nameAsc,
  nameDesc,
  streakDesc,
  streakAsc,
  createdNewest,
  createdOldest,
  completedFirst,
}

// State filter
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final completionFilterProvider = StateProvider<bool?>((ref) => null);
final minStreakFilterProvider = StateProvider<int>((ref) => 0);
final sortByProvider = StateProvider<SortBy>((ref) => SortBy.nameAsc);

/// Daftar kategori dari data habits.
final allCategoriesProvider = Provider<List<String>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);
  return habitsAsync.maybeWhen(
    data: (habits) {
      final categories = habits.map((h) => h.category).where((c) => c.isNotEmpty).toSet().toList();
      categories.sort();
      return categories;
    },
    orElse: () => const [],
  );
});

/// Ringkasan filter aktif.
final filterSummaryProvider = Provider<String>((ref) {
  final q = ref.watch(searchQueryProvider);
  final cat = ref.watch(categoryFilterProvider);
  final comp = ref.watch(completionFilterProvider);
  final minStreak = ref.watch(minStreakFilterProvider);
  final sortBy = ref.watch(sortByProvider);

  final parts = <String>[];
  if (q.trim().isNotEmpty) parts.add('"$q"');
  if (cat != null && cat.isNotEmpty) parts.add('Kategori: $cat');
  if (comp != null) parts.add(comp ? 'Selesai' : 'Belum');
  if (minStreak > 0) parts.add('Streak≥$minStreak');
  parts.add('Urut: ${sortBy.name}');

  if (parts.isEmpty) return 'Filter tidak aktif';
  return parts.join(' • ');
});

/// Hasil filter utama.
final filteredHabitsProvider = Provider<List<DailyHabit>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);
  final q = ref.watch(searchQueryProvider).trim().toLowerCase();
  final cat = ref.watch(categoryFilterProvider);
  final comp = ref.watch(completionFilterProvider);
  final minStreak = ref.watch(minStreakFilterProvider);
  final sortBy = ref.watch(sortByProvider);

  final habits = habitsAsync.value ?? [];

  var list = habits.where((h) {
    final matchesQuery = q.isEmpty ||
        h.name.toLowerCase().contains(q) ||
        h.description.toLowerCase().contains(q) ||
        h.category.toLowerCase().contains(q) ||
        h.target.toLowerCase().contains(q);

    final matchesCategory = cat == null || cat.isEmpty || h.category == cat;
    final matchesCompletion = comp == null || h.isDoneToday == comp;
    final matchesStreak = minStreak <= 0 || h.streak >= minStreak;

    return matchesQuery && matchesCategory && matchesCompletion && matchesStreak;
  }).toList();

  // Sorting
  list.sort((a, b) {
    switch (sortBy) {
      case SortBy.nameAsc:
        return a.name.compareTo(b.name);
      case SortBy.nameDesc:
        return b.name.compareTo(a.name);
      case SortBy.streakDesc:
        return b.streak.compareTo(a.streak);
      case SortBy.streakAsc:
        return a.streak.compareTo(b.streak);
      case SortBy.createdNewest:
        return b.createdAt.compareTo(a.createdAt);
      case SortBy.createdOldest:
        return a.createdAt.compareTo(b.createdAt);
      case SortBy.completedFirst:
        return (b.isDoneToday ? 1 : 0).compareTo(a.isDoneToday ? 1 : 0);
    }
  });

  return list;
});

