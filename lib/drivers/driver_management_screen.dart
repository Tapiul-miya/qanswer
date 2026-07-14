import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // ফর্ম কন্ট্রোলার সমূহ
  final nameController = TextEditingController();
  final licenseController = TextEditingController(); 
  final phoneController = TextEditingController();
  final vehicleNoController = TextEditingController();
  
  // সার্চ ও ফিল্টারিং ভ্যারিয়েবলস
  final nameSearchController = TextEditingController(); 
  
  String searchNameQuery = "";
  String filterRoute = "All";
  String filterVehicle = "All";
  String filterGender = "All";
  String filterLicense = "All";
  String filterPhone = "All";

  String selectedRoute = "Route A";
  String selectedGender = "Male";
  bool isSaving = false;

  // রুট বা এলাকার লিস্ট
  final List<String> routes = [
    "Route A", 
    "Route B", 
    "Route C", 
    "Route D", 
    "Route E", 
    "Special Route"
  ];

  @override
  void dispose() {
    nameController.dispose();
    licenseController.dispose(); 
    phoneController.dispose();
    vehicleNoController.dispose();
    nameSearchController.dispose();
    super.dispose();
  }

  // সব ফিল্টার রিসেট করার ফাংশন
  void _resetAllFilters() {
    setState(() {
      nameSearchController.clear();
      searchNameQuery = "";
      filterRoute = "All";
      filterVehicle = "All";
      filterGender = "All";
      filterLicense = "All";
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

  // ড্রাইভার যোগ বা এডিট করার জন্য বটম শিট ফর্ম
  void _showDriverForm({String? docId, Map<String, dynamic>? driverData}) {
    if (driverData != null) {
      nameController.text = driverData['name'] ?? '';
      licenseController.text = driverData['license'] ?? ''; 
      phoneController.text = driverData['phone'] ?? '';
      vehicleNoController.text = driverData['vehicleNo'] ?? '';
      selectedRoute = driverData['route'] ?? 'Route A';
      selectedGender = driverData['gender'] ?? 'Male';
    } else {
      nameController.clear();
      licenseController.clear(); 
      phoneController.clear();
      vehicleNoController.clear();
      selectedRoute = "Route A";
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
                    docId == null ? "Add New Driver" : "Update Driver Info",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 20),
                  
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Driver Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter driver name" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: licenseController,
                    decoration: const InputDecoration(labelText: "Driving License Number", prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter license number" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: vehicleNoController,
                    decoration: const InputDecoration(labelText: "Vehicle Number (e.g., Bus-05, Van-12)", prefixIcon: Icon(Icons.directions_bus), border: OutlineInputBorder()),
                    validator: (val) => val == null || val.trim().isEmpty ? "Enter vehicle number" : null,
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
                          value: selectedRoute,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Assigned Route", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: routes.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11)))).toList(),
                          onChanged: (val) => setModalState(() => selectedRoute = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
                          items: ["Male", "Female"].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 11)))).toList(),
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
                                "license": licenseController.text.trim(), 
                                "phone": phoneController.text.trim(),
                                "vehicleNo": vehicleNoController.text.trim(),
                                "route": selectedRoute,
                                "gender": selectedGender,
                                "updatedAt": Timestamp.now(),
                              };

                              try {
                                if (docId == null) {
                                  await firestore.collection("drivers").add({
                                    ...data,
                                    "createdAt": Timestamp.now(),
                                  });
                                } else {
                                  await firestore.collection("drivers").doc(docId).update(data);
                                }
                                if (mounted) Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(docId == null ? "Driver added successfully" : "Driver updated successfully")),
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
                          : Text(docId == null ? "Save Driver" : "Update Driver", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
  void _deleteDriver(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Driver"),
        content: const Text("Are you sure you want to remove this driver?"),
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
      await firestore.collection("drivers").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver deleted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      appBar: AppBar(
        title: const Text("Drivers Table", style: TextStyle(fontWeight: FontWeight.bold)),
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
        stream: firestore.collection("drivers").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No driver data found."));
          }

          final allDrivers = snapshot.data!.docs;

          // ইউনিক মানগুলোর তালিকা সংগ্রহ (কলাম ফিল্টারে দেখানোর জন্য)
          final Set<String> routesSet = {};
          final Set<String> vehiclesSet = {};
          final Set<String> gendersSet = {"Male", "Female"};
          final Set<String> licensesSet = {};
          final Set<String> phonesSet = {};

          for (var doc in allDrivers) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['route'] != null) routesSet.add(data['route'].toString());
            if (data['vehicleNo'] != null) vehiclesSet.add(data['vehicleNo'].toString());
            if (data['license'] != null) licensesSet.add(data['license'].toString());
            if (data['phone'] != null) phonesSet.add(data['phone'].toString());
          }

          final List<String> sortedRoutes = routesSet.toList()..sort();
          final List<String> sortedVehicles = vehiclesSet.toList()..sort();
          final List<String> sortedLicenses = licensesSet.toList()..sort();
          final List<String> sortedPhones = phonesSet.toList()..sort();

          // কাস্টম ফিল্টারিং লজিক
          final filteredDrivers = allDrivers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final route = (data['route'] ?? '').toString();
            final vehicle = (data['vehicleNo'] ?? '').toString();
            final gender = (data['gender'] ?? '').toString();
            final license = (data['license'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();

            final matchesName = name.contains(searchNameQuery);
            final matchesRoute = filterRoute == "All" || route == filterRoute;
            final matchesVehicle = filterVehicle == "All" || vehicle == filterVehicle;
            final matchesGender = filterGender == "All" || gender == filterGender;
            final matchesLicense = filterLicense == "All" || license == filterLicense;
            final matchesPhone = filterPhone == "All" || phone == filterPhone;

            return matchesName && matchesRoute && matchesVehicle && matchesGender && matchesLicense && matchesPhone;
          }).toList();

          return Column(
            children: [
              // সার্চ বার (নামের জন্য)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: nameSearchController,
                  decoration: InputDecoration(
                    hintText: "Search by Driver Name...",
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

              // ফিল্টার প্যানেল
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    _buildFilterChip(
                      title: "Route", 
                      selectedValue: filterRoute, 
                      onTap: () => _showSearchableFilter(
                        title: "Route", 
                        options: sortedRoutes, 
                        currentValue: filterRoute, 
                        onSelected: (val) => setState(() => filterRoute = val),
                      )
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      title: "Vehicle", 
                      selectedValue: filterVehicle, 
                      onTap: () => _showSearchableFilter(
                        title: "Vehicle", 
                        options: sortedVehicles, 
                        currentValue: filterVehicle, 
                        onSelected: (val) => setState(() => filterVehicle = val),
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
                      title: "License", 
                      selectedValue: filterLicense, 
                      onTap: () => _showSearchableFilter(
                        title: "License", 
                        options: sortedLicenses, 
                        currentValue: filterLicense, 
                        onSelected: (val) => setState(() => filterLicense = val),
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
                child: filteredDrivers.isEmpty
                    ? const Center(child: Text("No drivers match your filter criteria.", style: TextStyle(color: Colors.grey)))
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
                                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('License No', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Vehicle No', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                                  ],
                                  rows: filteredDrivers.map((driverDoc) {
                                    final data = driverDoc.data() as Map<String, dynamic>;
                                    final docId = driverDoc.id;

                                    return DataRow(cells: [
                                      DataCell(Text(data['name'] ?? 'N/A')),
                                      DataCell(Text(data['license'] ?? 'N/A')),
                                      DataCell(Text(data['vehicleNo'] ?? 'N/A')),
                                      DataCell(Text(data['route'] ?? 'N/A')),
                                      DataCell(Text(data['gender'] ?? 'N/A')),
                                      DataCell(Text(data['phone'] ?? 'N/A')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                                              onPressed: () => _showDriverForm(docId: docId, driverData: data),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deleteDriver(docId),
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
        onPressed: () => _showDriverForm(),
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