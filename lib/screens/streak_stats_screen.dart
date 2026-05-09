import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_habit_model.dart';
import '../providers/habits_riverpod.dart';

class StreakStatsScreen extends ConsumerWidget {
  const StreakStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(dailyHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Streak'),
        elevation: 0,
        backgroundColor: Colors.orangeAccent,
      ),
      body: habitsAsync.when(
        data: (habits) => _buildStatsView(habits),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatsView(List<DailyHabit> habits) {
    if (habits.isEmpty) {
      return const Center(
        child: Text('Belum ada kebiasaan untuk ditampilkan statistiknya'),
      );
    }

    // Calculate stats
    final totalHabits = habits.length;
    final activeStreaks = habits.where((h) => h.streak > 0).length;
    final maxStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
    final avgStreak = habits.isEmpty
        ? 0
        : (habits.map((h) => h.streak).reduce((a, b) => a + b) / habits.length)
              .round();

    // Group by streak ranges
    final streakRanges = {
      '🔥 Master (30+ hari)': habits.where((h) => h.streak >= 30).length,
      '⚡ Weekly (7-29 hari)': habits
          .where((h) => h.streak >= 7 && h.streak < 30)
          .length,
      '✨ Building (3-6 hari)': habits
          .where((h) => h.streak >= 3 && h.streak < 7)
          .length,
      '⭐ Starting (1-2 hari)': habits
          .where((h) => h.streak >= 1 && h.streak < 3)
          .length,
      '😴 No streak': habits.where((h) => h.streak == 0).length,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Kebiasaan',
                  totalHabits.toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Aktif Streak',
                  activeStreaks.toString(),
                  Icons.whatshot,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Streak Max',
                  maxStreak.toString(),
                  Icons.emoji_events,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rata-rata',
                  avgStreak.toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text(
            'Distribusi Streak',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Streak Distribution
          ...streakRanges.entries.map((entry) {
            final percentage = totalHabits > 0
                ? (entry.value / totalHabits * 100).round()
                : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 14)),
                      Text(
                        '${entry.value} (${percentage}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalHabits > 0 ? entry.value / totalHabits : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStreakColor(entry.key),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 32),
          const Text(
            'Top Streak Habits',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Top Streak Habits
          ..._buildTopHabits(habits),
        ],
      ),
    );
  }

  List<Widget> _buildTopHabits(List<DailyHabit> habits) {
    final topHabits = habits.where((h) => h.streak > 0).toList()
      ..sort((a, b) => b.streak.compareTo(a.streak));

    return topHabits
        .take(5)
        .map(
          (habit) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Text(
                _getStreakEmoji(habit.streak),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(habit.name),
              subtitle: Text(habit.category),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStreakBadgeColor(habit.streak),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${habit.streak} hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStreakColor(String range) {
    if (range.contains('Master')) return Colors.red;
    if (range.contains('Weekly')) return Colors.orange;
    if (range.contains('Building')) return Colors.amber;
    if (range.contains('Starting')) return Colors.purple;
    return Colors.grey;
  }

  String _getStreakEmoji(int streak) {
    if (streak >= 30) return '🔥';
    if (streak >= 7) return '⚡';
    if (streak >= 3) return '✨';
    return '⭐';
  }

  Color _getStreakBadgeColor(int streak) {
    if (streak >= 30) return Colors.red;
    if (streak >= 7) return Colors.orange;
    if (streak >= 3) return Colors.amber;
    return Colors.purple;
  }
}
