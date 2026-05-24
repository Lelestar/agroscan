import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static Database? _db;
  static const _version = 2;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final basePath = await getDatabasesPath();
    final path = p.join(basePath, 'agroscan.db');
    _db = await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diagnostics (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        raw_label TEXT NOT NULL,
        confidence REAL NOT NULL,
        display_json TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE diagnostics_new (
          id TEXT PRIMARY KEY,
          image_path TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          raw_label TEXT NOT NULL,
          confidence REAL NOT NULL,
          display_json TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO diagnostics_new (
          id, image_path, created_at, raw_label, confidence, display_json
        )
        SELECT
          id, image_path, created_at, raw_label, confidence, display_json
        FROM diagnostics
      ''');
      await db.execute('DROP TABLE diagnostics');
      await db.execute('ALTER TABLE diagnostics_new RENAME TO diagnostics');
    }
  }
}
