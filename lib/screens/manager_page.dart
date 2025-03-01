// import 'package:flutter/material.dart';
//
// import 'package:greenguardians/components/header.dart';
//
// import 'package:greenguardians/components/statistics.dart';
//
// import 'package:greenguardians/components/profilec.dart';
//
// import 'package:greenguardians/components/reported_issues.dart';
//
// import 'package:greenguardians/components/worker_management.dart';
//
//
//
// class ManagerPage extends StatelessWidget {
//
//   @override
//
//   Widget build(BuildContext context) {
//
//     Map<String, double> chartData = {
//
//       'Resolved': 60.0,
//
//       'Pending': 20.0,
//
//       'In Progress': 30.0,
//
//     };
//
//
//
//     List<String> issues = [
//
//       'Issue 1: Pending',
//
//       'Issue 2: In Progress',
//
//       'Issue 3: Resolved',
//       'Issue 4: Resolved'
//     ];
//
//
//
//     List<Map<String, dynamic>> workers = [
//
//       {'name': 'Worker 1', 'status': 'Active', 'tasksCompleted': 5},
//
//       {'name': 'Worker 2', 'status': 'Inactive', 'tasksCompleted': 3},
//
//       {'name': 'Worker 3', 'status': 'Active', 'tasksCompleted': 7},
//
//       {'name': 'Worker 4', 'status': 'On Break', 'tasksCompleted': 2},
//
//     ];
//
//
//
//     return Scaffold(
//
//       appBar: AppBar(
//
//         title: Text('Manager Dashboard'),
//
//         backgroundColor: Colors.green,
//
//       ),
//
//       drawer: Drawer(
//
//         child: ListView(
//
//           padding: EdgeInsets.zero,
//
//           children: [
//
//             UserAccountsDrawerHeader(
//
//               accountName: Text('Rajesh'),
//
//               accountEmail: Text('rajesh.doe@example.com'),
//
//               currentAccountPicture: CircleAvatar(
//
//                 backgroundImage: AssetImage('assets/user_avatar.png'), // Replace with your image path
//
//               ),
//
//               decoration: BoxDecoration(
//
//                 color: Colors.lightGreen,
//
//               ),
//
//             ),
//
//             ListTile(
//
//               leading: Icon(Icons.list),
//
//               title: Text('Reported Issues'),
//
//               onTap: () {
//
//                 Navigator.push(
//
//                   context,
//
//                   MaterialPageRoute(
//
//                     builder: (context) => ReportedIssuesScreen(),
//
//                   ),
//
//                 );
//
//               },
//
//             ),
//
//             ListTile(
//
//               leading: Icon(Icons.logout),
//
//               title: Text('Logout'),
//
//               onTap: () {
//
//                 // Implement logout functionality
//
//               },
//
//             ),
//
//           ],
//
//         ),
//
//       ),
//
//       body: Padding(
//
//         padding: const EdgeInsets.all(20.0),
//
//         child: SingleChildScrollView(
//
//           child: Column(
//
//             crossAxisAlignment: CrossAxisAlignment.start,
//
//             children: [
//
//               Header(),
//
//               SizedBox(height: 20),
//
//               // Profile(username: 'manager456', role: 'Manager'),
//
//               SizedBox(height: 20),
//
//               Statistics(chartData: chartData),
//
//               SizedBox(height: 20),
//
//               ReportedIssues(issues: issues),
//
//               SizedBox(height: 20),
//
//               WorkerManagement(workers: workers),
//
//             ],
//
//           ),
//
//         ),
//
//       ),
//
//     );
//
//   }
//
// }
//
//
//
// // ReportedIssuesScreen.dart
//
// class ReportedIssuesScreen extends StatelessWidget {
//
//   @override
//
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//
//       appBar: AppBar(
//
//         title: Text('Reported Issues'),
//
//       ),
//
//       body: Center(
//
//         child: Text('List of reported issues will be displayed here'),
//
//       ),
//
//     );
//
//   }
//
// }