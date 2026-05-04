import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/daily_habit_model.dart';

class SqliteHelper {
  static const String _databaseName = 'db_habit_pro.db';
  static const String _habitsTable = 'daily_habits';

  static Database? _database;
  static final SqliteHelper instance = SqliteHelper._init();

  SqliteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_habitsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        target TEXT NOT NULL,
        is_done_today INTEGER DEFAULT 0,
        last_completed_date TEXT,
        streak INTEGER DEFAULT 0,
        history_dates TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old habits table if exists, create new daily_habits table
      await db.execute('DROP TABLE IF EXISTS habits');
      await _createDB(db, 2);
    }
  }

  // Insert new habit
  Future<int> insertHabit(DailyHabit habit) async {
    final db = await database;
    final map = habit.toMap();
    return await db.insert(_habitsTable, map);
  }

  // Get all habits
  Future<List<DailyHabit>> getAllHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_habitsTable);
    return List.generate(maps.length, (i) => DailyHabit.fromMap(maps[i]));
  }

  // Update habit
  Future<int> updateHabit(DailyHabit habit) async {
    final db = await database;
    final map = habit.toMap();
    return await db.update(
      _habitsTable,
      map,
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  // Delete habit
  Future<int> deleteHabit(String id) async {
    final db = await database;
    return await db.delete(_habitsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Delete all habits
  Future<int> deleteAllHabits() async {
    final db = await database;
    return await db.delete(_habitsTable);
  }

  // Get habits by date
  Future<List<DailyHabit>> getHabitsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      _habitsTable,
      where: 'last_completed_date = ?',
      whereArgs: [date],
    );
    return result.map((map) => DailyHabit.fromMap(map)).toList();
  }

  // Count total habits
  Future<int> getHabitsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_habitsTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
