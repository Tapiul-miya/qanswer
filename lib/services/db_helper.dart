import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/question_model.dart';

class DBHelper {
  static Database? _db;
  final String dbName = 'edu_tracker.db';

  // =========================
  // DB INSTANCE
  // =========================
  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // =========================
  // INIT DB
  // =========================
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT,
            question TEXT,
            answer TEXT
          )
        ''');
      },
    );
  }

  // =========================
  // CRUD OPERATIONS
  // =========================

  Future<int> insert(QuestionModel question) async {
    final dbClient = await db;
    return dbClient.insert('questions', question.toMap());
  }

  Future<List<QuestionModel>> getAllQuestions() async {
    final dbClient = await db;

    final maps =
        await dbClient.query('questions', orderBy: "id DESC");

    return maps
        .map((e) => QuestionModel.fromMap(e))
        .toList();
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
  // EXPORT DATABASE
  // =========================
  Future<void> exportDatabase() async {
    try {
      if (kIsWeb) {
        debugPrint("Export not supported on Web");
        return;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      final file = File(path);

      if (!await file.exists()) {
        debugPrint("Database file not found!");
        return;
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Education Backup File',
      );
    } catch (e) {
      debugPrint("Export Error: $e");
    }
  }

  // =========================
  // IMPORT DATABASE
  // =========================
  Future<bool> importDatabase() async {
    try {
      if (kIsWeb) {
        debugPrint("Import not supported on Web");
        return false;
      }

      // ✅ FIXED HERE
      
         FilePickerResult? result =
    await FilePicker().pickFiles();

      if (result == null) return false;

      final file = result.files.first;

      if (file.path == null) return false;

      final backupFile = File(file.path!);

      if (!await backupFile.exists()) {
        debugPrint("Selected file not found!");
        return false;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, dbName);

      // Close existing DB
      if (_db != null) {
        await _db!.close();
        _db = null;
      }

      // Replace DB
      await backupFile.copy(path);

      // Re-open DB
      await db;

      return true;
    } catch (e) {
      debugPrint("Import Error: $e");
      return false;
    }
  }
}