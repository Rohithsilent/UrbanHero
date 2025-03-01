import 'package:UrbanHero/components/manager/profilem.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:UrbanHero/components/manager/reported_issues.dart';
import 'package:UrbanHero/components/manager/statistics.dart';
import 'package:UrbanHero/components/manager/worker_management.dart';
import 'package:fl_chart/fl_chart.dart' as fl;


import 'mappage.dart';

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});

  @override
  _ManagerPageState createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int assignedCount = 0;
  int unassignedCount = 0;

  @override
  void initState() {
    super.initState();
    fetchReportCounts();
  }

  // Fetch real-time assigned & unassigned reports
  Future<void> fetchReportCounts() async {
    try {
      final assignedSnapshot = await _firestore
          .collection('waste_reports')
          .where('assignedWorker', isNotEqualTo: null)
          .get();

      final unassignedSnapshot = await _firestore
          .collection('waste_reports')
          .where('assignedWorker', isEqualTo: null)
          .get();

      setState(() {
        assignedCount = assignedSnapshot.docs.length;
        unassignedCount = unassignedSnapshot.docs.length;
      });
    } catch (e) {
      print("Error fetching report counts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchReportCounts, // Refresh the graph data
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Task Overview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTaskChart(),
              const SizedBox(height: 20),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Sidebar Navigation (Drawer)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Manager'),
            accountEmail: Text('manager@gmail.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/images/google.png'),
            ),
            decoration: BoxDecoration(color: Colors.lightGreen),
          ),
          _drawerItem(Icons.list, 'Reported Issues', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportedIssues()));
          }),
          _drawerItem(Icons.map_outlined, 'Mapping', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
          }),
          _drawerItem(Icons.group, 'Worker Management', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerManagement()));
          }),
          _drawerItem(Icons.person, 'Profile', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManager()));
          }),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  // 🔹 Real-time Pie Chart
  Widget _buildTaskChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('waste_reports').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reports available"));
        }

        int assignedCount = 0;
        int unassignedCount = 0;

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;

          // ✅ Check if 'assignedWorker' exists before using it
          if (data.containsKey('assignedWorker') && data['assignedWorker'] != null) {
            assignedCount++;
          } else {
            unassignedCount++;
          }
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Task Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: fl.PieChart(
                    fl.PieChartData(
                      sections: [
                        fl.PieChartSectionData(
                          color: Colors.green,
                          value: assignedCount.toDouble(),
                          title: 'Assigned',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        fl.PieChartSectionData(
                          color: Colors.red,
                          value: unassignedCount.toDouble(),
                          title: 'Unassigned',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Assigned: $assignedCount | Unassigned: $unassignedCount",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }





  // 🔹 Quick Actions Section
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2, // ✅ 2 columns to prevent overflow
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // ✅ Prevents separate scrolling
          children: [
            _actionCard(Icons.list, "Reported Issues", Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportedIssues()));
            }),
            _actionCard(Icons.map, "Monitor Map", Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
            }),
            _actionCard(Icons.group, "Manage Workers", Colors.green, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerManagement()));
            }),
            _actionCard(Icons.assignment, "Task Overview", Colors.purple, () {
              // Add navigation logic if needed
            }),
          ],
        ),
      ],
    );
  }




  Widget _actionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

}
