import 'dart:math';
import 'package:intl/intl.dart';

// ============================================================================
// GAMIFICATION SERVICE
// ============================================================================

/// Service untuk mengelola sistem gamifikasi
class GamificationService {
  static const int XP_PER_HABIT = 10;
  static const int XP_PER_LEVEL = 100;

  /// Calculate level dari total XP
  static int calculateLevel(int totalXP) {
    return (totalXP / XP_PER_LEVEL).floor() + 1;
  }

  /// Calculate XP progress dalam level saat ini
  static Map<String, int> getLevelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final xpForCurrentLevel = (currentLevel - 1) * XP_PER_LEVEL;
    final xpInCurrentLevel = totalXP - xpForCurrentLevel;
    final xpToNextLevel = XP_PER_LEVEL - xpInCurrentLevel;

    return {
      'currentLevel': currentLevel,
      'xpInCurrentLevel': xpInCurrentLevel,
      'xpToNextLevel': xpToNextLevel,
      'progressPercentage': ((xpInCurrentLevel / XP_PER_LEVEL) * 100).round(),
    };
  }

  /// Get badge berdasarkan streak
  static List<String> getStreakBadges(int streak) {
    final badges = <String>[];

    if (streak >= 365) badges.add('🌟 Year Master');
    if (streak >= 100) badges.add('🏆 Century Champion');
    if (streak >= 50) badges.add('⭐ Golden Streak');
    if (streak >= 30) badges.add('🎯 Monthly Master');
    if (streak >= 7) badges.add('⚡ Weekly Warrior');
    if (streak >= 3) badges.add('🌟 Getting Started');

    return badges;
  }

  /// Get badge berdasarkan total habits completed
  static List<String> getCompletionBadges(int totalCompleted) {
    final badges = <String>[];

    if (totalCompleted >= 1000) badges.add('💎 Diamond Achiever');
    if (totalCompleted >= 500) badges.add('🥇 Gold Medalist');
    if (totalCompleted >= 100) badges.add('🥈 Silver Star');
    if (totalCompleted >= 50) badges.add('🥉 Bronze Winner');
    if (totalCompleted >= 10) badges.add('🎖️ First Steps');

    return badges;
  }

  /// Get badge berdasarkan consistency (hari aktif)
  static List<String> getConsistencyBadges(int activeDays, int totalDays) {
    final consistencyRate = totalDays > 0 ? (activeDays / totalDays) * 100 : 0;
    final badges = <String>[];

    if (consistencyRate >= 95) badges.add('👑 Perfectionist');
    if (consistencyRate >= 80) badges.add('🔥 Consistency King');
    if (consistencyRate >= 60) badges.add('💪 Dedicated');
    if (consistencyRate >= 40) badges.add('👍 Steady');

    return badges;
  }

  /// Calculate total XP dari habits
  static int calculateTotalXP(List<dynamic> habits) {
    int totalXP = 0;
    for (final habit in habits) {
      // XP dari completion history
      totalXP += habit.historyDates.length * XP_PER_HABIT;

      // Bonus XP dari streak
      if (habit.streak >= 7) totalXP += habit.streak * 2; // Bonus streak
      if (habit.streak >= 30) totalXP += habit.streak * 5; // Bonus monthly
    }
    return totalXP;
  }

  /// Get motivational message berdasarkan progress
  static String getMotivationalMessage(int currentXP, int targetXP) {
    final progress = targetXP > 0 ? (currentXP / targetXP) : 0;

    if (progress >= 1.0) {
      return '🎉 Level up! Kamu luar biasa!';
    } else if (progress >= 0.8) {
      return '🔥 Hampir sampai! Teruskan!';
    } else if (progress >= 0.5) {
      return '💪 Bagus! Setengah perjalanan!';
    } else if (progress >= 0.2) {
      return '🌟 Mulai bagus! Keep going!';
    } else {
      return '🚀 Ayo mulai hari ini!';
    }
  }
}

// ============================================================================
// MOTIVATIONAL QUOTES SERVICE
// ============================================================================

/// Service untuk mengelola quotes motivasi harian
class MotivationalQuotesService {
  static final List<String> _quotes = [
    'Konsistensi adalah kunci kesuksesan. Setiap hari kecil membawa perubahan besar.',
    'Jangan biarkan kemarin memakan hari esok Anda.',
    'Kebiasaan baik dimulai dari langkah kecil yang dilakukan secara konsisten.',
    'Setiap hari adalah kesempatan baru untuk menjadi versi terbaik diri Anda.',
    'Discipline adalah jembatan antara goals dan pencapaian.',
    'Kecil tapi konsisten lebih baik daripada besar tapi tidak konsisten.',
    'Perubahan dimulai dari kebiasaan sehari-hari.',
    'Jangan menunggu motivasi, ciptakan kebiasaan.',
    'Setiap kebiasaan baik yang Anda bangun hari ini akan membentuk masa depan Anda.',
    'Konsistensi mengalahkan intensitas.',
    'Mulai dari hal kecil, impian besar akan mengikuti.',
    'Kebiasaan adalah investasi untuk masa depan.',
    'Setiap hari adalah kesempatan untuk menjadi lebih baik.',
    'Konsistensi adalah cinta yang tenang.',
    'Bangun kebiasaan, bukan motivasi.',
    'Perjalanan seribu mil dimulai dengan langkah pertama yang konsisten.',
    'Kebiasaan baik adalah hadiah terbesar yang bisa Anda berikan pada diri sendiri.',
    'Konsistensi adalah bahasa cinta pada diri sendiri.',
    'Setiap kebiasaan yang Anda bangun hari ini adalah kemenangan.',
    'Jangan biarkan hari ini berlalu tanpa progress.',
  ];

  static final List<String> _authors = [
    'Aristoteles',
    'Ralph Waldo Emerson',
    'James Clear',
    'Confucius',
    'Jim Rohn',
    'Bruce Lee',
    'Mahatma Gandhi',
    'Albert Einstein',
    'Steve Jobs',
    'Nelson Mandela',
    'Maya Angelou',
    'Warren Buffett',
    'J.K. Rowling',
    'Richard Branson',
    'Elon Musk',
    'Bill Gates',
    'Oprah Winfrey',
    'Richard Branson',
    'Tony Robbins',
    'Zig Ziglar',
  ];

  /// Get quote harian berdasarkan tanggal
  static Map<String, String> getDailyQuote() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    // Gunakan dayOfYear sebagai seed untuk konsistensi harian
    final random = Random(dayOfYear);
    final quoteIndex = random.nextInt(_quotes.length);
    final authorIndex = random.nextInt(_authors.length);

    return {
      'quote': _quotes[quoteIndex],
      'author': _authors[authorIndex],
      'date': today,
    };
  }

  /// Get random quote (untuk testing)
  static Map<String, String> getRandomQuote() {
    final random = Random();
    final quoteIndex = random.nextInt(_quotes.length);
    final authorIndex = random.nextInt(_authors.length);

    return {
      'quote': _quotes[quoteIndex],
      'author': _authors[authorIndex],
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
  }

  /// Get quote by index
  static Map<String, String> getQuoteByIndex(int index) {
    final quoteIndex = index % _quotes.length;
    final authorIndex = index % _authors.length;

    return {
      'quote': _quotes[quoteIndex],
      'author': _authors[authorIndex],
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
  }

  /// Get all quotes (untuk admin/debug)
  static List<Map<String, String>> getAllQuotes() {
    final quotes = <Map<String, String>>[];
    for (int i = 0; i < _quotes.length; i++) {
      quotes.add({
        'quote': _quotes[i],
        'author': _authors[i],
        'index': i.toString(),
      });
    }
    return quotes;
  }
}

// ============================================================================
// PROFILE SERVICE
// ============================================================================

/// Service untuk mengelola profile user dan gamifikasi stats
class ProfileService {
  static Map<String, dynamic> calculateProfileStats(List<dynamic> habits) {
    int totalXP = GamificationService.calculateTotalXP(habits);
    int totalCompleted = 0;
    int longestStreak = 0;
    int activeStreaks = 0;
    int totalActiveDays = 0;

    final allHistoryDates = <String>{};

    for (final habit in habits) {
      totalCompleted += habit.historyDates.length;
      longestStreak = habit.streak > longestStreak ? habit.streak : longestStreak;
      if (habit.streak > 0) activeStreaks++;
      allHistoryDates.addAll(habit.historyDates);
    }

    totalActiveDays = allHistoryDates.length;

    final levelProgress = GamificationService.getLevelProgress(totalXP);
    final streakBadges = GamificationService.getStreakBadges(longestStreak);
    final completionBadges = GamificationService.getCompletionBadges(totalCompleted);
    final consistencyBadges = GamificationService.getConsistencyBadges(
      totalActiveDays,
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays,
    );

    final allBadges = {...streakBadges, ...completionBadges, ...consistencyBadges}.toList();

    return {
      'totalXP': totalXP,
      'currentLevel': levelProgress['currentLevel'],
      'xpInCurrentLevel': levelProgress['xpInCurrentLevel'],
      'xpToNextLevel': levelProgress['xpToNextLevel'],
      'progressPercentage': levelProgress['progressPercentage'],
      'totalCompleted': totalCompleted,
      'longestStreak': longestStreak,
      'activeStreaks': activeStreaks,
      'totalActiveDays': totalActiveDays,
      'badges': allBadges,
      'streakBadges': streakBadges,
      'completionBadges': completionBadges,
      'consistencyBadges': consistencyBadges,
    };
  }
}