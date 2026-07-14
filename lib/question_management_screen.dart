import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'models/question_model.dart';
import 'details_screen.dart';
import 'question_form_sheet.dart'; 

class QuestionManagementScreen extends StatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  bool isRefreshing = false;

  final List<String> subjects = [
    "No Subject", "Bangla", "English", "Hindi", "Mathematics", 
    "General Knowledge", "Science", "Physical Science", "Life Science", 
    "Physics", "Chemistry", "Biology", "History", "Geography", 
    "Civics", "Computer", "Environmental Studies", "Religious Studies"
  ];

  String selectedFilter = "All";
  String selectedClass = "Nursery";

  Color getSubjectColor(String subject) {
    switch (subject) {
      case "Bangla": return Colors.red;
      case "English": return Colors.purple;
      case "Hindi": return Colors.deepPurple;
      case "Mathematics": return Colors.blue;
      case "General Knowledge": return Colors.amber;
      case "Science": return Colors.green;
      case "Physical Science":
      case "Physics": return Colors.orange;
      case "Chemistry": return Colors.deepOrange;
      case "Life Science":
      case "Biology": return Colors.lightGreen;
      case "History": return Colors.brown;
      case "Geography": return Colors.indigo;
      case "Civics": return Colors.cyan;
      case "Computer": return Colors.grey;
      default: return Colors.blueGrey;
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

  Future<bool> _verifyPassword() async {
    final passwordController = TextEditingController();

    final enteredPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Password Required"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Enter Password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, passwordController.text.trim());
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (enteredPassword == null) return false;

    try {
      final passwordDoc = await firestore
          .collection("settings")
          .doc("delete_password")
          .get();

      if (!passwordDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password not found")),
          );
        }
        return false;
      }

      final savedPassword = passwordDoc["password"].toString();

      if (enteredPassword != savedPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Wrong Password")),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      return false;
    }
  }

  Widget buildMixedText(String text) {
    if (!text.contains(r'\(') && !text.contains(r'\[')) {
      return SelectableText(
        text,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }

    final regex = RegExp(r'\\\((.*?)\\\)|\\\[(.*?)\\\]', dotAll: true);
    final matches = regex.allMatches(text);
    List<InlineSpan> spans = [];
    int last = 0;

    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ));
      }

      final latex = match.group(1) ?? match.group(2)!;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(
          latex,
          mathStyle: MathStyle.display,
          textStyle: const TextStyle(color: Colors.red, fontSize: 18),
        ),
      ));

      last = match.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = ["All", ...subjects];

    return Scaffold(
      backgroundColor: Colors.transparent, // ড্যাশবোর্ডের ব্যাকগ্রাউন্ড ব্যবহার করার জন্য
      appBar: AppBar(
        // অ্যাপবারের টাইটেল সুন্দর ও স্পষ্ট করা হয়েছে এবং ক্লাস ও সাবজেক্ট ফিল্টার রিয়েল-টাইমে দেখাবে
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Question Bank",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                fontSize: 20,
              ),
            ),
            Text(
              "Class: $selectedClass • Subject: $selectedFilter",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.indigo.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.indigo),
                  onPressed: () async {
                    setState(() { isRefreshing = true; });
                    try {
                      await firestore
                          .collection("questions")
                          .get(const GetOptions(source: Source.server));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Data refreshed")),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Internet slow or unavailable")),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() { isRefreshing = false; });
                      }
                    }
                  },
                ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.indigo),
            onSelected: (value) {
              setState(() { selectedClass = value; });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Pre-Nursery', child: Text('Pre-Nursery')),
              PopupMenuItem(value: 'Nursery', child: Text('Nursery')),
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
              PopupMenuItem(value: 'No-Class', child: Text('No-Class')),
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
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (_) {
                      setState(() { selectedFilter = subj; });
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
                        final action = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text("Edit"),
                                  onTap: () => Navigator.pop(context, "edit"),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  onTap: () => Navigator.pop(context, "delete"),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (action == "edit") {
                          if (await _verifyPassword()) {
                            showQuestionFormSheet(
                              context: context,
                              firestore: firestore,
                              subjects: subjects,
                              buildMixedText: buildMixedText,
                              model: model,
                              docId: model.id,
                            );
                          }
                          return;
                        }

                        if (action != "delete") return;

                        if (!await _verifyPassword()) return;

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text("Are you sure you want to delete this question?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await firestore.collection("questions").doc(model.id).delete();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Deleted successfully")),
                            );
                          }
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.white, color.withOpacity(0.1)],
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              "Class ${model.className} • ${model.subject}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: color),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: model.subject == "Mathematics"
                                  ? buildMixedText(model.question)
                                  : Text(
                                      "Q: ${model.question}",
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsScreen(
                                    model: model,
                                    onEdit: (m) => showQuestionFormSheet(
                                      context: context,
                                      firestore: firestore,
                                      subjects: subjects,
                                      buildMixedText: buildMixedText,
                                      model: m,
                                      docId: model.id,
                                    ),
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
        onPressed: () async {
          if (await _verifyPassword()) {
            showQuestionFormSheet(
              context: context,
              firestore: firestore,
              subjects: subjects,
              buildMixedText: buildMixedText,
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}