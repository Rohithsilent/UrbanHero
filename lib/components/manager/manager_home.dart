import 'package:UrbanHero/components/manager/profilem.dart';
import 'package:UrbanHero/components/manager/statistics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:UrbanHero/components/manager/reported_issues.dart';
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
  int _selectedIndex = 0;
  int _selectedChartType = 0; // 0 for pie chart, 1 for bar chart

  // Store historical data
  List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Mon', 'assigned': 12, 'unassigned': 5},
    {'day': 'Tue', 'assigned': 15, 'unassigned': 7},
    {'day': 'Wed', 'assigned': 10, 'unassigned': 3},
    {'day': 'Thu', 'assigned': 18, 'unassigned': 8},
    {'day': 'Fri', 'assigned': 14, 'unassigned': 4},
    {'day': 'Sat', 'assigned': 8, 'unassigned': 2},
    {'day': 'Sun', 'assigned': 5, 'unassigned': 1},
  ];



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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
            'Manager Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchReportCounts,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Notification logic here
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              const Color(0xFFF5F7FA),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCards(),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTaskChart(),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Status cards for quick metrics
  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            "Total Reports",
            (assignedCount + unassignedCount).toString(),
            Icons.assignment,
            Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            "Pending",
            unassignedCount.toString(),
            Icons.pending_actions,
            Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Sidebar Navigation (Drawer)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade500,
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage('assets/images/google.png'),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'manager@gmail.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.dashboard, 'Dashboard', () {
              Navigator.pop(context);
            }),
            _drawerItem(Icons.list_alt, 'Reported Issues', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportedIssues()));
            }),
            _drawerItem(Icons.map_outlined, 'Map View', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
            }),
            _drawerItem(Icons.group, 'Worker Management', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerManagement()));
            }),
            const Divider(),
            _drawerItem(Icons.person, 'Profile', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManager()));
            }),
            _drawerItem(Icons.settings, 'Settings', () {
              // Add settings navigation
            }),
            _drawerItem(Icons.logout, 'Logout', () {
              // Add logout logic
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // 🔹 Interactive Chart Section
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

          if (data.containsKey('assignedWorker') && data['assignedWorker'] != null) {
            assignedCount++;
          } else {
            unassignedCount++;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Task Distribution",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildChartTypeButton(0, Icons.pie_chart),
                      const SizedBox(width: 8),
                      _buildChartTypeButton(1, Icons.bar_chart),
                      const SizedBox(width: 8),
                      _buildChartTypeButton(2, Icons.timeline),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: _selectedChartType == 0
                    ? _buildPieChart(assignedCount, unassignedCount)
                    : _selectedChartType == 1
                    ? _buildBarChart()
                    : _buildLineChart(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    'Assigned',
                    '$assignedCount Tasks',
                    Colors.green.shade500,
                  ),
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    'Unassigned',
                    '$unassignedCount Tasks',
                    Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartTypeButton(int index, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedChartType == index
              ? Colors.green.shade100
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: _selectedChartType == index
              ? Colors.green.shade700
              : Colors.grey.shade600,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildPieChart(int assignedCount, int unassignedCount) {
    return fl.PieChart(
      fl.PieChartData(
        sections: [
          fl.PieChartSectionData(
            color: Colors.green.shade500,
            value: assignedCount.toDouble(),
            title: '${((assignedCount / (assignedCount + unassignedCount)) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          fl.PieChartSectionData(
            color: Colors.redAccent,
            value: unassignedCount.toDouble(),
            title: '${((unassignedCount / (assignedCount + unassignedCount)) * 100).toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        centerSpaceColor: Colors.white,
      ),
    );
  }

  Widget _buildBarChart() {
    return fl.BarChart(
      fl.BarChartData(
        alignment: fl.BarChartAlignment.spaceAround,
        maxY: 30,
        barTouchData: fl.BarTouchData(
          enabled: true,
          touchTooltipData: fl.BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade100,
          ),
        ),
        titlesData: fl.FlTitlesData(
          show: true,
          bottomTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(fontSize: 10);
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Mon';
                    break;
                  case 1:
                    text = 'Tue';
                    break;
                  case 2:
                    text = 'Wed';
                    break;
                  case 3:
                    text = 'Thu';
                    break;
                  case 4:
                    text = 'Fri';
                    break;
                  case 5:
                    text = 'Sat';
                    break;
                  case 6:
                    text = 'Sun';
                    break;
                  default:
                    text = '';
                }
                return fl.SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox();
                return fl.SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
          topTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
        ),
        gridData: fl.FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 5,
        ),
        borderData: fl.FlBorderData(show: false),
        barGroups: _weeklyData.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return fl.BarChartGroupData(
            x: index,
            barRods: [
              fl.BarChartRodData(
                toY: data['assigned'].toDouble(),
                color: Colors.green.shade500,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              fl.BarChartRodData(
                toY: data['unassigned'].toDouble(),
                color: Colors.redAccent,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    return fl.LineChart(
      fl.LineChartData(
        gridData: fl.FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return fl.FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return fl.FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: fl.FlTitlesData(
          show: true,
          bottomTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(fontSize: 10);
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = 'Mon';
                    break;
                  case 1:
                    text = 'Tue';
                    break;
                  case 2:
                    text = 'Wed';
                    break;
                  case 3:
                    text = 'Thu';
                    break;
                  case 4:
                    text = 'Fri';
                    break;
                  case 5:
                    text = 'Sat';
                    break;
                  case 6:
                    text = 'Sun';
                    break;
                  default:
                    text = '';
                }
                return fl.SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: fl.AxisTitles(
            sideTitles: fl.SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox();
                return fl.SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
          topTitles: fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
        ),
        borderData: fl.FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 20,
        lineBarsData: [
          fl.LineChartBarData(
            spots: _weeklyData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return fl.FlSpot(index.toDouble(), data['assigned'].toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.green.shade500,
            barWidth: 3,
            dotData: fl.FlDotData(show: true),
          ),
          fl.LineChartBarData(
            spots: _weeklyData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              return fl.FlSpot(index.toDouble(), data['unassigned'].toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            dotData: fl.FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔹 Quick Actions Section - Fixed for no overflow
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available width to prevent overflow
              final itemWidth = (constraints.maxWidth - 16) / 2; // 16 is the gap
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _actionCard(
                    Icons.list_alt,
                    "Reported Issues",
                    "View all issues",
                    Colors.blue.shade700,
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportedIssues()));
                    },
                    width: itemWidth,
                  ),
                  _actionCard(
                    Icons.map,
                    "Monitor Map",
                    "View location data",
                    Colors.orange.shade700,
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
                    },
                    width: itemWidth,
                  ),
                  _actionCard(
                    Icons.group,
                    "Manage Workers",
                    "Assign and track workers",
                    Colors.green.shade700,
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerManagement()));
                    },
                    width: itemWidth,
                  ),
                  _actionCard(
                    Icons.analytics,
                    "Analytics",
                    "View detailed reports",
                    Colors.purple.shade700,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WasteReportDashboard()));
                    },
                    width: itemWidth,
                  ),
                ],
              );
            }
        ),
      ],
    );
  }

  Widget _actionCard(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap, {
        required double width,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Handle navigation based on index
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportedIssues()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileManager()));
          }
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}