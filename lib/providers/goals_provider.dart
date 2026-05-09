import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit_goal_model.dart';

// Goals state notifier
class GoalsNotifier extends StateNotifier<List<HabitGoal>> {
  GoalsNotifier() : super([]);

  /// Add a new goal
  void addGoal(HabitGoal goal) {
    state = [...state, goal];
  }

  /// Update goal
  void updateGoal(HabitGoal updatedGoal) {
    state = [
      for (final goal in state)
        if (goal.id == updatedGoal.id) updatedGoal else goal,
    ];
  }

  /// Delete goal
  void deleteGoal(String goalId) {
    state = state.where((goal) => goal.id != goalId).toList();
  }

  /// Update goal progress
  void updateProgress(String goalId, int newProgress) {
    state = [
      for (final goal in state)
        if (goal.id == goalId)
          goal.copyWith(
            currentProgress: newProgress,
            isCompleted: newProgress >= goal.targetCount,
          )
        else
          goal,
    ];
  }

  /// Complete goal
  void completeGoal(String goalId) {
    state = [
      for (final goal in state)
        if (goal.id == goalId) goal.copyWith(isCompleted: true) else goal,
    ];
  }

  /// Get goals for specific habit
  List<HabitGoal> getHabitGoals(String habitId) {
    return state.where((goal) => goal.habitId == habitId).toList();
  }

  /// Get active goals
  List<HabitGoal> getActiveGoals() {
    return state.where((goal) => !goal.isCompleted).toList();
  }

  /// Get completed goals
  List<HabitGoal> getCompletedGoals() {
    return state.where((goal) => goal.isCompleted).toList();
  }

  /// Get overdue goals
  List<HabitGoal> getOverdueGoals() {
    return state.where((goal) => goal.isOverdue()).toList();
  }
}

/// Provider untuk goals
final goalsProvider = StateNotifierProvider<GoalsNotifier, List<HabitGoal>>((
  ref,
) {
  return GoalsNotifier();
});

/// Provider untuk active goals
final activeGoalsProvider = Provider<List<HabitGoal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.where((goal) => !goal.isCompleted).toList();
});

/// Provider untuk completed goals
final completedGoalsProvider = Provider<List<HabitGoal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.where((goal) => goal.isCompleted).toList();
});

/// Provider untuk overdue goals
final overdueGoalsProvider = Provider<List<HabitGoal>>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.where((goal) => goal.isOverdue()).toList();
});

/// Provider untuk goals of specific habit
final habitGoalsProvider = StateProvider.family<List<HabitGoal>, String>((
  ref,
  habitId,
) {
  final allGoals = ref.watch(goalsProvider);
  return allGoals.where((goal) => goal.habitId == habitId).toList();
});

/// Provider untuk goal progress summary
final goalProgressSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final goals = ref.watch(goalsProvider);
  final active = goals.where((g) => !g.isCompleted).toList();
  final completed = goals.where((g) => g.isCompleted).toList();
  final overdue = goals.where((g) => g.isOverdue()).toList();

  int totalProgress = 0;
  for (final goal in active) {
    totalProgress += goal.getProgressPercent().toInt();
  }

  return {
    'totalGoals': goals.length,
    'activeGoals': active.length,
    'completedGoals': completed.length,
    'overdueGoals': overdue.length,
    'averageProgress': active.isEmpty ? 0 : (totalProgress ~/ active.length),
    'completionRate': goals.isEmpty
        ? 0
        : ((completed.length / goals.length) * 100).toInt(),
  };
});
