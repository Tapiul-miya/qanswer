import 'package:flutter/material.dart';
import 'models/question_model.dart';
import 'services/db_helper.dart';

void main() => runApp(MaterialApp(
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    ));

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dbHelper = DBHelper();
  List<QuestionModel> questions = [];
  final List<String> subjects = ["Math", "Science", "History", "English", "Physics"];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  _refreshList() async {
    List<QuestionModel> x = await dbHelper.getAllQuestions();
    setState(() => questions = x);
  }

  void _showForm(QuestionModel? model) {
    // Dropdown value track করার জন্য variable
    String? selectedSubject = model?.subject ?? subjects.first;
    final quesController = TextEditingController(text: model?.question);
    final ansController = TextEditingController(text: model?.answer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder( // UI আপডেট করার জন্য এটি দরকার
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(model == null ? "Add Entry" : "Update Entry", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                
                // --- DROPDOWN FIELD ---
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: InputDecoration(labelText: "Subject"),
                  items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setModalState(() => selectedSubject = val); // Modal UI refresh
                  },
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

                    // Database operation complete হওয়া পর্যন্ত অপেক্ষা করা
                    if (model == null) {
                      await dbHelper.insert(q);
                    } else {
                      await dbHelper.update(q);
                    }

                    if (mounted) {
                      Navigator.pop(context); // Modal বন্ধ হবে
                      _refreshList(); // Main UI refresh হবে
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
    return Scaffold(
      appBar: AppBar(title: Text("Education CRUD")),
      body: questions.isEmpty 
          ? Center(child: Text("No data found! Click + to add."))
          : ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, i) => Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(questions[i].subject, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  subtitle: Text("Q: ${questions[i].question}"),
                  onTap: () => _showDetails(questions[i]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await dbHelper.delete(questions[i].id!);
                      _refreshList();
                    },
                  ),
                ),
              ),
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
