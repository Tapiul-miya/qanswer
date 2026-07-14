import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // ফর্ম কন্ট্রোলার সমূহ
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final designationController = TextEditingController();
  final departmentController = TextEditingController();

  // সার্চ ও ফিল্টারিং ভ্যারিয়েবলস
  final nameSearchController = TextEditingController();

  String searchNameQuery = "";
  String filterDepartment = "All";
  String filterDesignation = "All";
  String filterGender = "All";
  String filterPhone = "All";

  String selectedDepartment = "Science";
  String selectedDesignation = "Lecturer";
  String selectedGender = "Male";
  bool isSaving = false;

  // ডিপার্টমেন্টের লিস্ট
  final List<String> departments = [
    "Science",
    "Arts",
    "Commerce",
    "Mathematics",
    "English",
    "Bangla"
  ];

  // পদবী বা ডেজিগনেশনের লিস্ট
  final List<String> designations = [
    "Lecturer",
    "Assistant Professor",
    "Associate Professor",
    "Professor",
    "Head Teacher"
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    designationController.dispose();
    departmentController.dispose();
    nameSearchController.dispose();
    super.dispose();
  }

  // সব ফিল্টার রিসেট করার ফাংশন
  void _resetAllFilters() {
    setState(() {
      nameSearchController.clear();
      searchNameQuery = "";
      filterDepartment = "All";
      filterDesignation = "All";
      filterGender = "All";
      filterPhone = "All";
    });
  }

  // ডাইনামিক সার্চেবল ফিল্টার ডায়ালগ
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
              title: Text("Select $title", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
                            trailing: currentValue == item ? const Icon(Icons.check, color: Colors.teal) : null,
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

  // শিক্ষক যোগ বা এডিট করার জন্য বটম শিট ফর্ম
  void _showTeacherForm({String? docId, Map<String, dynamic>? teacherData}) {
    if (teacherData != null) {
      nameController.text = teacherData['name'] ?? '';
      phoneController.text = teacherData['phone'] ?? '';
      selectedDepartment = teacherData['department'] ?? 'Science';
      selectedDesignation = teacherData['designation'] ?? 'Lecturer';
      selectedGender = teacherData['gender'] ?? 'Male';
    } else {
      nameController.clear();
      phoneController.clear();
      selectedDepartment = "Science";
      selectedDesignation = "Lecturer";
      selectedGender = "Male";
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
                    docId == null ? "Add New Teacher" : "Update Teacher Info",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Teacher Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter teacher name" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter phone number" : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedDepartment = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedDesignation,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Designation", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: designations.map((des) => DropdownMenuItem(value: des, child: Text(des, style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedDesignation = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                    items: ["Male", "Female"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setModalState(() => selectedGender = val!),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              setModalState(() => isSaving = true);

                              final data = {
                                "name": nameController.text.trim(),
                                "phone": phoneController.text.trim(),
                                "department": selectedDepartment,
                                "designation": selectedDesignation,
                                "gender": selectedGender,
                                "updatedAt": Timestamp.now(),
                              };

                              try {
                                if (docId == null) {
                                  await firestore.collection("teachers").add({
                                    ...data,
                                    "createdAt": Timestamp.now(),
                                  });
                                } else {
                                  await firestore.collection("teachers").doc(docId).update(data);
                                }
                                if (mounted) Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(docId == null ? "Teacher added successfully" : "Teacher updated successfully")),
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
                          : Text(docId == null ? "Save Teacher" : "Update Teacher", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
  void _deleteTeacher(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Teacher"),
        content: const Text("Are you sure you want to remove this teacher?"),
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
      await firestore.collection("teachers").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teacher deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Teachers Table", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
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
        stream: firestore.collection("teachers").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No teacher data found."));
          }

          final allTeachers = snapshot.data!.docs;

          // ইউনিক মানগুলোর তালিকা সংগ্রহ (কলাম ফিল্টারে দেখানোর জন্য)
          final Set<String> departmentsSet = {};
          final Set<String> designationsSet = {};
          final Set<String> gendersSet = {"Male", "Female"};
          final Set<String> phonesSet = {};

          for (var doc in allTeachers) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['department'] != null) departmentsSet.add(data['department'].toString());
            if (data['designation'] != null) designationsSet.add(data['designation'].toString());
            if (data['phone'] != null) phonesSet.add(data['phone'].toString());
          }

          final List<String> sortedDepartments = departmentsSet.toList()..sort();
          final List<String> sortedDesignations = designationsSet.toList()..sort();
          final List<String> sortedPhones = phonesSet.toList()..sort();

          // কাস্টম ফিল্টারিং লজিক
          final filteredTeachers = allTeachers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final department = (data['department'] ?? '').toString();
            final designation = (data['designation'] ?? '').toString();
            final gender = (data['gender'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();

            final matchesName = name.contains(searchNameQuery);
            final matchesDepartment = filterDepartment == "All" || department == filterDepartment;
            final matchesDesignation = filterDesignation == "All" || designation == filterDesignation;
            final matchesGender = filterGender == "All" || gender == filterGender;
            final matchesPhone = filterPhone == "All" || phone == filterPhone;

            return matchesName && matchesDepartment && matchesDesignation && matchesGender && matchesPhone;
          }).toList();

          return Column(
            children: [
              // সার্চ বার (নামের জন্য)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: nameSearchController,
                  decoration: InputDecoration(
                    hintText: "Search by Teacher Name...",
                    prefixIcon: const Icon(Icons.search, color: Colors.teal),
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

              // ফিল্টার প্যানেল
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    _buildFilterChip(
                      title: "Department",
                      selectedValue: filterDepartment,
                      onTap: () => _showSearchableFilter(
                        title: "Department",
                        options: sortedDepartments,
                        currentValue: filterDepartment,
                        onSelected: (val) => setState(() => filterDepartment = val),
                      )
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      title: "Designation",
                      selectedValue: filterDesignation,
                      onTap: () => _showSearchableFilter(
                        title: "Designation",
                        options: sortedDesignations,
                        currentValue: filterDesignation,
                        onSelected: (val) => setState(() => filterDesignation = val),
                      )
                    ),
                    const SizedBox(width: 8),
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

              // ডেটা টেবিল
              Expanded(
                child: filteredTeachers.isEmpty
                    ? const Center(child: Text("No teachers match your filter criteria.", style: TextStyle(color: Colors.grey)))
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
                                  headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
                                  columns: const [
                                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                    DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                    DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                    DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                  ],
                                  rows: filteredTeachers.map((teacherDoc) {
                                    final data = teacherDoc.data() as Map<String, dynamic>;
                                    final docId = teacherDoc.id;

                                    return DataRow(cells: [
                                      DataCell(Text(data['name'] ?? 'N/A')),
                                      DataCell(Text(data['department'] ?? 'N/A')),
                                      DataCell(Text(data['designation'] ?? 'N/A')),
                                      DataCell(Text(data['gender'] ?? 'N/A')),
                                      DataCell(Text(data['phone'] ?? 'N/A')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.teal, size: 20),
                                              onPressed: () => _showTeacherForm(docId: docId, teacherData: data),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deleteTeacher(docId),
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
        backgroundColor: Colors.teal,
        onPressed: () => _showTeacherForm(),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
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
          color: isFiltered ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isFiltered ? Colors.teal : Colors.grey.shade300),
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