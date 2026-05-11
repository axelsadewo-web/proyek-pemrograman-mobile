import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/daily_habit_model.dart';
import '../providers/habits_riverpod.dart';

class StreakCalendarScreen extends ConsumerStatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  ConsumerState<StreakCalendarScreen> createState() =>
      _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends ConsumerState<StreakCalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(dailyHabitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Streak'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: habitsAsync.when(
        data: (habits) {
          final stats = _buildMonthStats(habits, _visibleMonth);
          return _buildCalendar(stats);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Map<String, dynamic> _buildMonthStats(
    List<DailyHabit> habits,
    DateTime month,
  ) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;

    final dateToCompletedCount = <String, int>{};

    // initialize all dates in month so grid always shows something
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      dateToCompletedCount[_format(date)] = 0;
    }

    for (final habit in habits) {
      for (final dateStr in habit.historyDates) {
        final parsed = _tryParse(dateStr);
        if (parsed == null) continue;

        if (parsed.year == month.year && parsed.month == month.month) {
          final key = _format(parsed);
          dateToCompletedCount[key] = (dateToCompletedCount[key] ?? 0) + 1;
        }
      }
    }

    final completedCounts = dateToCompletedCount.values.toList();
    final maxCount = completedCounts.isEmpty
        ? 0
        : completedCounts.reduce((a, b) => a > b ? a : b);

    return {
      'firstDay': firstDay,
      'daysInMonth': daysInMonth,
      'dateToCompletedCount': dateToCompletedCount,
      'maxCount': maxCount,
      'totalHabits': habits.length,
    };
  }

  Widget _buildCalendar(Map<String, dynamic> stats) {
    final firstDay = stats['firstDay'] as DateTime;
    final daysInMonth = stats['daysInMonth'] as int;
    final dateToCompletedCount =
        stats['dateToCompletedCount'] as Map<String, int>;
    final maxCount = stats['maxCount'] as int;
    final totalHabits = stats['totalHabits'] as int;

    // Calendar layout: start Monday (1) ... Sunday (7)
    // DateTime.weekday: Monday=1, Sunday=7
    final leadingEmptyCells = firstDay.weekday - 1; // 0..6

    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildWeekdayHeader(),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    itemCount: rows * 7,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, idx) {
                      final dayIndex = idx - leadingEmptyCells;
                      if (dayIndex < 0 || dayIndex >= daysInMonth) {
                        return const SizedBox.shrink();
                      }

                      final date = DateTime(
                        firstDay.year,
                        firstDay.month,
                        dayIndex + 1,
                      );
                      final key = _format(date);
                      final completedCount = dateToCompletedCount[key] ?? 0;

                      final isToday = _isSameDate(date, DateTime.now());

                      return _DayCell(
                        dayLabel: date.day.toString(),
                        completedCount: completedCount,
                        maxCount: maxCount,
                        isToday: isToday,
                        totalHabits: totalHabits,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            'Legenda: warna makin terang berarti makin banyak habit selesai di hari tersebut.\n'
            '(Jumlah selesai = count history pada tanggal itu)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_visibleMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month - 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              monthLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month + 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Row(
      children: labels.map((e) {
        return Expanded(
          child: Text(
            e,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  String _format(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime? _tryParse(String s) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  final String dayLabel;
  final int completedCount;
  final int maxCount;
  final bool isToday;
  final int totalHabits;

  const _DayCell({
    required this.dayLabel,
    required this.completedCount,
    required this.maxCount,
    required this.isToday,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    final intensity = maxCount <= 0 ? 0.0 : completedCount / maxCount;

    // base: grey; overlay: indigo/purple
    final baseColor = Colors.grey.shade200;
    final heatColor = Colors.deepPurpleAccent;

    final cellColor = Color.lerp(baseColor, heatColor, intensity) ?? baseColor;

    final textColor = completedCount > 0 ? Colors.white : Colors.grey.shade700;

    return Tooltip(
      message: 'Tanggal: ${dayLabel}\nSelesai: $completedCount habit',
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: Colors.black.withOpacity(0.25), width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: completedCount > 0
              ? [
                  BoxShadow(
                    color: heatColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            completedCount > 0
                ? Text(
                    '$completedCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor.withOpacity(0.95),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
