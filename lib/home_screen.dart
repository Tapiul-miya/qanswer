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
  "Bangla",
  "English",
  "Hindi",
  "Mathematics",
  "General Knowledge",
  "Science",
  "Physical Science",
  "Life Science",
  "Physics",
  "Chemistry",
  "Biology",
  "History",
  "Geography",
  "Civics",
  "Computer",
  "Environmental Studies"
];

  String selectedFilter = "All";
  String selectedClass = "1";

  Color getSubjectColor(String subject) {
  switch (subject) {
    case "Bangla":
      return Colors.red;

    case "English":
      return Colors.purple;
      
    case "Hindi":
      return Colors.deepPurple;

    case "Mathematics":
      return Colors.blue;

    case "General Knowledge":
      return Colors.amber;

    case "Science":
      return Colors.green;

    case "Physical Science":
    case "Physics":
      return Colors.orange;

    case "Chemistry":
      return Colors.deepOrange;

    case "Life Science":
    case "Biology":
      return Colors.lightGreen;

    case "History":
      return Colors.brown;

    case "Geography":
      return Colors.indigo;

    case "Civics":
      return Colors.cyan;

    case "Computer":
      return Colors.grey;

    default:
      return Colors.blueGrey;
  }
}

  Stream<QuerySnapshot> getQuestionStream() {
    if (selectedFilter == "All") {
      return firestore
          .collection("questions")
          .where("class", isEqualTo: selectedClass)
          .snapshots();
    } else {
      return firestore
          .collection("questions")
          .where("class", isEqualTo: selectedClass)
          .where("subject", isEqualTo: selectedFilter)
          .snapshots();
    }
  }

  void _showForm({QuestionModel? model, String? docId}) {
    String selectedSubject = model?.subject ?? subjects.first;
    String selectedCls = model?.className ?? "1";

    final quesController =
        TextEditingController(text: model?.question ?? "");
    final ansController =
        TextEditingController(text: model?.answer ?? "");

    bool isSaving = false;

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
              children: [
                Text(
                  model == null ? "Add Question" : "Update Question",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selectedCls,
                  decoration: const InputDecoration(labelText: "Class"),
                  items: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text("Class $c")))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedCls = val!),
                ),

                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(labelText: "Subject"),
                  items: subjects
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedSubject = val!),
                ),

                TextField(
                  controller: quesController,
                  decoration:
                      const InputDecoration(labelText: "Question"),
                ),

                TextField(
                  controller: ansController,
                  decoration:
                      const InputDecoration(labelText: "Answer"),
                ),

                const SizedBox(height: 15),

                ElevatedButton(
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
                              await firestore
                                  .collection("questions")
                                  .add({
                                ...data.toMap(),
                                "createdAt": Timestamp.now(),
                              });
                            } else {
                              await firestore
                                  .collection("questions")
                                  .doc(docId)
                                  .update(data.toMap());
                            }

                            if (mounted) {
                              Navigator.pop(context);
                            }
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
                )
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
        title: Text("Class $selectedClass"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedClass = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '1', child: Text('Class 1')),
              PopupMenuItem(value: '2', child: Text('Class 2')),
              PopupMenuItem(value: '3', child: Text('Class 3')),
              PopupMenuItem(value: '4', child: Text('Class 4')),
              PopupMenuItem(value: '5', child: Text('Class 5')),
              PopupMenuItem(value: '6', child: Text('Class 6')),
              PopupMenuItem(value: '7', child: Text('Class 7')),
              PopupMenuItem(value: '8', child: Text('Class 8')),
              PopupMenuItem(value: '9', child: Text('Class 9')),
              PopupMenuItem(value: '10', child: Text('Class 10')),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final subj = filterOptions[index];
                final isSelected = selectedFilter == subj;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(subj),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
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

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getQuestionStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No Data"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final model = QuestionModel.fromMap(
                      docs[i].data() as Map<String, dynamic>,
                      docs[i].id,
                    );

                    final color = getSubjectColor(model.subject);

                    return GestureDetector(
                      onLongPress: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text(
                                "Are you sure you want to delete this question?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await firestore
                              .collection("questions")
                              .doc(model.id)
                              .delete();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Deleted successfully")),
                            );
                          }
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                color.withOpacity(0.1)
                              ],
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              "Class ${model.className} • ${model.subject}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Q: ${model.question}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(
                                    model: model,
                                    onEdit: (m) => _showForm(
                                        model: m, docId: model.id),
                                  ),
                                ),
                              );
                            },
                          ),
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}