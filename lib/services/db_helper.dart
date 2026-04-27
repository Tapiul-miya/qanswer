import 'dart:io' show File; // শুধু Android এর জন্য
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/question_model.dart';

class DBHelper {
  static Database? _db;
  final String dbName = 'edu_tracker.db';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE questions(id INTEGER PRIMARY KEY AUTOINCREMENT, subject TEXT, question TEXT, answer TEXT)",
        );
      },
    );
  }

  // CRUD
  Future<int> insert(QuestionModel question) async {
    final dbClient = await db;
    return dbClient.insert('questions', question.toMap());
  }

  Future<List<QuestionModel>> getAllQuestions() async {
    final dbClient = await db;
    final maps =
        await dbClient.query('questions', orderBy: "id DESC");

    return List.generate(
      maps.length,
      (i) => QuestionModel.fromMap(maps[i]),
    );
  }

  Future<int> update(QuestionModel question) async {
    final dbClient = await db;
    return dbClient.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> delete(int id) async {
    final dbClient = await db;
    return dbClient.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // ✅ EXPORT (Backup)
  // =========================
  Future<void> exportDatabase() async {
    try {
      if (kIsWeb) {
        print("Export not supported on Web properly");
        return;
      }

      String dbPath = await getDatabasesPath();
      String path = join(dbPath, dbName);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Education DB Backup',
      );
    } catch (e) {
      print("Export Error: $e");
    }
  }

  // =========================
  // ✅ IMPORT (Restore)
  // =========================
  Future<bool> importDatabase() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles();

      if (result == null) return false;

      final file = result.files.first;

      // ❌ Web case
      if (kIsWeb) {
        print("Import not supported on Web");
        return false;
      }

      // ✅ Android / Desktop
      if (file.path != null) {
        File backupFile = File(file.path!);

        String dbPath = await getDatabasesPath();
        String path = join(dbPath, dbName);

        // Close old DB
        if (_db != null) {
          await _db!.close();
          _db = null;
        }

        await backupFile.copy(path);

        await db; // reopen
        return true;
      }
    } catch (e) {
      print("Import Error: $e");
    }

    return false;
  }
}