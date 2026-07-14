import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/question_model.dart'; // আপনার প্রজেক্ট অনুযায়ী পাথ ঠিক করে নিবেন

void showQuestionFormSheet({
  required BuildContext context,
  required FirebaseFirestore firestore,
  required List<String> subjects,
  required Widget Function(String) buildMixedText, // HomeScreen এর buildMixedText মেথড পাস করার জন্য
  QuestionModel? model,
  String? docId,
}) {
  String selectedSubject = model?.subject ?? subjects.first;
  String selectedCls = model?.className ?? "Pre-Nursery";

  final quesController = TextEditingController(text: model?.question ?? "");
  final ansController = TextEditingController(text: model?.answer ?? "");

  final ValueNotifier<String> questionNotifier = ValueNotifier(quesController.text);
  final ValueNotifier<String> answerNotifier = ValueNotifier(ansController.text);

  bool isSaving = false;
  bool showPreview = true;

  quesController.addListener(() {
    questionNotifier.value = quesController.text;
  });
  ansController.addListener(() {
    answerNotifier.value = ansController.text;
  });

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        model == null ? "Add Question" : "Update Question",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedCls,
                        decoration: const InputDecoration(labelText: "Class"),
                        items: ["Pre-Nursery", "Nursery", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "No-Class"]
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c == "Pre-Nursery" || c == "Nursery" ? c : "Class $c"),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedCls = val!),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedSubject,
                        decoration: const InputDecoration(labelText: "Subject"),
                        items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedSubject = val!;
                          });
                        },
                      ),
                      TextField(
                        controller: quesController,
                        decoration: const InputDecoration(labelText: "Question"),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                        minLines: 3,
                      ),
                      if (selectedSubject == "Mathematics")
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Show Preview"),
                          value: showPreview,
                          onChanged: (value) {
                            setModalState(() {
                              showPreview = value;
                            });
                          },
                        ),
                      if (selectedSubject == "Mathematics" && showPreview) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Preview",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<String>(
                          valueListenable: questionNotifier,
                          builder: (context, text, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: text.isEmpty ? const Text("Start typing...") : buildMixedText(text),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: ansController,
                        decoration: const InputDecoration(labelText: "Answer"),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                        minLines: 3,
                      ),
                      if (selectedSubject == "Mathematics" && showPreview) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Answer Preview",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<String>(
                          valueListenable: answerNotifier,
                          builder: (context, text, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: text.isEmpty ? const Text("Start typing...") : buildMixedText(text),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() {
                              isSaving = true;
                            });

                            final data = QuestionModel(
                              subject: selectedSubject,
                              question: quesController.text.trim(),
                              answer: ansController.text.trim(),
                              className: selectedCls,
                            );

                            try {
                              if (model == null) {
                                await firestore.collection("questions").add({
                                  ...data.toMap(),
                                  "createdAt": Timestamp.now(),
                                });
                              } else {
                                await firestore.collection("questions").doc(docId).update(data.toMap());
                              }

                              Navigator.pop(modalContext); // modalContext ব্যবহার করা হয়েছে বন্ধ করার জন্য
                            } catch (e) {
                              // Error Handling
                            } finally {
                              setModalState(() {
                                isSaving = false;
                              });
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((_) {
    questionNotifier.dispose();
    answerNotifier.dispose();
  });
}