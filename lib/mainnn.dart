import 'package:flutter/material.dart';
import 'models/question_model.dart';
import 'services/db_helper.dart';
import 'details_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DBHelper();

  List<QuestionModel> allQuestions = [];
  List<QuestionModel> filteredQuestions = [];

  final List<String> subjects = [
    "Math",
    "Science",
    "History",
    "English",
    "Physics"
  ];

  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  // 🔄 Refresh Data
  Future<void> _refreshList() async {
    final data = await dbHelper.getAllQuestions();
    setState(() {
      allQuestions = data;
      _applyFilter();
    });
  }

  // 🔍 Filter Logic
  void _applyFilter() {
    if (selectedFilter == "All") {
      filteredQuestions = allQuestions;
    } else {
      filteredQuestions = allQuestions
          .where((q) => q.subject == selectedFilter)
          .toList();
    }
  }

  // ➕ Add / Edit Form
  void _showForm(QuestionModel? model) {
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

                    final q = QuestionModel(
                      id: model?.id,
                      subject: selectedSubject,
                      question: quesController.text,
                      answer: ansController.text,
                    );

                    if (model == null) {
                      await dbHelper.insert(q);
                    } else {
                      await dbHelper.update(q);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _refreshList();
                    }
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
      // ✅ FIXED HERE
      appBar: AppBar(
        title: const Text("Education CRUD"),
        elevation: 0,

        actions: [
  IconButton(
    icon: const Icon(Icons.download),
    onPressed: () async {
      await dbHelper.exportDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Export Done")),
      );
    },
  ),
  IconButton(
    icon: const Icon(Icons.upload),
    onPressed: () async {
      bool success = await dbHelper.importDatabase();

      if (success) {
        _refreshList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restore Success!")),
        );
      }
    },
  ),
],
      ),

      body: Column(
        children: [
          // 🔹 FILTER CHIPS
          Container(
            height: 60,
            color: Colors.indigo.withOpacity(0.1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                String subj = filterOptions[index];
                bool isSelected = selectedFilter == subj;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(subj),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black),
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = subj;
                        _applyFilter();
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 🔹 LIST
          Expanded(
            child: filteredQuestions.isEmpty
                ? Center(
                    child: Text(
                        "No data found for '$selectedFilter'"),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, i) {
                      final item = filteredQuestions[i];



                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            item.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          subtitle: Text(
                            "Q: ${item.question}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(
                                  model: item,
                                  onEdit: (model) =>
                                      _showForm(model),
                                ),
                              ),
                            ).then((_) => _refreshList());
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                                
                                
                            onPressed: () async {
  bool? confirmDelete = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Delete"),
      content: const Text("Are you sure you want to delete this item?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirmDelete == true) {
    await dbHelper.delete(item.id!);
    _refreshList();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deleted Successfully")),
    );
  }
},
                            
                            
                          ),
                        ),
                      );
                      
                      
                      
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}