import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart'; // ফাইল শেয়ার/সেভ করার জন্য
import 'package:file_picker/file_picker.dart'; // ফাইল সিলেক্ট করার জন্য
import '../models/question_model.dart';

class DBHelper {
  static Database? _db;
  final String dbName = 'edu_tracker.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE questions(id INTEGER PRIMARY KEY AUTOINCREMENT, subject TEXT, question TEXT, answer TEXT)");
    });
  }

  // --- ডাটা ইনসার্ট, রিড, আপডেট, ডিলিট ---
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

  // --- ১. ডাটাবেস এক্সপোর্ট (Backup) ---
  Future<void> exportDatabase() async {
    try {
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, dbName);
      
      // ফাইলটি শেয়ার অপশনে পাঠানো (যাতে ইউজার গুগল ড্রাইভ বা ফোনে সেভ করতে পারে)
      await Share.shareXFiles([XFile(path)], text: 'My Education Database Backup');
    } catch (e) {
      print("Export Error: $e");
    }
  }

  // --- ২. ডাটাবেস ইমপোর্ট (Restore) ---
  Future<bool> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        File backupFile = File(result.files.single.path!);
        String databasesPath = await getDatabasesPath();
        String path = join(databasesPath, dbName);

        // বর্তমান ডাটাবেস কানেকশন ক্লোজ করা
        if (_db != null) {
          await _db!.close();
          _db = null;
        }

        // নতুন ফাইল দিয়ে রিপ্লেস করা
        await backupFile.copy(path);
        
        // পুনরায় ডাটাবেস ওপেন করা
        await db; 
        return true;
      }
    } catch (e) {
      print("Import Error: $e");
    }
    return false;
  }
}
