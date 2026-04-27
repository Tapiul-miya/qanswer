import 'package:flutter/material.dart';
import 'models/question_model.dart';

class DetailsScreen extends StatelessWidget {
  final QuestionModel model;
  final Function(QuestionModel) onEdit;

  const DetailsScreen({
    super.key,
    required this.model,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📘 SUBJECT
            Text(
              model.subject,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 20),

            // ❓ QUESTION
            const Text(
              "Question:",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              model.question,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // ✅ ANSWER
            const Text(
              "Answer:",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              model.answer,
              style: const TextStyle(fontSize: 16),
            ),

            const Spacer(),

            // ✏️ EDIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onEdit(model); // HomeScreen-এর form open হবে
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}