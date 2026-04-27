import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/question_model.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final firestore = FirebaseFirestore.instance;

  final List<String> subjects = [
    "Math",
    "Science",
    "History",
    "English",
    "Physics"
  ];

  String selectedFilter = "All";

  // ➕ Add / Edit Form
  void _showForm({QuestionModel? model, String? docId}) {
    String selectedSubject = model?.subject ?? subjects.first;

    final quesController =
        TextEditingController(text: model?.question ?? "");
    final ansController =
        TextEditingController(text: model?.answer ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model == null ? "Add Entry" : "Update Entry",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration:
                      const InputDecoration(labelText: "Subject"),
                  items: subjects
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedSubject = val!),
                ),

                TextField(
                  controller: quesController,
                  maxLines: null,
                  decoration:
                      const InputDecoration(labelText: "Question"),
                ),

                TextField(
                  controller: ansController,
                  maxLines: null,
                  decoration:
                      const InputDecoration(labelText: "Answer"),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (quesController.text.isEmpty ||
                        ansController.text.isEmpty) return;

                    if (model == null) {
                      // 🔥 INSERT
                      await firestore.collection("questions").add({
                        "subject": selectedSubject,
                        "question": quesController.text,
                        "answer": ansController.text,
                        "createdAt": Timestamp.now(),
                      });
                    } else {
                      // 🔥 UPDATE
                      await firestore
                          .collection("questions")
                          .doc(docId)
                          .update({
                        "subject": selectedSubject,
                        "question": quesController.text,
                        "answer": ansController.text,
                      });
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Save Data"),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = ["All", ...subjects];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase CRUD"),
      ),

      body: Column(
        children: [
          // 🔹 FILTER CHIPS
          Container(
            height: 60,
            color: Colors.indigo.withOpacity(0.1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                String subj = filterOptions[index];
                bool isSelected = selectedFilter == subj;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(subj),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = subj;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 🔥 FIRESTORE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedFilter == "All"
                  ? firestore
                      .collection("questions")
                      .orderBy("createdAt", descending: true)
                      .snapshots()
                  : firestore
                      .collection("questions")
                      .where("subject",
                          isEqualTo: selectedFilter)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No Data"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          data["subject"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        subtitle: Text(
                          "Q: ${data["question"]}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 👉 DETAILS PAGE
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsScreen(
                                model: QuestionModel(
                                  id: data.id,
                                  subject: data["subject"],
                                  question: data["question"],
                                  answer: data["answer"],
                                ),
                                onEdit: (model) => _showForm(
                                  model: model,
                                  docId: data.id,
                                ),
                              ),
                            ),
                          );
                        },

                        // ❌ DELETE WITH CONFIRM
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                title:
                                    const Text("Confirm Delete"),
                                content: const Text(
                                    "Are you sure?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            context, false),
                                    child:
                                        const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(
                                            context, true),
                                    child:
                                        const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await firestore
                                  .collection("questions")
                                  .doc(data.id)
                                  .delete();
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ ADD BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}