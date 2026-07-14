import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // ফর্ম কন্ট্রোলার সমূহ
  final nameController = TextEditingController();
  final guardianNameController = TextEditingController(); 
  final rollController = TextEditingController();
  final phoneController = TextEditingController();
  
  // কলাম ভিত্তিক সার্চ ও ফিল্টারিং ভ্যারিয়েবলস
  final nameSearchController = TextEditingController(); // শুধুমাত্র নাম দিয়ে সাধারণ সার্চের জন্য
  
  String searchNameQuery = "";
  String filterRoll = "All";
  String filterClass = "All";
  String filterSection = "All";
  String filterGender = "All";
  String filterGuardian = "All";
  String filterPhone = "All";

  String selectedClass = "1";
  String selectedSection = "A"; 
  String selectedGender = "Boy";
  bool isSaving = false;

  final List<String> classes = ["Pre-Nursery", "Nursery", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"];
  final List<String> sections = ["A", "B", "C", "D", "E", "F", "G", "H"]; 

  @override
  void dispose() {
    nameController.dispose();
    guardianNameController.dispose();
    rollController.dispose();
    phoneController.dispose();
    nameSearchController.dispose();
    super.dispose();
  }

  // সব ফিল্টার রিসেট করার ফাংশন
  void _resetAllFilters() {
    setState(() {
      nameSearchController.clear();
      searchNameQuery = "";
      filterRoll = "All";
      filterClass = "All";
      filterSection = "All";
      filterGender = "All";
      filterGuardian = "All";
      filterPhone = "All";
    });
  }

  // ডাইনামিক সার্চেবল ফিল্টার ডায়ালগ (টাইপ করে কলাম ফিল্টার করার জন্য)
  void _showSearchableFilter({
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        List<String> filterList = ["All", ...options];
        List<String> tempSearchList = List.from(filterList);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Select $title", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Search $title...",
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          tempSearchList = filterList
                              .where((element) => element.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempSearchList.length,
                        itemBuilder: (context, idx) {
                          final item = tempSearchList[idx];
                          return ListTile(
                            title: Text(item == "All" ? "All $title" : item),
                            trailing: currentValue == item ? const Icon(Icons.check, color: Colors.indigo) : null,
                            onTap: () {
                              onSelected(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // শিক্ষার্থী যোগ বা এডিট করার জন্য বটম শিট ফর্ম
  void _showStudentForm({String? docId, Map<String, dynamic>? studentData}) {
    if (studentData != null) {
      nameController.text = studentData['name'] ?? '';
      guardianNameController.text = studentData['guardianName'] ?? ''; 
      rollController.text = studentData['roll'] ?? '';
      phoneController.text = studentData['phone'] ?? '';
      selectedClass = studentData['class'] ?? '1';
      selectedSection = studentData['section'] ?? 'A'; 
      selectedGender = studentData['gender'] ?? 'Boy';
    } else {
      nameController.clear();
      guardianNameController.clear(); 
      rollController.clear();
      phoneController.clear();
      selectedClass = "1";
      selectedSection = "A"; 
      selectedGender = "Boy";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docId == null ? "Add New Student" : "Update Student Info",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Student Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter student name" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: guardianNameController,
                    decoration: const InputDecoration(labelText: "Guardian Name", prefixIcon: Icon(Icons.supervisor_account), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter guardian name" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: rollController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Roll Number", prefixIcon: Icon(Icons.pin), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter roll number" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Guardian Phone", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter phone number" : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedClass,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: classes.map((c) => DropdownMenuItem(value: c, child: Text("Class $c", style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedClass = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSection,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Section", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s", style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedSection = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: ["Boy", "Girl"].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedGender = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              setModalState(() => isSaving = true);

                              final data = {
                                "name": nameController.text.trim(),
                                "guardianName": guardianNameController.text.trim(), 
                                "roll": rollController.text.trim(),
                                "phone": phoneController.text.trim(),
                                "class": selectedClass,
                                "section": selectedSection, 
                                "gender": selectedGender,
                                "updatedAt": Timestamp.now(),
                              };

                              try {
                                if (docId == null) {
                                  await firestore.collection("students").add({
                                    ...data,
                                    "createdAt": Timestamp.now(),
                                  });
                                } else {
                                  await firestore.collection("students").doc(docId).update(data);
                                }
                                if (mounted) Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(docId == null ? "Student added successfully" : "Student updated successfully")),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              } finally {
                                setModalState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                          : Text(docId == null ? "Save Student" : "Update Student", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ডিলিট কনফার্মেশন ডায়ালগ
  void _deleteStudent(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to remove this student?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await firestore.collection("students").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      appBar: AppBar(
        title: const Text("Students Table", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Reset All Filters",
            icon: const Icon(Icons.refresh),
            onPressed: _resetAllFilters,
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection("students").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No data found."));
          }

          final allStudents = snapshot.data!.docs;

          // ইউনিক মানগুলোর তালিকা সংগ্রহ (কলাম ফিল্টারে দেখানোর জন্য)
          final Set<String> rollsSet = {};
          final Set<String> classesSet = {};
          final Set<String> sectionsSet = {};
          final Set<String> gendersSet = {"Boy", "Girl"};
          final Set<String> guardiansSet = {};
          final Set<String> phonesSet = {};

          for (var doc in allStudents) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['roll'] != null) rollsSet.add(data['roll'].toString());
            if (data['class'] != null) classesSet.add(data['class'].toString());
            if (data['section'] != null) sectionsSet.add(data['section'].toString());
            if (data['guardianName'] != null) guardiansSet.add(data['guardianName'].toString());
            if (data['phone'] != null) phonesSet.add(data['phone'].toString());
          }

          final List<String> sortedRolls = rollsSet.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          final List<String> sortedClasses = classesSet.toList()..sort();
          final List<String> sortedSections = sectionsSet.toList()..sort();
          final List<String> sortedGuardians = guardiansSet.toList()..sort();
          final List<String> sortedPhones = phonesSet.toList()..sort();

          // কাস্টম ফিল্টারিং লজিক (Name সহ প্রতিটি কলামের আলাদা ফিল্টার)
          final filteredStudents = allStudents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final roll = (data['roll'] ?? '').toString();
            final sClass = (data['class'] ?? '').toString();
            final section = (data['section'] ?? '').toString();
            final gender = (data['gender'] ?? '').toString();
            final guardian = (data['guardianName'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();

            final matchesName = name.contains(searchNameQuery);
            final matchesRoll = filterRoll == "All" || roll == filterRoll;
            final matchesClass = filterClass == "All" || sClass == filterClass;
            final matchesSection = filterSection == "All" || section == filterSection;
            final matchesGender = filterGender == "All" || gender == filterGender;
            final matchesGuardian = filterGuardian == "All" || guardian == filterGuardian;
            final matchesPhone = filterPhone == "All" || phone == filterPhone;

            return matchesName && matchesRoll && matchesClass && matchesSection && matchesGender && matchesGuardian && matchesPhone;
          }).toList();

          return Column(
            children: [
              // সার্চ বার (শুধুমাত্র নামের জন্য)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: nameSearchController,
                  decoration: InputDecoration(
                    hintText: "Search by Student Name...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    suffixIcon: nameSearchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear), 
                            onPressed: () {
                              nameSearchController.clear();
                              setState(() { searchNameQuery = ""; });
                            }
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchNameQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),

              // অনুভূমিকভাবে স্ক্রোলযোগ্য কলাম ভিত্তিক সার্চ ফিল্টার প্যানেল
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    // Roll ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Roll", 
                      selectedValue: filterRoll, 
                      onTap: () => _showSearchableFilter(
                        title: "Roll", 
                        options: sortedRolls, 
                        currentValue: filterRoll, 
                        onSelected: (val) => setState(() => filterRoll = val),
                      )
                    ),
                    const SizedBox(width: 8),

                    // Class ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Class", 
                      selectedValue: filterClass, 
                      onTap: () => _showSearchableFilter(
                        title: "Class", 
                        options: sortedClasses, 
                        currentValue: filterClass, 
                        onSelected: (val) => setState(() => filterClass = val),
                      )
                    ),
                    const SizedBox(width: 8),

                    // Section ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Section", 
                      selectedValue: filterSection, 
                      onTap: () => _showSearchableFilter(
                        title: "Section", 
                        options: sortedSections, 
                        currentValue: filterSection, 
                        onSelected: (val) => setState(() => filterSection = val),
                      )
                    ),
                    const SizedBox(width: 8),

                    // Gender ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Gender", 
                      selectedValue: filterGender, 
                      onTap: () => _showSearchableFilter(
                        title: "Gender", 
                        options: gendersSet.toList(), 
                        currentValue: filterGender, 
                        onSelected: (val) => setState(() => filterGender = val),
                      )
                    ),
                    const SizedBox(width: 8),

                    // Guardian ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Guardian", 
                      selectedValue: filterGuardian, 
                      onTap: () => _showSearchableFilter(
                        title: "Guardian", 
                        options: sortedGuardians, 
                        currentValue: filterGuardian, 
                        onSelected: (val) => setState(() => filterGuardian = val),
                      )
                    ),
                    const SizedBox(width: 8),

                    // Phone ফিল্টার বাটন
                    _buildFilterChip(
                      title: "Phone", 
                      selectedValue: filterPhone, 
                      onTap: () => _showSearchableFilter(
                        title: "Phone", 
                        options: sortedPhones, 
                        currentValue: filterPhone, 
                        onSelected: (val) => setState(() => filterPhone = val),
                      )
                    ),
                  ],
                ),
              ),

              // টেবিল ডেটা ভিউ (হরাইজন্টাল এবং ভার্টিকাল স্ক্রোলিং সহ)
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(child: Text("No students match your filter criteria.", style: TextStyle(color: Colors.grey)))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
                                  columns: const [
                                    DataColumn(label: Text('Roll', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Guardian', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                  ],
                                  rows: filteredStudents.map((studentDoc) {
                                    final data = studentDoc.data() as Map<String, dynamic>;
                                    final docId = studentDoc.id;

                                    return DataRow(cells: [
                                      DataCell(Text(data['roll'] ?? 'N/A')),
                                      DataCell(Text(data['name'] ?? 'N/A')),
                                      DataCell(Text(data['class'] ?? 'N/A')),
                                      DataCell(Text(data['section'] ?? 'N/A')),
                                      DataCell(Text(data['gender'] ?? 'N/A')),
                                      DataCell(Text(data['guardianName'] ?? 'N/A')),
                                      DataCell(Text(data['phone'] ?? 'N/A')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                              onPressed: () => _showStudentForm(docId: docId, studentData: data),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deleteStudent(docId),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _showStudentForm(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // ফিল্টার চিপ বাটন ডিজাইন হেল্পার
  Widget _buildFilterChip({
    required String title,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final bool isFiltered = selectedValue != "All";
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isFiltered ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isFiltered ? Colors.indigo : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFiltered ? "$title: $selectedValue" : title,
              style: TextStyle(
                color: isFiltered ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: isFiltered ? Colors.white : Colors.grey.shade600,
              size: 18,
            )
          ],
        ),
      ),
    );
  }
}