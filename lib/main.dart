import 'package:flutter/material.dart';
import 'models/question_model.dart';
import 'services/db_helper.dart';
import 'details_screen.dart'; // আলাদা ফাইলটি ইমপোর্ট করা হয়েছে

void main() => runApp(MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false, // UI স্টাইল ঠিক রাখার জন্য
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    ));

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DBHelper();
  List<QuestionModel> allQuestions = []; // মেইন ডাটাবেস লিস্ট
  List<QuestionModel> filteredQuestions = []; // ফিল্টার করা লিস্ট
  
  final List<String> subjects = ["Math", "Science", "History", "English", "Physics"];
  String selectedFilter = "All"; // বর্তমান ফিল্টার ট্র্যাক করার জন্য

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  // ডাটাবেস থেকে ডাটা রিফ্রেশ করা
  _refreshList() async {
    List<QuestionModel> data = await dbHelper.getAllQuestions();
    setState(() {
      allQuestions = data;
      _applyFilter(); // ডাটা আসার পর ফিল্টার অ্যাপ্লাই করা
    });
  }

  // ফিল্টারিং লজিক
  void _applyFilter() {
    setState(() {
      if (selectedFilter == "All") {
        filteredQuestions = allQuestions;
      } else {
        filteredQuestions = allQuestions.where((q) => q.subject == selectedFilter).toList();
      }
    });
  }

  // ডাটা অ্যাড বা এডিট করার ফর্ম (Modal Bottom Sheet)
  void _showForm(QuestionModel? model) {
    String? selectedSubject = model?.subject ?? subjects.first;
    final quesController = TextEditingController(text: model?.question);
    final ansController = TextEditingController(text: model?.answer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(model == null ? "Add Entry" : "Update Entry", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(labelText: "Subject"),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setModalState(() => selectedSubject = val),
                ),

                TextField(controller: quesController, maxLines: null, decoration: const InputDecoration(labelText: "Question")),
                TextField(controller: ansController, maxLines: null, decoration: const InputDecoration(labelText: "Answer")),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () async {
                    if (quesController.text.isEmpty || ansController.text.isEmpty) return;

                    final q = QuestionModel(
                      id: model?.id,
                      subject: selectedSubject!,
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
    List<String> filterOptions = ["All", ...subjects];

    return Scaffold(
    
    
   // AppBar-এ বাটন যোগ করা
    
      appBar: AppBar(
      title: const Text("Education CRUD"), elevation: 0),
      
      actions: [
    IconButton(
      icon: const Icon(Icons.download), // এক্সপোর্ট
      onPressed: () async {
        String? msg = await dbHelper.exportDatabase();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? "Failed")));
      },
    ),
    IconButton(
      icon: const Icon(Icons.upload), // ইমপোর্ট
      onPressed: () async {
        bool success = await dbHelper.importDatabase();
        if (success) {
          _refreshList(); // ডাটা রিস্টোর হলে লিস্ট আপডেট করুন
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restore Success!")));
        }
      },
    ),
  ],
      
       body: Column(
        children: [
          // --- সাবজেক্ট ফিল্টার লিস্ট ---
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
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(subj),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (selected) {
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

          // --- প্রশ্ন ও উত্তরের লিস্ট ---
          Expanded(
            child: filteredQuestions.isEmpty 
                ? Center(child: Text("No data found for '$selectedFilter'"))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, i) => Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(filteredQuestions[i].subject, 
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        subtitle: Text("Q: ${filteredQuestions[i].question}", maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          // লিস্টে ক্লিক করলে নতুন স্ক্রিনে নিয়ে যাবে
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(
                                model: filteredQuestions[i],
                                onEdit: (model) => _showForm(model),
                              ),
                            ),
                          ).then((_) => _refreshList()); // ফিরে আসার পর লিস্ট আপডেট হবে
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await dbHelper.delete(filteredQuestions[i].id!);
                            _refreshList();
                          },
                        ),
                      ),
                    ),
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
