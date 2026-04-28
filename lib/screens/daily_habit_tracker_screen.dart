import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_/models/daily_habit_model.dart';

// ============================================================================
// DAILY HABIT TRACKER SCREEN
// ============================================================================

class DailyHabitTrackerScreen extends ConsumerStatefulWidget {
  const DailyHabitTrackerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyHabitTrackerScreen> createState() =>
      _DailyHabitTrackerScreenState();
}

class _DailyHabitTrackerScreenState
    extends ConsumerState<DailyHabitTrackerScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  /// Initialize demo data jika belum ada
  Future<void> _initializeDemoData() async {
    final habits = await HabitStorageService.getAllHabits();
    if (habits.isEmpty) {
      final demoHabits = [
        DailyHabit(
          id: '1',
          name: 'Berlari Pagi',
          description: '30 menit berlari',
          category: 'Olahraga',
          target: 'Harian',
        ),
        DailyHabit(
          id: '2',
          name: 'Baca Buku',
          description: 'Membaca minimal 20 halaman',
          category: 'Belajar',
          target: 'Harian',
        ),
        DailyHabit(
          id: '3',
          name: 'Minum Air',
          description: 'Minum 8 gelas air',
          category: 'Kesehatan',
          target: 'Harian',
        ),
        DailyHabit(
          id: '4',
          name: 'Meditasi',
          description: '10 menit meditasi pagi',
          category: 'Spiritual',
          target: 'Harian',
        ),
        DailyHabit(
          id: '5',
          name: 'Review Kode',
          description: 'Review project Flutter',
          category: 'Produktivitas',
          target: 'Harian',
        ),
      ];

      for (final habit in demoHabits) {
        await HabitStorageService.saveHabit(habit);
      }

      if (mounted) {
        final _ = ref.refresh(dailyHabitsProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(dailyHabitsProvider);
    final progress = ref.watch(dailyProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Harian'),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-habit'),
        child: const Icon(Icons.add),
        tooltip: 'Tambah Habit Baru',
      ),
      body: habitsAsync.when(
        data: (habits) => RefreshIndicator(
          onRefresh: () async {
            ref.refresh(dailyHabitsProvider);
            await Future.delayed(const Duration(milliseconds: 200));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Progress Section
                _buildProgressSection(progress),
                const SizedBox(height: 16),

                // Habits List
                if (habits.isEmpty)
                  _buildEmptyState()
                else
                  _buildHabitsList(habits),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Build progress section di atas
  Widget _buildProgressSection(Map<String, int> progress) {
    final completed = progress['completed'] ?? 0;
    final total = progress['total'] ?? 0;
    final percentage = total > 0 ? (completed / total) : 0.0;
    final remaining = total - completed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
<<<<<<< HEAD
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
=======
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
>>>>>>> ac332bd445d439c07c48f34b6d3bc410dd4bf9b9
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Hari Ini',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFEC4899),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            remaining <= 0
                ? 'Semua tugas selesai. Hebat sekali!'
                : 'Tinggal $remaining kebiasaan lagi untuk menyelesaikan semua hari ini.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressTag('Completed', '$completed', Icons.check_circle),
              const SizedBox(width: 12),
              _buildProgressTag('Total', '$total', Icons.list),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTag(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get motivation text berdasarkan progress
  String _getMotivationText(int completed, int total) {
    if (total == 0) return 'Belum ada kebiasaan';
    if (completed == 0) return 'Mulai dari satu kebiasaan 💪';
    if (completed == total) return 'Sempurna! Semua kebiasaan selesai ✨';
    final remaining = total - completed;
    return 'Lanjutkan! Tinggal $remaining kebiasaan lagi 🎯';
  }

  /// Build list of habits
  Widget _buildHabitsList(List<DailyHabit> habits) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return _buildHabitItem(habits[index], index);
      },
    );
  }

  /// Build individual habit item dengan animasi
  Widget _buildHabitItem(DailyHabit habit, int index) {
    final canCheck = habit.canCheckTodayByDate();

    return GestureDetector(
      onTap: canCheck
          ? () => ref
                .read(dailyHabitsProvider.notifier)
                .toggleHabitCompletion(habit.id)
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: habit.isDoneToday ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: habit.isDoneToday
                ? const LinearGradient(
                    colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: habit.isDoneToday
                ? null
                : Theme.of(context).cardColor,
            border: Border.all(
              color: habit.isDoneToday
                  ? Colors.green.shade300
                  : Colors.grey.shade200,
              width: 1.4,
            ),
          ),
          child: ListTile(
<<<<<<< HEAD
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
=======
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
>>>>>>> ac332bd445d439c07c48f34b6d3bc410dd4bf9b9
            title: Text(
              habit.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                decoration: habit.isDoneToday
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: habit.isDoneToday
                    ? Colors.green.shade800
                    : Colors.grey.shade900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                if (habit.description.isNotEmpty)
                  Text(
                    habit.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (habit.description.isNotEmpty) const SizedBox(height: 8),
                Text(
                  'Terakhir: ${habit.getLastCompletedDateFormatted()}',
<<<<<<< HEAD
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
=======
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
>>>>>>> ac332bd445d439c07c48f34b6d3bc410dd4bf9b9
                ),
              ],
            ),
            trailing: _buildCheckboxAnimated(habit, canCheck),
          ),
        ),
      ),
    );
  }

  /// Build animated checkbox
  Widget _buildCheckboxAnimated(DailyHabit habit, bool canCheck) {
    return AnimatedScale(
      scale: habit.isDoneToday ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: habit.isDoneToday ? Colors.green : Colors.grey.shade200,
        ),
        child: Checkbox(
          value: habit.isDoneToday,
          onChanged: canCheck
              ? (_) => ref
                    .read(dailyHabitsProvider.notifier)
                    .toggleHabitCompletion(habit.id)
              : null,
          fillColor: MaterialStateProperty.all(
            habit.isDoneToday ? Colors.green : Colors.transparent,
          ),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada kebiasaan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat kebiasaan baru untuk memulai',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN APP (untuk testing)
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HabitStorageService.initializeBox();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Habit Tracker',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const ProviderScope(child: DailyHabitTrackerScreen()),
    );
  }
}
