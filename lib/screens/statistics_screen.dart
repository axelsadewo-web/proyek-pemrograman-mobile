import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_habit_model.dart';

// ============================================================================
// STATISTICS SCREEN
// ============================================================================

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik & Progress'),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mingguan'),
            Tab(text: 'Bulanan'),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeeklyTab(), _buildMonthlyTab()],
      ),
    );
  }

  /// Build weekly statistics tab
  Widget _buildWeeklyTab() {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final overallStats = ref.watch(statisticsProvider);

    if (weeklyStats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyCompleted = weeklyStats['dailyCompleted'] as Map<String, int>;
    final totalCompleted = weeklyStats['totalCompleted'] as int;
    final totalPossible = weeklyStats['totalPossible'] as int;
    final completionRate = weeklyStats['completionRate'] as double;
    final weekDates = weeklyStats['weekDates'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats Cards
          _buildOverallStatsCards(overallStats),

          const SizedBox(height: 24),

          // Weekly Summary
          _buildWeeklySummary(totalCompleted, totalPossible, completionRate),

          const SizedBox(height: 24),

          // Weekly Chart
          _buildWeeklyChart(dailyCompleted, weekDates),

          const SizedBox(height: 24),

          // Achievement Badges
          _buildAchievementSection(),
        ],
      ),
    );
  }

  /// Build monthly statistics tab
  Widget _buildMonthlyTab() {
    final monthlyStats = ref.watch(monthlyStatsProvider);
    final overallStats = ref.watch(statisticsProvider);

    if (monthlyStats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final dailyCompleted = monthlyStats['dailyCompleted'] as Map<String, int>;
    final totalCompleted = monthlyStats['totalCompleted'] as int;
    final totalPossible = monthlyStats['totalPossible'] as int;
    final completionRate = monthlyStats['completionRate'] as double;
    final monthDates = monthlyStats['monthDates'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats Cards
          _buildOverallStatsCards(overallStats),

          const SizedBox(height: 24),

          // Monthly Summary
          _buildMonthlySummary(totalCompleted, totalPossible, completionRate),

          const SizedBox(height: 24),

          // Monthly Chart
          _buildMonthlyChart(dailyCompleted, monthDates),

          const SizedBox(height: 24),

          // Achievement Badges
          _buildAchievementSection(),
        ],
      ),
    );
  }

  /// Build overall statistics cards
  Widget _buildOverallStatsCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Habit',
            '${stats['totalHabits'] ?? 0}',
            Icons.list_alt,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Aktif Hari Ini',
            '${stats['completedToday'] ?? 0}/${stats['totalHabits'] ?? 0}',
            Icons.today,
            Colors.green,
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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

  /// Build weekly summary
  Widget _buildWeeklySummary(int completed, int possible, double rate) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Mingguan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Total Selesai', '$completed'),
                _buildSummaryItem('Total Kemungkinan', '$possible'),
                _buildSummaryItem('Persentase', '${rate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 80
                    ? Colors.green
                    : rate >= 60
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build monthly summary
  Widget _buildMonthlySummary(int completed, int possible, double rate) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Bulanan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Total Selesai', '$completed'),
                _buildSummaryItem('Total Kemungkinan', '$possible'),
                _buildSummaryItem('Persentase', '${rate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 80
                    ? Colors.green
                    : rate >= 60
                    ? Colors.orange
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary item
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Build weekly chart
  Widget _buildWeeklyChart(
    Map<String, int> dailyCompleted,
    List<String> weekDates,
  ) {
    final spots = <FlSpot>[];
    final dayLabels = <String>[];

    for (int i = 0; i < weekDates.length; i++) {
      final date = weekDates[i];
      final completed = dailyCompleted[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), completed.toDouble()));

      // Format day label
      final dateTime = DateFormat('yyyy-MM-dd').parse(date);
      final dayName = DateFormat('E', 'id_ID').format(dateTime);
      dayLabels.add(dayName);
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Mingguan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dayLabels.length) {
                            return Text(
                              dayLabels[index],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build monthly chart
  Widget _buildMonthlyChart(
    Map<String, int> dailyCompleted,
    List<String> monthDates,
  ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < monthDates.length; i++) {
      final date = monthDates[i];
      final completed = dailyCompleted[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), completed.toDouble()));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Bulanan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = (value + 1).toInt();
                          return Text(
                            day.toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: spots.map((spot) {
                    return BarChartGroupData(
                      x: spot.x.toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: Theme.of(context).colorScheme.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build achievement section
  Widget _buildAchievementSection() {
    final habitsAsync = ref.watch(dailyHabitsProvider);

    return habitsAsync.when(
      data: (habits) {
        final achievements = <Widget>[];

        for (final habit in habits) {
          final badge = habit.getAchievementBadge();
          if (badge.isNotEmpty) {
            achievements.add(
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        if (achievements.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Belum ada achievement\nMulai bangun streak Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Achievement',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...achievements,
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

// ============================================================================
// REMINDER SETTINGS SCREEN
// ============================================================================

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isReminderEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Reminder'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifikasi Harian',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enable/Disable Switch
                  SwitchListTile(
                    title: const Text('Aktifkan Reminder'),
                    subtitle: const Text('Dapatkan notifikasi setiap hari'),
                    value: _isReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isReminderEnabled = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Time Picker
                  ListTile(
                    title: const Text('Waktu Reminder'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: _isReminderEnabled ? _selectTime : null,
                    enabled: _isReminderEnabled,
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReminderSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan Pengaturan'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Motivational Messages
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💪 Pesan Motivasi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMotivationalMessage(
                    'Jangan biarkan hari ini berlalu tanpa progress!',
                  ),
                  _buildMotivationalMessage(
                    'Konsistensi adalah kunci kesuksesan.',
                  ),
                  _buildMotivationalMessage(
                    'Setiap hari adalah kesempatan baru.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveReminderSettings() {
    // TODO: Implement reminder scheduling
    // await NotificationService.scheduleDailyReminder(
    //   time: _selectedTime,
    //   title: 'Habit Reminder',
    //   body: 'Jangan lupa selesaikan kebiasaan harian Anda!',
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isReminderEnabled
              ? 'Reminder diaktifkan pukul ${_selectedTime.format(context)}'
              : 'Reminder dinonaktifkan',
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }
}
