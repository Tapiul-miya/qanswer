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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pop(context);
              onEdit(model);
            },
          )
        ],
      ),
      body: LayoutBuilder( // এটি পুরো স্ক্রিনের উচ্চতা নিশ্চিত করবে
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight, // পুরো স্ক্রিনের হাইট নিবে
              ),
              child: Container(
                width: double.infinity,
                color: Colors.white, // ব্যাকগ্রাউন্ড সাদা
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // সাবজেক্ট ট্যাগ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        model.subject,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // প্রশ্ন সেকশন
                    const Text(
                      "QUESTION",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      model.question,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(thickness: 1),
                    ),

                    // উত্তর সেকশন
                    const Text(
                      "ANSWER",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      model.answer,
                      style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                    ),
                    
                    const SizedBox(height: 50), // নিচে কিছু অতিরিক্ত জায়গা
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
