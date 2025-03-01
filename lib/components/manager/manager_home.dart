import 'package:UrbanHero/components/manager/reported_issues.dart';
import 'package:UrbanHero/components/manager/statistics.dart';
import 'package:flutter/material.dart';


class ManagerPage extends StatelessWidget {
  const ManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, double> chartData = {
      'Resolved': 60.0,
      'Pending': 20.0,
      'In Progress': 30.0,
    };

    List<String> issues = [
      'Issue 1: Pending',
      'Issue 2: In Progress',
      'Issue 3: Resolved',
      'Issue 4: Resolved'
    ];

    List<Map<String, dynamic>> workers = [
      {'name': 'Worker 1', 'status': 'Active', 'tasksCompleted': 5},
      {'name': 'Worker 2', 'status': 'Inactive', 'tasksCompleted': 3},
      {'name': 'Worker 3', 'status': 'Active', 'tasksCompleted': 7},
      {'name': 'Worker 4', 'status': 'On Break', 'tasksCompleted': 2},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Manager'),
              accountEmail: Text('manager@gmail.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/images/google.png'),
              ),
              decoration: BoxDecoration(
                color: Colors.lightGreen,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Reported Issues'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportedIssues(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Mapping'),
              onTap: (){
                Navigator.pushNamed(context, '/map');
              },

            ),
            ListTile(
              leading: const Icon(Icons.contact_page_sharp),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pushNamed(context, '/profilem');
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_page_sharp),
              title: const Text('Assign Tasks'),
              onTap: () {
                Navigator.pushNamed(context, '/assign');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),
              Statistics(chartData: chartData),
              const SizedBox(height: 20),
              // Pass all required parameters to the ReportedIssues widget
              // ReportedIssues(
              //   issues: issues,
              //   imageUrl:
              //   'https://img.freepik.com/premium-photo/spilled-recycling-man-made-garbage-park-forest-near-city-empty-used-dirty-waste-plastic-bottles-caps-bags-carton-paper-boxes-environmental-total-pollution-ecological-problem-global-warming_643018-1042.jpg',
              //   dateTimeReported: DateTime.now(),
              //   additionalIssues: 'Some additional issue details.',
              // ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}

// ReportedIssuesScreen.dart
class ReportedIssuesScreen extends StatelessWidget {
  const ReportedIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Issues'),
      ),
      body: const Center(
        child: Text('List of reported issues will be displayed here'),
      ),
    );
  }
}
