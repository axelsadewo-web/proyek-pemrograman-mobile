import '../models/daily_habit_model.dart';

class HabitTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final String difficulty; // 'Mudah', 'Sedang', 'Sulit'
  final int averageStreak;
  final List<String> tips;

  HabitTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.difficulty,
    required this.averageStreak,
    required this.tips,
  });

  /// Convert template to DailyHabit
  DailyHabit toHabit() {
    return DailyHabit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      category: category,
      target: 'Harian',
      schedule: 'Setiap hari',
    );
  }
}

class HabitTemplatesService {
  /// Get all available templates
  static List<HabitTemplate> getAllTemplates() {
    return [
      // Health & Fitness
      HabitTemplate(
        id: 'template_morning_run',
        name: 'Olahraga Pagi',
        description: 'Jogging atau lari pagi untuk kesehatan kardiovaskular',
        category: 'Olahraga',
        icon: '🏃',
        difficulty: 'Sedang',
        averageStreak: 42,
        tips: [
          'Mulai dengan jarak pendek (2-3 km)',
          'Lakukan pada pagi hari yang konsisten',
          'Perlahan tingkatkan kecepatan dan jarak',
          'Jangan lupa pemanasan dan pendinginan',
        ],
      ),
      HabitTemplate(
        id: 'template_workout',
        name: 'Gym/Workout',
        description: 'Latihan beban dan kekuatan di gym',
        category: 'Olahraga',
        icon: '💪',
        difficulty: 'Sedang',
        averageStreak: 35,
        tips: [
          'Fokus pada form yang benar',
          'Jangan berlebihan di awal',
          'Istirahat cukup antar sesi',
          'Konsisten 3-5 hari seminggu',
        ],
      ),
      HabitTemplate(
        id: 'template_yoga',
        name: 'Yoga/Stretching',
        description: 'Yoga atau stretching untuk fleksibilitas dan ketenangan',
        category: 'Meditasi',
        icon: '🧘',
        difficulty: 'Mudah',
        averageStreak: 56,
        tips: [
          'Mulai dengan 10-15 menit',
          'Ikuti video tutorial',
          'Dengarkan tubuh Anda',
          'Konsisten lebih penting daripada intensitas',
        ],
      ),
      HabitTemplate(
        id: 'template_meditation',
        name: 'Meditasi',
        description: 'Meditasi untuk kesehatan mental dan mindfulness',
        category: 'Meditasi',
        icon: '🧠',
        difficulty: 'Mudah',
        averageStreak: 63,
        tips: [
          'Mulai dengan 5 menit saja',
          'Cari tempat yang tenang',
          'Gunakan aplikasi seperti Headspace',
          'Jangan khawatir dengan "pikiran kosong"',
        ],
      ),

      // Learning & Development
      HabitTemplate(
        id: 'template_reading',
        name: 'Membaca',
        description: 'Membaca buku atau artikel untuk pengembangan diri',
        category: 'Belajar',
        icon: '📚',
        difficulty: 'Mudah',
        averageStreak: 45,
        tips: [
          'Mulai dengan 15-20 menit',
          'Pilih genre yang Anda sukai',
          'Buat catatan poin penting',
          'Baca di tempat yang nyaman',
        ],
      ),
      HabitTemplate(
        id: 'template_coding',
        name: 'Coding/Programming',
        description: 'Belajar atau latihan programming',
        category: 'Coding',
        icon: '💻',
        difficulty: 'Sulit',
        averageStreak: 38,
        tips: [
          'Build projects, bukan hanya tutorial',
          'Mulai dengan problem solving sederhana',
          'Dokumentasikan apa yang Anda pelajari',
          'Gabung komunitas developer',
        ],
      ),
      HabitTemplate(
        id: 'template_learning',
        name: 'Belajar Hal Baru',
        description: 'Belajar skill atau pengetahuan baru',
        category: 'Belajar',
        icon: '🎓',
        difficulty: 'Sedang',
        averageStreak: 28,
        tips: [
          'Ikuti kursus online (Udemy, Coursera)',
          'Set target pembelajaran spesifik',
          'Praktik apa yang telah dipelajari',
          'Review secara berkala',
        ],
      ),

      // Health & Wellness
      HabitTemplate(
        id: 'template_sleep',
        name: 'Tidur Cukup',
        description: 'Tidur 7-8 jam setiap malam',
        category: 'Tidur',
        icon: '😴',
        difficulty: 'Mudah',
        averageStreak: 71,
        tips: [
          'Set jadwal tidur yang konsisten',
          'Hindari gadget 30 menit sebelum tidur',
          'Kamar gelap dan sejuk',
          'Batasi kafein setelah jam 3 sore',
        ],
      ),
      HabitTemplate(
        id: 'template_nutrition',
        name: 'Makan Sehat',
        description: 'Mengonsumsi makanan bergizi seimbang',
        category: 'Nutrisi',
        icon: '🥗',
        difficulty: 'Mudah',
        averageStreak: 52,
        tips: [
          'Siapkan meal plan mingguan',
          'Makan 3 kali utama + 1-2 snack',
          'Perbanyak sayur dan buah',
          'Minum air putih minimal 8 gelas',
        ],
      ),
      HabitTemplate(
        id: 'template_water',
        name: 'Minum Air Putih',
        description: 'Minum air putih 8-10 gelas per hari',
        category: 'Kesehatan',
        icon: '💧',
        difficulty: 'Mudah',
        averageStreak: 84,
        tips: [
          'Minum segelas air setelah bangun',
          'Bawa botol minum kemana-mana',
          'Atur reminder setiap jam',
          'Minum air sebelum makan',
        ],
      ),

      // Productivity & Habits
      HabitTemplate(
        id: 'template_morningroutine',
        name: 'Rutinitas Pagi',
        description: 'Rutinitas produktif di pagi hari',
        category: 'Produktivitas',
        icon: '🌅',
        difficulty: 'Sedang',
        averageStreak: 47,
        tips: [
          'Bangun pada waktu yang sama setiap hari',
          'Jangan langsung cek ponsel',
          'Lakukan exercise atau meditasi',
          'Sarapan yang bergizi',
        ],
      ),
      HabitTemplate(
        id: 'template_journaling',
        name: 'Journaling',
        description: 'Menulis jurnal untuk refleksi diri',
        category: 'Produktivitas',
        icon: '📝',
        difficulty: 'Mudah',
        averageStreak: 35,
        tips: [
          'Tulis 10-15 menit setiap hari',
          'Tulis apa yang rasakan, bukan apa adanya',
          'Jangan khawatir dengan grammar',
          'Gunakan prompts jika stuck',
        ],
      ),
      HabitTemplate(
        id: 'template_planning',
        name: 'Perencanaan Harian',
        description: 'Merencanakan aktivitas harian',
        category: 'Produktivitas',
        icon: '📋',
        difficulty: 'Mudah',
        averageStreak: 41,
        tips: [
          'Buat to-do list 3 prioritas utama',
          'Review dan update setiap pagi/sore',
          'Tandai task yang selesai',
          'Evaluasi akhir hari',
        ],
      ),

      // Social & Relationships
      HabitTemplate(
        id: 'template_social',
        name: 'Social Time',
        description: 'Menghabiskan waktu bersama orang terkasih',
        category: 'Sosial',
        icon: '👥',
        difficulty: 'Mudah',
        averageStreak: 31,
        tips: [
          'Schedule waktu quality time',
          'Minimal 30 menit perhari',
          'Letakkan ponsel',
          'Dengarkan dengan penuh perhatian',
        ],
      ),

      // Hobbies & Creative
      HabitTemplate(
        id: 'template_music',
        name: 'Bermain Musik',
        description: 'Praktik alat musik favorit',
        category: 'Musik',
        icon: '🎸',
        difficulty: 'Sedang',
        averageStreak: 33,
        tips: [
          'Mulai dengan 15-30 menit praktek',
          'Konsisten lebih penting dari durasi',
          'Ikuti online course',
          'Play songs yang Anda sukai',
        ],
      ),
      HabitTemplate(
        id: 'template_art',
        name: 'Berkarya Seni',
        description: 'Melukis, menggambar, atau berkarya kreatif',
        category: 'Hobi',
        icon: '🎨',
        difficulty: 'Mudah',
        averageStreak: 27,
        tips: [
          'Jangan terlalu fokus pada hasil',
          'Eksperimen dengan teknik baru',
          'Ikuti tutorial online',
          'Share karya dengan orang lain',
        ],
      ),
    ];
  }

  /// Get templates by category
  static List<HabitTemplate> getTemplatesByCategory(String category) {
    return getAllTemplates()
        .where((template) => template.category == category)
        .toList();
  }

  /// Get templates by difficulty
  static List<HabitTemplate> getTemplatesByDifficulty(String difficulty) {
    return getAllTemplates()
        .where((template) => template.difficulty == difficulty)
        .toList();
  }

  /// Get popular templates
  static List<HabitTemplate> getPopularTemplates() {
    final templates = getAllTemplates();
    templates.sort((a, b) => b.averageStreak.compareTo(a.averageStreak));
    return templates.take(5).toList();
  }

  /// Get all categories
  static List<String> getAllCategories() {
    final categories = getAllTemplates()
        .map((t) => t.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Get all difficulties
  static List<String> getAllDifficulties() {
    return ['Mudah', 'Sedang', 'Sulit'];
  }

  /// Search templates
  static List<HabitTemplate> searchTemplates(String query) {
    query = query.toLowerCase();
    return getAllTemplates()
        .where(
          (template) =>
              template.name.toLowerCase().contains(query) ||
              template.description.toLowerCase().contains(query) ||
              template.category.toLowerCase().contains(query),
        )
        .toList();
  }
}
