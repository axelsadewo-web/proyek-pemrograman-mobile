import 'dart:convert';

class HabitGoal {
  final String id;
  final String habitId;
  final String title;
  final String description;
  final int targetCount;
  final String unit; // 'hari', 'kali', 'jam', etc
  final DateTime deadline;
  final int currentProgress;
  final bool isCompleted;
  final DateTime createdAt;

  HabitGoal({
    required this.id,
    required this.habitId,
    required this.title,
    required this.description,
    required this.targetCount,
    required this.unit,
    required this.deadline,
    this.currentProgress = 0,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'title': title,
      'description': description,
      'target_count': targetCount,
      'unit': unit,
      'deadline': deadline.toIso8601String(),
      'current_progress': currentProgress,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HabitGoal.fromMap(Map<String, dynamic> map) {
    return HabitGoal(
      id: map['id'] ?? '',
      habitId: map['habit_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetCount: map['target_count'] ?? 0,
      unit: map['unit'] ?? 'hari',
      deadline: DateTime.parse(
        map['deadline'] ?? DateTime.now().toIso8601String(),
      ),
      currentProgress: map['current_progress'] ?? 0,
      isCompleted: (map['is_completed'] ?? 0) == 1,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  HabitGoal copyWith({
    String? id,
    String? habitId,
    String? title,
    String? description,
    int? targetCount,
    String? unit,
    DateTime? deadline,
    int? currentProgress,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return HabitGoal(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetCount: targetCount ?? this.targetCount,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      currentProgress: currentProgress ?? this.currentProgress,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get progress percentage
  double getProgressPercent() {
    if (targetCount == 0) return 0;
    return (currentProgress / targetCount * 100).clamp(0, 100);
  }

  /// Check if goal is achieved
  bool isAchieved() => currentProgress >= targetCount;

  /// Check if goal is overdue
  bool isOverdue() => DateTime.now().isAfter(deadline) && !isCompleted;

  /// Get days remaining
  int getDaysRemaining() {
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Get remaining count
  int getRemainingCount() =>
      (targetCount - currentProgress).clamp(0, targetCount);

  /// Get progress text
  String getProgressText() {
    return '$currentProgress/$targetCount $unit';
  }
}

class GoalService {
  /// Calculate goal progress
  static double calculateProgress(HabitGoal goal) {
    if (goal.targetCount == 0) return 0;
    return (goal.currentProgress / goal.targetCount).clamp(0, 1);
  }

  /// Check if goal should be completed
  static bool shouldCompleteGoal(HabitGoal goal) {
    return goal.currentProgress >= goal.targetCount && !goal.isCompleted;
  }

  /// Get motivation text based on progress
  static String getMotivationText(HabitGoal goal) {
    final remaining = goal.getRemainingCount();
    final daysLeft = goal.getDaysRemaining();

    if (goal.isAchieved()) {
      return '🎉 Congratulations! Goal achieved!';
    }

    if (daysLeft < 0) {
      return '⏰ Deadline passed! Try again next time.';
    }

    if (remaining == 0) {
      return '🎯 Almost there! Final push!';
    }

    if (daysLeft <= 1) {
      return '⚡ Last day! You can do it!';
    }

    if (daysLeft <= 3) {
      return '💪 Keep going! Just $daysLeft days left!';
    }

    if (remaining <= 2) {
      return '🌟 Just $remaining ${goal.unit} left!';
    }

    return '📈 You\'re doing great! Keep it up!';
  }

  /// Get goal status color
  static String getStatusEmoji(HabitGoal goal) {
    if (goal.isCompleted) return '✅';
    if (goal.isOverdue()) return '❌';
    if (goal.isAchieved()) return '🎯';
    return '⏳';
  }

  /// Create weekly goal
  static HabitGoal createWeeklyGoal({
    required String habitId,
    required String title,
    int targetDays = 7,
  }) {
    return HabitGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: habitId,
      title: title,
      description: 'Complete the habit for $targetDays days this week',
      targetCount: targetDays,
      unit: 'hari',
      deadline: DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
    );
  }

  /// Create monthly goal
  static HabitGoal createMonthlyGoal({
    required String habitId,
    required String title,
    int targetDays = 30,
  }) {
    return HabitGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      habitId: habitId,
      title: title,
      description: 'Complete the habit for $targetDays days this month',
      targetCount: targetDays,
      unit: 'hari',
      deadline: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
    );
  }
}
