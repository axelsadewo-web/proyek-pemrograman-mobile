import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

// ============================================================================
// EXPORT SERVICE
// ============================================================================

/// Service untuk export data ke berbagai format
class ExportService {
  /// Export habits data ke CSV
  static Future<void> exportHabitsToCSV(List<dynamic> habits) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw 'Storage permission denied';
      }

      // Prepare CSV data
      List<List<String>> csvData = [
        // Header row
        [
          'ID',
          'Name',
          'Description',
          'Frequency',
          'Created Date',
          'Total Completions',
          'Current Streak',
          'Longest Streak',
          'Completion Dates'
        ]
      ];

      // Add habit data
      for (final habit in habits) {
        final completions = habit.completions ?? [];
        final completionDates = completions.join('; ');

        csvData.add([
          habit.id ?? '',
          habit.name ?? '',
          habit.description ?? '',
          habit.frequency ?? '',
          habit.createdAt?.toString() ?? '',
          completions.length.toString(),
          _calculateCurrentStreak(completions).toString(),
          _calculateLongestStreak(completions).toString(),
          completionDates,
        ]);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get directory for saving file
      final directory = await _getExportDirectory();
      final fileName = 'habits_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Habit Tracker Export',
      );
    } catch (e) {
      throw 'Failed to export CSV: $e';
    }
  }

  /// Export statistics ke CSV
  static Future<void> exportStatisticsToCSV(List<dynamic> habits) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw 'Storage permission denied';
      }

      // Calculate statistics
      final stats = _calculateStatistics(habits);

      // Prepare CSV data
      List<List<String>> csvData = [
        ['Statistic', 'Value'],
        ['Total Habits', stats['totalHabits'].toString()],
        ['Active Habits', stats['activeHabits'].toString()],
        ['Total Completions', stats['totalCompletions'].toString()],
        ['Average Completions per Day', stats['avgCompletionsPerDay'].toStringAsFixed(2)],
        ['Longest Streak', stats['longestStreak'].toString()],
        ['Current Streak', stats['currentStreak'].toString()],
        ['Most Productive Day', stats['mostProductiveDay']],
        ['Total Active Days', stats['totalActiveDays'].toString()],
        ['Completion Rate (%)', stats['completionRate'].toStringAsFixed(2)],
      ];

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get directory for saving file
      final directory = await _getExportDirectory();
      final fileName = 'statistics_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Habit Tracker Statistics',
      );
    } catch (e) {
      throw 'Failed to export statistics: $e';
    }
  }

  /// Export detailed habit progress ke CSV
  static Future<void> exportHabitProgressToCSV(dynamic habit) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw 'Storage permission denied';
      }

      final completions = habit.completions ?? [];
      final habitName = habit.name ?? 'Unknown Habit';

      // Prepare CSV data
      List<List<String>> csvData = [
        ['Date', 'Completed', 'Streak'],
      ];

      // Generate date range (last 90 days)
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 90));

      int currentStreak = 0;
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final dateString = _formatDate(currentDate);
        final isCompleted = completions.contains(dateString);

        if (isCompleted) {
          currentStreak++;
        } else {
          currentStreak = 0;
        }

        csvData.add([
          dateString,
          isCompleted ? '1' : '0',
          currentStreak.toString(),
        ]);

        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      // Get directory for saving file
      final directory = await _getExportDirectory();
      final fileName = '${habitName.replaceAll(' ', '_')}_progress_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(csvString);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Habit Progress: $habitName',
      );
    } catch (e) {
      throw 'Failed to export habit progress: $e';
    }
  }

  /// Get export directory
  static Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final exportDir = Directory('${directory.path}/HabitTracker');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        return exportDir;
      }
    }

    // Fallback to app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Calculate current streak from completions
  static int _calculateCurrentStreak(List<String> completions) {
    if (completions.isEmpty) return 0;

    final sortedCompletions = List<String>.from(completions)..sort();
    final today = DateTime.now();
    final todayString = _formatDate(today);

    int streak = 0;
    DateTime checkDate = today;

    // Check if completed today
    if (!completions.contains(todayString)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateString = _formatDate(checkDate);
      if (completions.contains(dateString)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest streak from completions
  static int _calculateLongestStreak(List<String> completions) {
    if (completions.isEmpty) return 0;

    final sortedCompletions = List<String>.from(completions)..sort();
    int longestStreak = 0;
    int currentStreak = 1;

    for (int i = 1; i < sortedCompletions.length; i++) {
      final prevDate = DateTime.parse(sortedCompletions[i - 1]);
      final currentDate = DateTime.parse(sortedCompletions[i]);

      if (currentDate.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        longestStreak = longestStreak > currentStreak ? longestStreak : currentStreak;
        currentStreak = 1;
      }
    }

    return longestStreak > currentStreak ? longestStreak : currentStreak;
  }

  /// Calculate comprehensive statistics
  static Map<String, dynamic> _calculateStatistics(List<dynamic> habits) {
    int totalHabits = habits.length;
    int activeHabits = habits.where((h) => (h.completions?.length ?? 0) > 0).length;
    int totalCompletions = 0;
    int longestStreak = 0;
    int currentStreak = 0;
    int totalActiveDays = 0;
    Map<String, int> dayCompletions = {};

    for (final habit in habits) {
      final completions = habit.completions ?? [];
      totalCompletions += completions.length;

      final habitLongestStreak = _calculateLongestStreak(completions);
      final habitCurrentStreak = _calculateCurrentStreak(completions);

      longestStreak = longestStreak > habitLongestStreak ? longestStreak : habitLongestStreak;
      currentStreak = currentStreak > habitCurrentStreak ? currentStreak : habitCurrentStreak;

      // Count completions per day
      for (final date in completions) {
        dayCompletions[date] = (dayCompletions[date] ?? 0) + 1;
      }
    }

    totalActiveDays = dayCompletions.length;

    // Find most productive day
    String mostProductiveDay = 'N/A';
    int maxCompletions = 0;
    dayCompletions.forEach((date, count) {
      if (count > maxCompletions) {
        maxCompletions = count;
        mostProductiveDay = date;
      }
    });

    // Calculate average completions per day
    double avgCompletionsPerDay = totalActiveDays > 0 ? totalCompletions / totalActiveDays : 0;

    // Calculate completion rate (assuming 90 days period)
    double completionRate = totalHabits > 0 ? (totalCompletions / (totalHabits * 90)) * 100 : 0;

    return {
      'totalHabits': totalHabits,
      'activeHabits': activeHabits,
      'totalCompletions': totalCompletions,
      'avgCompletionsPerDay': avgCompletionsPerDay,
      'longestStreak': longestStreak,
      'currentStreak': currentStreak,
      'mostProductiveDay': mostProductiveDay,
      'totalActiveDays': totalActiveDays,
      'completionRate': completionRate,
    };
  }

  /// Format date to string
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}