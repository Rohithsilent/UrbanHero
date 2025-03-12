import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkerStatsScreen extends StatefulWidget {
  const WorkerStatsScreen({super.key});

  @override
  _WorkerStatsScreenState createState() => _WorkerStatsScreenState();
}

class _WorkerStatsScreenState extends State<WorkerStatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  int _tasksCompleted = 0;
  double _avgResponseTime = 0.0;
  int _areasCovered = 0;
  double _customerRating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchWorkerStats();
  }

  Future<void> fetchWorkerStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      String? workerUid = _auth.currentUser?.uid;
      if (workerUid == null) {
        print('Worker UID not found.');
        return;
      }

      // Get all tasks assigned to this worker
      final tasksSnapshot = await _firestore
          .collection('waste_reports')
          .where('assignedWorker', isEqualTo: workerUid)
          .get();

      // Get completed tasks
      final completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .toList();

      // Calculate tasks completed
      _tasksCompleted = completedTasks.length;

      // Calculate areas covered (unique locations)
      final locations = tasksSnapshot.docs
          .map((doc) => doc['location'] as String)
          .toSet();
      _areasCovered = locations.length;

      // Calculate average response time (from assigned to started)
      List<double> responseTimes = [];
      for (var doc in tasksSnapshot.docs) {
        if (doc['assignedTimestamp'] != null && doc['startedTimestamp'] != null) {
          final assignedTime = (doc['assignedTimestamp'] as Timestamp).toDate();
          final startedTime = (doc['startedTimestamp'] as Timestamp).toDate();
          final diffInHours = startedTime.difference(assignedTime).inMinutes / 60.0;
          responseTimes.add(diffInHours);
        }
      }

      if (responseTimes.isNotEmpty) {
        final sum = responseTimes.reduce((a, b) => a + b);
        _avgResponseTime = sum / responseTimes.length;
      }

      // Get customer ratings from feedback
      final feedbackSnapshot = await _firestore
          .collection('feedback')
          .where('workerId', isEqualTo: workerUid)
          .get();

      List<double> ratings = [];
      for (var doc in feedbackSnapshot.docs) {
        if (doc['rating'] != null) {
          ratings.add((doc['rating'] as num).toDouble());
        }
      }

      if (ratings.isNotEmpty) {
        final sum = ratings.reduce((a, b) => a + b);
        _customerRating = sum / ratings.length;
      } else {
        _customerRating = 0.0;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching worker stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchWorkerStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatCard(
              'Tasks Completed',
              _tasksCompleted.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Average Response Time',
              '${_avgResponseTime.toStringAsFixed(1)} hours',
              Icons.timer,
              Colors.blue,
            ),
            _buildStatCard(
              'Areas Covered',
              _areasCovered.toString(),
              Icons.map,
              Colors.purple,
            ),
            _buildStatCard(
              'Customer Rating',
              '${_customerRating.toStringAsFixed(1)}/5',
              Icons.star,
              Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildCompletionRate(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRate() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('waste_reports')
          .where('assignedWorker', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final allTasks = snapshot.data!.docs.length;
        final completedTasks = snapshot.data!.docs
            .where((doc) => doc['status'] == 'completed')
            .length;

        final completionRate = allTasks > 0
            ? (completedTasks / allTasks * 100).toStringAsFixed(0)
            : "0";

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: allTasks > 0 ? completedTasks / allTasks : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedTasks of $allTasks tasks completed',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$completionRate%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}