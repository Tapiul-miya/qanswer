import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FontDB {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'fonts.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fonts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            path TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> insertFont(String name, String path) async {
    final d = await db;
    await d.insert('fonts', {
      'name': name,
      'path': path,
    });
  }

  Future<List<Map<String, dynamic>>> getFonts() async {
    final d = await db;
    return await d.query('fonts');
  }
}