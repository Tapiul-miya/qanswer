import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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

  void showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', selectedFont);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('isDark', isDark);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedFont = prefs.getString('selectedFont') ?? "default";
      fontSize = prefs.getDouble('fontSize') ?? 15;
      isDark = prefs.getBool('isDark') ?? false;
    });
  }

  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    showMsg("Copied");
  }

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

        if (!customFonts.contains(name)) {
          customFonts.add(name);
        }
      }
    }

    setState(() {});
  }

  Future<void> addCustomFont() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      final fileName = file.name.trim().toLowerCase();

      if (bytes == null) return;

      final existingFonts = await fontDB.getFonts();

      final isDuplicate = existingFonts.any((f) =>
          f['name'].toString().trim().toLowerCase() == fileName);

      if (isDuplicate || customFonts.contains(fileName)) {
        showMsg("Font already exists");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final fontId = "font_${DateTime.now().millisecondsSinceEpoch}";
      final filePath = "${dir.path}/$fontId.ttf";

      final savedFile = File(filePath);
      await savedFile.writeAsBytes(bytes);

      await fontDB.insertFont(fileName, filePath);

      final loader = FontLoader(fileName);
      loader.addFont(savedFile.readAsBytes().then(ByteData.sublistView));
      await loader.load();

      setState(() {
        customFonts.add(fileName);
        selectedFont = fileName;
      });

      await saveSettings();
      showMsg("Font added");
    } catch (e) {
      showMsg("Font load failed");
    }
  }

  void showFontPreview(String fontName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.black : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "The quick brown fox jumps over the lazy dog\n0123456789",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: fontName == "default" ? null : fontName,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  setState(() => selectedFont = fontName);
                  saveSettings();
                  Navigator.pop(context);
                  showMsg("Font applied");
                },
                child: const Text("Use This Font"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    loadFontsFromDB();
    loadSettings();
  }


   Widget buildMixedText(String text) {
  // যদি কোনো LaTeX না থাকে তাহলে সাধারণ Text দেখাও
  if (!text.contains(r'\(')) {
    return SelectableText(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: selectedFont == "default" ? null : selectedFont,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  final regex = RegExp(r'\\\((.*?)\\\)', dotAll: true);
  final matches = regex.allMatches(text);

  List<InlineSpan> spans = [];
  int last = 0;

  for (final match in matches) {
    // Math-এর আগের Text
    if (match.start > last) {
      spans.add(
        TextSpan(
          text: text.substring(last, match.start),
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: selectedFont == "default" ? null : selectedFont,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      );
    }

    // Math অংশ
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          match.group(1)!,
          textStyle: TextStyle(
            fontSize: fontSize,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );

    last = match.end;
  }

  // শেষের Text
  if (last < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(last),
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: selectedFont == "default" ? null : selectedFont,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  return SelectableText.rich(
    TextSpan(children: spans),
  );
}





  Widget buildBox({
    required String title,
    required String content,
    required Color color,
    Widget? extraWidget,
  }) {
    return GestureDetector(
      onTap: () => copyText(content),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            
            widget.model.subject == "Mathematics"
    ? buildMixedText(content)
    : SelectableText(
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
        title: Text(widget.model.subject), // ✅ SUBJECT HERE
        actions: [
          Switch(
            value: isDark,
            onChanged: (v) {
              setState(() => isDark = v);
              saveSettings();
            },
          ),
          
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "add_font") {
                addCustomFont();
              } else if (value.startsWith("font_")) {
                final fontName = value.replaceFirst("font_", "");
                setState(() => selectedFont = fontName);
                saveSettings();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: "add_font",
                  child: Text("➕ Add Font"),
                ),
                const PopupMenuDivider(),
                ...allFonts.map((f) {
                  return PopupMenuItem(
                    value: "font_$f",
                    child: Text(f),
                  );
                }).toList(),
              ];
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 80),
          child: Column(
            children: [
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
      ),

      bottomNavigationBar: Container(
        height: 60,
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: Row(
          children: [
            const Text("Size", style: TextStyle(fontSize: 12)),
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
      ),
    );
  }
}