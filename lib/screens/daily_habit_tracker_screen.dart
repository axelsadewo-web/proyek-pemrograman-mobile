import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

// ============================================================================
// MODEL HABIT
// ============================================================================

/// Model Habit dengan tracking harian
class DailyHabit {
  String id;
  String name;
  String description;
  String category;
  String target; // 'Harian' atau 'Mingguan'
  bool isDoneToday;
  String? lastCompletedDate; // Format: yyyy-MM-dd
  DateTime createdAt;

  DailyHabit({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.target,
    this.isDoneToday = false,
    this.lastCompletedDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Konversi ke Map untuk Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'target': target,
      'isDoneToday': isDoneToday,
      'lastCompletedDate': lastCompletedDate,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create dari Map (Hive)
  factory DailyHabit.fromMap(Map<String, dynamic> map) {
    return DailyHabit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Olahraga',
      target: map['target'] ?? 'Harian',
      isDoneToday: map['isDoneToday'] ?? false,
      lastCompletedDate: map['lastCompletedDate'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Copy with
  DailyHabit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? target,
    bool? isDoneToday,
    String? lastCompletedDate,
    DateTime? createdAt,
  }) {
    return DailyHabit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      target: target ?? this.target,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Cek apakah bisa dicentang hari ini (belum dilakukan hari ini)
  bool canCheckTodayByDate() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return lastCompletedDate != today;
  }

  /// Get tanggal terakhir dalam format readable
  String getLastCompletedDateFormatted() {
    if (lastCompletedDate == null) {
      return 'Belum pernah dilakukan';
    }
    try {
      final date = DateFormat('yyyy-MM-dd').parse(lastCompletedDate!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (lastCompletedDate == today) {
        return 'Hari ini';
      }
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return lastCompletedDate ?? 'Tidak diketahui';
    }
  }
}

// ============================================================================
// HIVE BOX INITIALIZATION & PROVIDER
// ============================================================================

/// Hive adapter untuk Hive persisten storage
class HabitStorageService {
  static const String boxName = 'daily_habits';

  /// Initialize Hive box
  static Future<Box<Map>> initializeBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<Map>(boxName);
    }
    return Hive.box<Map>(boxName);
  }

  /// Get all habits dari Hive
  static Future<List<DailyHabit>> getAllHabits() async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    return box.values
        .map((e) => DailyHabit.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Save habit ke Hive
  static Future<void> saveHabit(DailyHabit habit) async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.put(habit.id, habit.toMap());
  }

  /// Delete habit dari Hive
  static Future<void> deleteHabit(String habitId) async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.delete(habitId);
  }

  /// Clear all habits
  static Future<void> clearAllHabits() async {
    await initializeBox();
    final box = Hive.box<Map>(boxName);
    await box.clear();
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider untuk daily habits list
final dailyHabitsProvider =
    StateNotifierProvider<DailyHabitsNotifier, AsyncValue<List<DailyHabit>>>(
  (ref) => DailyHabitsNotifier(),
);

/// StateNotifier untuk manage daily habits
class DailyHabitsNotifier extends StateNotifier<AsyncValue<List<DailyHabit>>> {
  DailyHabitsNotifier() : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  /// Load habits dari Hive
  Future<void> _loadHabits() async {
    try {
      final habits = await HabitStorageService.getAllHabits();
      // Reset isDoneToday jika bukan hari yang sama
      _resetDailyStatusIfNeeded(habits);
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Reset isDoneToday jika tanggal berbeda
  void _resetDailyStatusIfNeeded(List<DailyHabit> habits) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final habit in habits) {
      if (habit.lastCompletedDate != today && habit.isDoneToday) {
        habit.isDoneToday = false;
      }
    }
  }

  /// Toggle habit completion status
  Future<void> toggleHabitCompletion(String habitId) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    final habitIndex = habits.indexWhere((h) => h.id == habitId);

    if (habitIndex != -1) {
      final habit = habits[habitIndex];
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Cek validasi: tidak boleh double checklist dalam 1 hari
      if (habit.lastCompletedDate == today && habit.isDoneToday) {
        // Sudah dilakukan hari ini, tidak bisa dicentang lagi
        return;
      }

      // Update habit
      final updatedHabit = habit.copyWith(
        isDoneToday: !habit.isDoneToday,
        lastCompletedDate: !habit.isDoneToday ? today : habit.lastCompletedDate,
      );

      // Update list
      final updatedHabits = [...habits];
      updatedHabits[habitIndex] = updatedHabit;

      // Save ke Hive
      await HabitStorageService.saveHabit(updatedHabit);

      // Update state
      state = AsyncValue.data(updatedHabits);
    }
  }

  /// Add habit baru
  Future<void> addHabit(DailyHabit habit) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    habits.add(habit);

    await HabitStorageService.saveHabit(habit);
    state = AsyncValue.data(habits);
  }

  /// Delete habit
  Future<void> deleteHabit(String habitId) async {
    final currentState = state;
    if (currentState is! AsyncValue<List<DailyHabit>>) return;

    final habits = currentState.value ?? [];
    habits.removeWhere((h) => h.id == habitId);

    await HabitStorageService.deleteHabit(habitId);
    state = AsyncValue.data(habits);
  }
}

/// Provider untuk hitung progress hari ini
final dailyProgressProvider = Provider<Map<String, int>>((ref) {
  final habitsAsync = ref.watch(dailyHabitsProvider);

  return habitsAsync.when(
    data: (habits) {
      final completed = habits.where((h) => h.isDoneToday).length;
      final total = habits.length;
      return {'completed': completed, 'total': total};
    },
    loading: () => {'completed': 0, 'total': 0},
    error: (_, __) => {'completed': 0, 'total': 0},
  );
});

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
    final habits =
        await HabitStorageService.getAllHabits();
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
        ref.refresh(dailyHabitsProvider);
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
      ),
      body: habitsAsync.when(
        data: (habits) => SingleChildScrollView(
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, st) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  /// Build progress section di atas
  Widget _buildProgressSection(Map<String, int> progress) {
    final completed = progress['completed'] ?? 0;
    final total = progress['total'] ?? 0;
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completed/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar dengan animasi
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Motivasi text
          Text(
            _getMotivationText(completed, total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
        margin: const EdgeInsets.only(bottom: 12),
        elevation: habit.isDoneToday ? 4 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: habit.isDoneToday
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: habit.isDoneToday
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              habit.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                decoration: habit.isDoneToday
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: habit.isDoneToday
                    ? Colors.green.shade700
                    : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (habit.description.isNotEmpty)
                  Text(
                    habit.description,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  'Terakhir: ${habit.getLastCompletedDateFormatted()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat kebiasaan baru untuk memulai',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const ProviderScope(
        child: DailyHabitTrackerScreen(),
      ),
    );
  }
}
