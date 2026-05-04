import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gamification_service.dart';

// ============================================================================
// HOME WIDGET SERVICE
// ============================================================================

/// Service untuk mengelola Home Widget Android
class HomeWidgetService {
  static const String _appGroupId = 'group.habit_tracker_widget';
  static const String _habitsCountKey = 'habits_count';
  static const String _completedTodayKey = 'completed_today';
  static const String _currentStreakKey = 'current_streak';
  static const String _levelKey = 'current_level';

  /// Update home widget dengan data terbaru
  static Future<void> updateHomeWidget(List<dynamic> habits) async {
    try {
      final stats = ProfileService.calculateProfileStats(habits);

      // Hitung habits yang completed hari ini
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      int completedToday = 0;

      for (final habit in habits) {
        final completions = habit.completions ?? [];
        if (completions.contains(todayString)) {
          completedToday++;
        }
      }

      // Update widget data
      await HomeWidget.saveWidgetData<String>(
        _habitsCountKey,
        habits.length.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        _completedTodayKey,
        completedToday.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        _currentStreakKey,
        stats['longestStreak'].toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        _levelKey,
        stats['currentLevel'].toString(),
      );

      // Update widget
      await HomeWidget.updateWidget(
        name: 'HabitTrackerWidgetProvider',
        androidName: 'HabitTrackerWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  /// Handle tap pada widget
  static Future<void> handleWidgetTap() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (uri != null) {
        // Handle deep link dari widget
        debugPrint('Launched from widget: $uri');
      }
    } catch (e) {
      debugPrint('Error handling widget tap: $e');
    }
  }

  /// Get data dari widget untuk display
  static Future<Map<String, String>> getWidgetData() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final habitsCount =
          await HomeWidget.getWidgetData<String>(_habitsCountKey) ?? '0';
      final completedToday =
          await HomeWidget.getWidgetData<String>(_completedTodayKey) ?? '0';
      final currentStreak =
          await HomeWidget.getWidgetData<String>(_currentStreakKey) ?? '0';
      final level = await HomeWidget.getWidgetData<String>(_levelKey) ?? '1';

      return {
        'habitsCount': habitsCount,
        'completedToday': completedToday,
        'currentStreak': currentStreak,
        'level': level,
      };
    } catch (e) {
      debugPrint('Error getting widget data: $e');
      return {
        'habitsCount': '0',
        'completedToday': '0',
        'currentStreak': '0',
        'level': '1',
      };
    }
  }
}

// ============================================================================
// HOME WIDGET PROVIDER
// ============================================================================

/// Provider untuk home widget data
final homeWidgetDataProvider = FutureProvider<Map<String, String>>((ref) {
  return HomeWidgetService.getWidgetData();
});

// ============================================================================
// ANDROID HOME WIDGET CONFIGURATION
// ============================================================================

/// Konfigurasi untuk Android Home Widget
/// File ini harus disimpan di android/app/src/main/kotlin/com/example/habit_tracker/HomeWidgetProvider.kt
const String androidHomeWidgetProvider = '''
package com.example.habit_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HabitTrackerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: android.content.SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from shared preferences
                val habitsCount = widgetData.getString("habits_count", "0") ?: "0"
                val completedToday = widgetData.getString("completed_today", "0") ?: "0"
                val currentStreak = widgetData.getString("current_streak", "0") ?: "0"
                val level = widgetData.getString("current_level", "1") ?: "1"

                // Update widget views
                setTextViewText(R.id.habits_count, habitsCount)
                setTextViewText(R.id.completed_today, completedToday)
                setTextViewText(R.id.current_streak, currentStreak)
                setTextViewText(R.id.level, level)

                // Set up click intent
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("habittracker://home")
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
''';

/// Layout XML untuk widget
/// File ini harus disimpan di android/app/src/main/res/layout/widget_layout.xml
const String androidWidgetLayout = '''
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_container"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:background="@drawable/widget_background"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Habit Tracker"
        android:textColor="#FFFFFF"
        android:textSize="16sp"
        android:textStyle="bold"
        android:layout_gravity="center_horizontal"
        android:layout_marginBottom="8dp" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:layout_marginBottom="8dp">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center">

            <TextView
                android:id="@+id/habits_count"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="0"
                android:textColor="#FFFFFF"
                android:textSize="24sp"
                android:textStyle="bold" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Habits"
                android:textColor="#CCCCCC"
                android:textSize="12sp" />

        </LinearLayout>

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center">

            <TextView
                android:id="@+id/completed_today"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="0"
                android:textColor="#FFFFFF"
                android:textSize="24sp"
                android:textStyle="bold" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Today"
                android:textColor="#CCCCCC"
                android:textSize="12sp" />

        </LinearLayout>

    </LinearLayout>

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal">

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center">

            <TextView
                android:id="@+id/current_streak"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="0"
                android:textColor="#FFFFFF"
                android:textSize="18sp"
                android:textStyle="bold" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Streak"
                android:textColor="#CCCCCC"
                android:textSize="10sp" />

        </LinearLayout>

        <LinearLayout
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:orientation="vertical"
            android:gravity="center">

            <TextView
                android:id="@+id/level"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="1"
                android:textColor="#FFFFFF"
                android:textSize="18sp"
                android:textStyle="bold" />

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Level"
                android:textColor="#CCCCCC"
                android:textSize="10sp" />

        </LinearLayout>

    </LinearLayout>

</LinearLayout>
''';

/// Background drawable untuk widget
/// File ini harus disimpan di android/app/src/main/res/drawable/widget_background.xml
const String androidWidgetBackground = '''
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <gradient
        android:startColor="#6200EE"
        android:endColor="#3700B3"
        android:angle="45" />
    <corners android:radius="16dp" />
</shape>
''';

// ============================================================================
// WIDGET PREVIEW WIDGET
// ============================================================================

/// Widget untuk preview home widget di dalam app
class HomeWidgetPreview extends ConsumerWidget {
  const HomeWidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widgetDataAsync = ref.watch(homeWidgetDataProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6200EE), Color(0xFF3700B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: widgetDataAsync.when(
          data: (data) => _buildWidgetContent(data),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (error, st) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetContent(Map<String, String> data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '📱 Home Widget Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Stats Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(data['habitsCount'] ?? '0', 'Habits'),
            _buildStatItem(data['completedToday'] ?? '0', 'Today'),
          ],
        ),
        const SizedBox(height: 12),

        // Stats Row 2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(data['currentStreak'] ?? '0', 'Streak'),
            _buildStatItem(data['level'] ?? '1', 'Level'),
          ],
        ),

        const SizedBox(height: 16),
        const Text(
          'Tap to open app',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET SETUP INSTRUCTIONS
// ============================================================================

/// Instruksi untuk setup Android Home Widget
const String homeWidgetSetupInstructions = '''
# Android Home Widget Setup Instructions

## 1. Add Dependencies to pubspec.yaml
```yaml
dependencies:
  home_widget: ^0.1.6
```

## 2. Update AndroidManifest.xml
Add these permissions and service to android/app/src/main/AndroidManifest.xml:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.habit_tracker">

    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <!-- Add app group for widget data sharing -->
    <permission
        android:name="group.habit_tracker_widget"
        android:protectionLevel="signature" />
    <uses-permission android:name="group.habit_tracker_widget" />

    <application>
        <!-- Add this receiver -->
        <receiver android:name=".HabitTrackerWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_info" />
        </receiver>
        
        <!-- Add this service for background updates -->
        <service
            android:name="es.antonborri.home_widget.HomeWidgetBackgroundService"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="true" />
    </application>
</manifest>
```

## 3. Create Widget Info XML
Create android/app/src/main/res/xml/widget_info.xml:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="86400000"
    android:initialLayout="@layout/widget_layout"
    android:configure="com.example.habit_tracker.HabitTrackerWidgetConfigure"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen">
</appwidget-provider>
```

## 4. Create Kotlin Files
Create the Kotlin files as shown in the constants above.

## 5. Update MainActivity.kt
Add this to your MainActivity.kt:

```kotlin
import es.antonborri.home_widget.HomeWidgetPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        HomeWidgetPlugin.registerWith(flutterEngine)
    }
}
```

## 6. Initialize in Flutter App
Add this to your main.dart or app initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Home Widget
  await HomeWidget.setAppGroupId('group.habit_tracker_widget');
  
  runApp(MyApp());
}
```

## 7. Update Widget When Data Changes
Call this whenever habits data changes:

```dart
await HomeWidgetService.updateHomeWidget(habits);
```
''';
