import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class WorkerManagement extends StatefulWidget {
  const WorkerManagement({super.key});

  @override
  _WorkerManagementState createState() => _WorkerManagementState();
}

class _WorkerManagementState extends State<WorkerManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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
      // Fetch workers from the 'users' collection, where the role is 'worker'
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'worker') // Filtering by role 'worker'
          .get();

      setState(() {
        workers = snapshot.docs.map((doc) {
          return {
            'username': doc['username'],  // Fetching the 'username' field from each document
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
      final snapshot = await _firestore.collection('waste_reports').get();
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

  // Assign issue to worker and send notification
  Future<void> assignIssue(String workerId, String issueId, String location) async {
    try {
      // Update the issue in Firestore
      await _firestore.collection('waste_reports').doc(issueId).update({
        'assignedWorker': workerId,
        'status': 'Assigned',
      });

      // Send a Firebase Cloud Messaging notification
      await _messaging.sendMessage(
        to: 'manager_notifications',
        data: {
          'title': 'Work Assigned',
          'body': 'Work assigned at $location',
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Work assigned at $location')),
      );
    } catch (e) {
      print('Error assigning issue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign work')),
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
              child: ListView.builder(
                itemCount: issues.length,
                itemBuilder: (context, index) {
                  final issue = issues[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Waste Size: ${issue['wasteSize']}'),
                      subtitle: Text(
                          'Description: ${issue['description']}\nLocation: ${issue['location']}'),
                      trailing: ElevatedButton(
                        onPressed: () => showWorkerSelection(issue),
                        child: const Text('Assign'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
                  title: Text(worker['name']),
                  subtitle: Text('Username: ${worker['username']}'),
                  onTap: () {
                    Navigator.pop(context);
                    assignIssue(worker['id'], issue['id'], issue['location']);
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
