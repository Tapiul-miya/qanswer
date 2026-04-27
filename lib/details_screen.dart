import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/question_model.dart';
import 'font_db.dart';

class DetailsScreen extends StatefulWidget {
  final QuestionModel model;
  final Function(QuestionModel) onEdit;

  const DetailsScreen({
    super.key,
    required this.model,
    required this.onEdit,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool isDark = false;
  String selectedFont = "default";
  double fontSize = 15;

  final List<String> customFonts = [];
  final FontDB fontDB = FontDB();

  // ================= SNACKBAR =================
  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ================= SAVE SETTINGS =================
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', selectedFont);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('isDark', isDark);
  }

  // ================= LOAD SETTINGS =================
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedFont = prefs.getString('selectedFont') ?? "default";
      fontSize = prefs.getDouble('fontSize') ?? 15;
      isDark = prefs.getBool('isDark') ?? false;
    });
  }

  // ================= COPY =================
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showMsg("Copied");
  }

  // ================= LOAD FONTS FROM DB =================
  Future<void> loadFontsFromDB() async {
    final fonts = await fontDB.getFonts();

    for (var f in fonts) {
      final name = f['name'];
      final path = f['path'];

      final file = File(path);

      if (await file.exists()) {
        final loader = FontLoader(name);
        loader.addFont(file.readAsBytes().then(ByteData.sublistView));
        await loader.load();

        customFonts.add(name);
      }
    }

    setState(() {});
  }

  // ================= ADD FONT =================
  Future<void> addCustomFont() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();

      final fontName =
          "CustomFont_${DateTime.now().millisecondsSinceEpoch}";

      final filePath = "${dir.path}/$fontName.ttf";

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await fontDB.insertFont(fontName, filePath);

      final loader = FontLoader(fontName);
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
      await loader.load();

      setState(() {
        customFonts.add(fontName);
        selectedFont = fontName;
      });

      await saveSettings();

      showMsg("Font added successfully");
    } catch (e) {
      showMsg("Font load failed");
    }
  }

  @override
  void initState() {
    super.initState();
    loadFontsFromDB();
    loadSettings();
  }

  // ================= BOX UI =================
  Widget buildBox({
    required String title,
    required String content,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => copyText(content),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              content,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily:
                    selectedFont == "default" ? null : selectedFont,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allFonts = ["default", ...customFonts];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,

      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.indigo,
        title: const Text("Question Details"),
        actions: [
          Switch(
            value: isDark,
            onChanged: (v) {
              setState(() => isDark = v);
              saveSettings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => widget.onEdit(widget.model),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= FONT PANEL =================
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selectedFont,
                    items: allFonts
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedFont = val);
                        saveSettings();
                        showMsg("Font changed");
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text("Size"),
                      Expanded(
                        child: Slider(
                          min: 12,
                          max: 30,
                          value: fontSize,
                          onChanged: (v) {
                            setState(() => fontSize = v);
                            saveSettings();
                          },
                        ),
                      ),
                      Text(fontSize.toInt().toString()),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: addCustomFont,
                    child: const Text("Add Font"),
                  ),
                ],
              ),
            ),

            // ================= SUBJECT =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey, Colors.black]
                      : [Colors.indigo, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.model.subject,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            buildBox(
              title: "QUESTION",
              content: widget.model.question,
              color: Colors.red,
            ),

            buildBox(
              title: "ANSWER",
              content: widget.model.answer,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}