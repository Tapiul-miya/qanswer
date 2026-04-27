import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'models/question_model.dart';

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

  // 🔤 FONT DATA
  String selectedFont = "Roboto";

  List<String> builtInFonts = [
    "Roboto",
    "Poppins",
    "Montserrat",
    "Lato",
    "OpenSans",
  ];

  List<String> customFonts = [];

  double fontSize = 15;

  // =========================
  // COPY TEXT
  // =========================
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  // =========================
  // ADD TTF FONT (FIXED)
  // =========================
  Future<void> addCustomFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);

    // unique font name
    final fontName = "CustomFont${DateTime.now().millisecondsSinceEpoch}";

    final fontBytes = await file.readAsBytes();

    // FIX: proper ByteData conversion
    final byteData = ByteData.sublistView(fontBytes);

    final loader = FontLoader(fontName);
    loader.addFont(Future.value(byteData));

    await loader.load();

    setState(() {
      customFonts.add(fontName);
      selectedFont = fontName;
    });
  }

  // =========================
  // BOX UI
  // =========================
  Widget _buildBox({
    required String title,
    required String content,
    required Color titleColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => _copyText(content),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),

            // 🔥 FIX: font applied correctly
            SelectableText(
              content,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: selectedFont,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final allFonts = [
      ...builtInFonts,
      ...customFonts,
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : Colors.white,

      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.indigo,
        title: const Text("Question Details"),
        actions: [
          Switch(
            value: isDark,
            onChanged: (val) {
              setState(() {
                isDark = val;
              });
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

            // =========================
            // FONT CONTROL
            // =========================
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [

                  // 🔤 FONT SELECT
                  Row(
                    children: [
                      const Text("Font: "),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedFont,
                          items: allFonts.map((font) {
                            return DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedFont = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔠 SIZE
                  Row(
                    children: [
                      const Text("Size: "),
                      Expanded(
                        child: Slider(
                          min: 12,
                          max: 30,
                          value: fontSize,
                          onChanged: (val) {
                            setState(() {
                              fontSize = val;
                            });
                          },
                        ),
                      ),
                      Text(fontSize.toInt().toString()),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ➕ ADD FONT
                  ElevatedButton(
                    onPressed: addCustomFont,
                    child: const Text("Add TTF Font"),
                  ),
                ],
              ),
            ),

            // =========================
            // SUBJECT
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.grey.shade800, Colors.black]
                      : [Colors.indigo, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.model.subject,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QUESTION
            _buildBox(
              title: "QUESTION",
              content: widget.model.question,
              titleColor: Colors.red,
              borderColor: Colors.redAccent,
            ),

            // ANSWER
            _buildBox(
              title: "ANSWER",
              content: widget.model.answer,
              titleColor: Colors.green,
              borderColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}