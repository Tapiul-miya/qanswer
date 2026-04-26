import 'package:flutter/material.dart';
import 'models/question_model.dart';
import 'services/db_helper.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: false),
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

  void _showForm(QuestionModel? model) {
    String? selectedSubject = model?.subject ?? subjects.first;
    final quesController = TextEditingController(text: model?.question);
    final ansController = TextEditingController(text: model?.answer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(model == null ? "Add Entry" : "Update Entry", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: InputDecoration(labelText: "Subject"),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setModalState(() => selectedSubject = val),
                ),

                TextField(controller: quesController, maxLines: null, decoration: InputDecoration(labelText: "Question")),
                TextField(controller: ansController, maxLines: null, decoration: InputDecoration(labelText: "Answer")),
                SizedBox(height: 20),
                
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
                  child: Text("Save Data"),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ফিল্টার অপশনে "All" যোগ করা
    List<String> filterOptions = ["All", ...subjects];

    return Scaffold(
      appBar: AppBar(title: Text("Education CRUD"), elevation: 0),
      body: Column(
        children: [
          // --- HORIZONTAL SUBJECT FILTER ---
          Container(
            height: 60,
            color: Colors.indigo.withOpacity(0.1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 10),
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

          // --- QUESTIONS LIST ---
          Expanded(
            child: filteredQuestions.isEmpty 
                ? Center(child: Text("No data found for '$selectedFilter'"))
                : ListView.builder(
                    padding: EdgeInsets.only(top: 10),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, i) => Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(filteredQuestions[i].subject, 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        subtitle: Text("Q: ${filteredQuestions[i].question}", maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => _showDetails(filteredQuestions[i]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
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
        child: Icon(Icons.add),
      ),
    );
  }

  void _showDetails(QuestionModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(model.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Question:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(model.question),
              Divider(),
              Text("Answer:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(model.answer),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Close")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _showForm(model); }, child: Text("Edit")),
        ],
      ),
    );
  }
}
