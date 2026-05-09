import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_/main.dart';
import 'package:project_/screens/add_edit_habit_screen.dart';
import 'package:project_/models/daily_habit_model.dart';

void main() {
  testWidgets('Add habit form validation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Wait for app to load
    await tester.pumpAndSettle();

    // Navigate to add habit screen (assuming there's a way to navigate)
    // For now, just test the form widget directly
    final addHabitScreen = AddEditHabitScreen();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AddEditHabitScreen())),
      ),
    );

    await tester.pumpAndSettle();

    // Find the save button
    final saveButton = find.text('Simpan Kebiasaan');
    expect(saveButton, findsOneWidget);

    // Try to save without filling required fields
    await tester.tap(saveButton);
    await tester.pump();

    // Should show validation error
    expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Habit model serialization works', (WidgetTester tester) async {
    final habit = DailyHabit(
      id: 'test1',
      name: 'Test Habit',
      description: 'Test description',
      category: 'Olahraga',
      target: 'Harian',
    );

    final map = habit.toMap();
    final restored = DailyHabit.fromMap(map);

    expect(restored.id, habit.id);
    expect(restored.name, habit.name);
    expect(restored.category, habit.category);
  });
}
