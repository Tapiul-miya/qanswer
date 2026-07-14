import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart'; 
import 'question_management_screen.dart'; 
import 'students/student_management_screen.dart';
import 'teachers/teacher_management_screen.dart';
import 'drivers/driver_management_screen.dart';

class SchoolDashboardScreen extends StatefulWidget {
  const SchoolDashboardScreen({super.key});

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(), 
    const QuestionManagementScreen(), 
    const StudentManagementScreen(),
    const TeacherManagementScreen(),
    const DriverManagementScreen(), 
    const Center(child: Text("Staff & Workers Management (Coming Soon...)", style: TextStyle(fontSize: 20))), 
    const Center(child: Text("Settings & Access Control", style: TextStyle(fontSize: 20))),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // ================= বাম পাশের সাইডবার (Sidebar) =================
          Container(
            width: isLargeScreen ? 260 : 80, 
            color: Colors.indigo.shade900,
            child: Column(
              children: [
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: isLargeScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 32),
                        if (isLargeScreen) ...[
                          const SizedBox(width: 12),
                          const Text(
                            "EduManage Portal",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 15),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildMenuItem(0, Icons.dashboard, "Dashboard", isLargeScreen),
                      _buildMenuItem(1, Icons.quiz, "Question Bank", isLargeScreen),
                      _buildMenuItem(2, Icons.people, "Students Info", isLargeScreen),
                      _buildMenuItem(3, Icons.badge, "Teachers Panel", isLargeScreen),
                      _buildMenuItem(4, Icons.directions_bus, "Drivers List", isLargeScreen), 
                      _buildMenuItem(5, Icons.engineering, "Staff / Workers", isLargeScreen), 
                      _buildMenuItem(6, Icons.settings, "System Settings", isLargeScreen),
                    ],
                  ),
                ),

                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: isLargeScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      if (isLargeScreen) ...[
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Admin User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text("Principal", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ================= ডান পাশের কনটেন্ট স্ক্রিন =================
          Expanded(
            child: Container(
              color: Colors.grey.shade100, 
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title, bool showText) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: showText ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.amber : Colors.white70, size: 24),
              if (showText) ...[
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ================= ড্যাশবোর্ড ওভারভিউ স্ক্রিন (গ্রেডিয়েন্ট কার্ড সহ) =================
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // স্কুলের নামের মারকুই হেডার
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade900,
                    Colors.indigo.shade700,
                    Colors.purple.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      "🏫",
                      style: TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  Expanded(
                    child: SizedBox(
                      height: 35,
                      child: Marquee(
                        text: "Baravita Vivekananda Vidyapith • ",
                        style: const TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.amberAccent, 
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 50.0, 
                        velocity: 45.0, 
                        pauseAfterRound: const Duration(seconds: 1), 
                        startPadding: 10.0,
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Welcome Back, Principal!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.indigo),
            ),
            const Text("Here is what's happening in your school today.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // ড্যাশবোর্ড প্রিমিয়াম লাইভ গ্রেডিয়েন্ট কার্ড গ্রিড
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.8,
                  children: [
                    _buildLiveStatCard(
                      collectionPath: "students",
                      title: "Total Students",
                      icon: Icons.people,
                      startColor: const Color(0xFF1E3C72), // রয়েল ব্লু গ্রেডিয়েন্ট
                      endColor: const Color(0xFF2A5298),
                    ),
                    _buildLiveStatCard(
                      collectionPath: "teachers",
                      title: "Total Teachers",
                      icon: Icons.badge,
                      startColor: const Color(0xFF0F9D58), // ডিপ এমারেল্ড গ্রিন
                      endColor: const Color(0xFF007F4F),
                    ),
                    _buildLiveStatCard(
                      collectionPath: "questions", 
                      title: "Questions Added",
                      icon: Icons.quiz,
                      startColor: const Color(0xFFE65C00), // ভাইব্রেন্ট সানসেট অরেঞ্জ
                      endColor: const Color(0xFFF9D423),
                    ),
                    _buildLiveStatCard(
                      collectionPath: "drivers",
                      title: "Active Drivers",
                      icon: Icons.directions_bus,
                      startColor: const Color(0xFF4A00E0), // নিয়ন পার্পল-ব্লু
                      endColor: const Color(0xFF8E2DE2),
                    ), 
                    _buildStaticStatCard(
                      "Support Staff", 
                      "24", 
                      Icons.engineering, 
                      const Color(0xFF373B44), // ডার্ক মেটালিক স্লটে
                      const Color(0xFF4286f4),
                    ), 
                    _buildStaticStatCard(
                      "Attendance Rate", 
                      "94%", 
                      Icons.fact_check, 
                      const Color(0xFFD31027), // রুবি রেড গ্রেডিয়েন্ট
                      const Color(0xFFEA0043),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // নোটিশ বোর্ড বা রিসেন্ট অ্যাক্টিভিটি
            const Text(
              "Recent Announcements",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.campaign, color: Colors.white)),
                      title: Text("Parent-Teacher Meeting", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Scheduled for this Saturday at 10:00 AM"),
                    ),
                    Divider(),
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.school, color: Colors.white)),
                      title: Text("Term 1 Examination Syllabus Published", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Mathematics and Science syllabus uploaded to all classes"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ফায়ারস্টোর লাইভ গ্রেডিয়েন্ট কার্ড জেনারেটর
  Widget _buildLiveStatCard({
    required String collectionPath,
    required String title,
    required IconData icon,
    required Color startColor,
    required Color endColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionPath).snapshots(),
      builder: (context, snapshot) {
        String totalCount = "...";

        if (snapshot.hasData) {
          totalCount = snapshot.data!.docs.length.toString();
        } else if (snapshot.hasError) {
          totalCount = "Error";
        }

        return _buildStaticStatCard(title, totalCount, icon, startColor, endColor);
      },
    );
  }

  // সম্পূর্ণ ব্যাকগ্রাউন্ড গ্রেডিয়েন্ট সহ প্রিমিয়াম স্ট্যাট কার্ড ডিজাইন
  Widget _buildStaticStatCard(String title, String count, IconData icon, Color startColor, Color endColor) {
    return Container(
      decoration: BoxDecoration(
        // 🔥 কার্ডের মূল ব্যাকগ্রাউন্ডে প্রিমিয়াম লিনিয়ার গ্রেডিয়েন্ট
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.12), // হালকা গ্লাস বর্ডার
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // টাইটেল টেক্সট (অর্ধ-স্বচ্ছ সাদা যাতে গ্রেডিয়েন্টে ভালো দেখায়)
                    Text(
                      title, 
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85), 
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    
                    // 🔥 বোল্ড হোয়াইট টেক্সট (শ্যাডো সহ চমৎকার ভিজ্যুয়াল পেতে)
                    Text(
                      count, 
                      style: const TextStyle(
                        fontSize: 34, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 2),
                            blurRadius: 3,
                          )
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // গ্লাস-মরফিজম (Glassmorphism) স্টাইলিশ আইকন বক্স
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, // সাদা প্রিমিয়াম আইকন
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}