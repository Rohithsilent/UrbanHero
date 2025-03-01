import 'package:flutter/material.dart';

class WorkerStatsScreen extends StatelessWidget {
  const WorkerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Performance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(
              'Tasks Completed',
              '45',
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Average Response Time',
              '2.5 hours',
              Icons.timer,
              Colors.blue,
            ),
            _buildStatCard(
              'Areas Covered',
              '12',
              Icons.map,
              Colors.purple,
            ),
            _buildStatCard(
              'Customer Rating',
              '4.8/5',
              Icons.star,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}