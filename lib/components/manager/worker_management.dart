import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkerManagement extends StatefulWidget {
  const WorkerManagement({super.key});

  @override
  _WorkerManagementState createState() => _WorkerManagementState();
}

class _WorkerManagementState extends State<WorkerManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> issues = [];

  @override
  void initState() {
    super.initState();
    fetchWorkers();
    fetchIssues();
  }

  // Fetch workers from Firestore
  Future<void> fetchWorkers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Worker') // Ensure correct case
          .get();

      setState(() {
        workers = snapshot.docs.map((doc) {
          return {
            'id': doc.id, // Store worker document ID
            'username': doc['username'], // Display username
            'email': doc['email'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching workers: $e');
    }
  }

  // Fetch issues from Firestore
  Future<void> fetchIssues() async {
    try {
      final snapshot = await _firestore.collection('waste_reports').get(); // Fetch all reports

      setState(() {
        issues = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching issues: $e');
    }
  }


  // Assign issue to worker
  Future<void> assignIssue(String workerId, String issueId, String workerName) async {
    try {
      await _firestore.collection('waste_reports').doc(issueId).update({
        'assignedWorker': workerId, // Store worker's UID
        'assignedWorkerName': workerName, // Store worker's username
        'status': 'Assigned',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task assigned to $workerName')),
      );

      // Refresh issues after assignment
      fetchIssues();
    } catch (e) {
      print('Error assigning issue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign task')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Issues Reported',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: issues.isEmpty
                  ? const Center(child: Text("No issues available"))
                  : ListView(
                children: [
                  // Unassigned Issues
                  if (issues.any((issue) => issue['assignedWorker'] == null))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Unassigned Issues',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ...issues.where((issue) => issue['assignedWorker'] == null).map((issue) {
                    return issueCard(issue, isAssigned: false);
                  }).toList(),

                  // Assigned Issues
                  if (issues.any((issue) => issue['assignedWorker'] != null))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Assigned Issues',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ...issues.where((issue) => issue['assignedWorker'] != null).map((issue) {
                    return issueCard(issue, isAssigned: true);
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Function to build issue cards
  Widget issueCard(Map<String, dynamic> issue, {required bool isAssigned}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text('Waste Size: ${issue['wasteSize']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${issue['description']}'),
            Text('Location: ${issue['location']}'),
            Text(
              'Assigned Worker: ${issue['assignedWorkerName'] ?? 'Not Assigned'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAssigned ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: isAssigned
            ? null // No assign button for already assigned issues
            : ElevatedButton(
          onPressed: () => showWorkerSelection(issue),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Assign'),
        ),
      ),
    );
  }


  void showWorkerSelection(Map<String, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Worker'),
          content: workers.isEmpty
              ? const Text('No workers available.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return ListTile(
                  title: Text(worker['username']), // Fixed
                  subtitle: Text(worker['email']), // Show email
                  onTap: () {
                    Navigator.pop(context);
                    assignIssue(worker['id'], issue['id'], worker['username']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
