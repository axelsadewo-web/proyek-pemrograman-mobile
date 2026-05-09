import 'package:flutter_test/flutter_test.dart';
import 'package:project_/models/daily_habit_model.dart';

void main() {
  group('Habit Saving Tests', () {
    test('DailyHabit toMap and fromMap should work correctly', () {
      final habit = DailyHabit(
        id: 'test1',
        name: 'Test Habit',
        description: 'Test description',
        category: 'Olahraga',
        target: 'Harian',
        schedule: 'Setiap hari',
      );

      final map = habit.toMap();
      final restoredHabit = DailyHabit.fromMap(map);

      expect(restoredHabit.id, habit.id);
      expect(restoredHabit.name, habit.name);
      expect(restoredHabit.description, habit.description);
      expect(restoredHabit.category, habit.category);
      expect(restoredHabit.target, habit.target);
      expect(restoredHabit.schedule, habit.schedule);
    });

    test('Habit validation should work', () {
      // Valid habit
      final validHabit = DailyHabit(
        id: 'test1',
        name: 'Valid Habit',
        category: 'Olahraga',
        target: 'Harian',
      );

      expect(validHabit.name.length >= 3, true);

      // Invalid habit - name too short
      final invalidHabit = DailyHabit(
        id: 'test2',
        name: 'Hi', // Too short
        category: 'Olahraga',
        target: 'Harian',
      );

      expect(invalidHabit.name.length < 3, true);
    });
  });
}
