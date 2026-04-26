import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_log.db');
    return await openDatabase(
      path,
      version: 3, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        type TEXT,
        distance REAL,
        steps INTEGER,
        calories REAL
      )
    ''');
    await _createPredictionsTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createPredictionsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE predictions ADD COLUMN diagnosis TEXT');
      await db.execute('ALTER TABLE predictions ADD COLUMN risk_level TEXT');
    }
  }

  Future _createPredictionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        outcome TEXT,
        probability TEXT,
        confidence TEXT,
        diagnosis TEXT,
        risk_level TEXT
      )
    ''');
  }

  // Logs Table Methods
  Future<int> insertLog(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('logs', row);
  }

  Future<List<Map<String, dynamic>>> queryAllLogs() async {
    Database db = await database;
    return await db.query('logs', orderBy: 'id DESC');
  }

  Future<int> deleteLog(int id) async {
    Database db = await database;
    return await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllLogs() async {
    Database db = await database;
    return await db.delete('logs');
  }

  // Predictions Table Methods
  Future<int> insertPrediction(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('predictions', row);
  }

  Future<List<Map<String, dynamic>>> queryAllPredictions() async {
    Database db = await database;
    return await db.query('predictions', orderBy: 'id DESC');
  }

  Future<int> deletePrediction(int id) async {
    Database db = await database;
    return await db.delete('predictions', where: 'id = ?', whereArgs: [id]);
  }
}
