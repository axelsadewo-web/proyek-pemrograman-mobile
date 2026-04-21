import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habbits.dart';

class DBHelper {
  static const String _databaseName = 'habits.db';
  static const String _tableName = 'habits';
  static const String _columnId = 'id';
  static const String _columnTitle = 'title';
  static const String _columnDate = 'date';
  static const String _columnIsDone = 'isDone';

  static Database? _database;

  static final DBHelper instance = DBHelper._init();

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE $_tableName (
  $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
  $_columnTitle TEXT NOT NULL,
  $_columnDate TEXT NOT NULL,
  $_columnIsDone INTEGER NOT NULL DEFAULT 0
)
''');
  }

  // Insert habit
  Future<int> insertHabit(Habit habit) async {
    final db = await instance.database;
    return await db.insert(_tableName, habit.toMap());
  }

  // Get all habits
  Future<List<Habit>> getHabits() async {
    final db = await instance.database;
    final result = await db.query(_tableName);
    return result.map((map) => Habit.fromMap(map)).toList();
  }

  // Update habit
  Future<int> updateHabit(Habit habit) async {
    final db = await instance.database;
    return await db.update(
      _tableName,
      habit.toMap(),
      where: '$_columnId = ?',
      whereArgs: [habit.id],
    );
  }

  // Delete habit
  Future<int> deleteHabit(int id) async {
    final db = await instance.database;
    return await db.delete(
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete all habits
  Future<int> deleteAllHabits() async {
    final db = await instance.database;
    return await db.delete(_tableName);
  }

  // Get habits by date
  Future<List<Habit>> getHabitsByDate(String date) async {
    final db = await instance.database;
    final result = await db.query(
      _tableName,
      where: '$_columnDate = ?',
      whereArgs: [date],
    );
    return result.map((map) => Habit.fromMap(map)).toList();
  }
}
