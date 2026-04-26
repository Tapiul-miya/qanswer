import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question_model.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), 'edu_tracker.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE questions(id INTEGER PRIMARY KEY AUTOINCREMENT, subject TEXT, question TEXT, answer TEXT)");
    });
  }

  Future<int> insert(QuestionModel question) async {
    var dbClient = await db;
    return await dbClient.insert('questions', question.toMap());
  }

  Future<List<QuestionModel>> getAllQuestions() async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query('questions', orderBy: "id DESC");
    return List.generate(maps.length, (i) => QuestionModel.fromMap(maps[i]));
  }

  Future<int> update(QuestionModel question) async {
    var dbClient = await db;
    return await dbClient.update('questions', question.toMap(), where: 'id = ?', whereArgs: [question.id]);
  }

  Future<int> delete(int id) async {
    var dbClient = await db;
    return await dbClient.delete('questions', where: 'id = ?', whereArgs: [id]);
  }
}
