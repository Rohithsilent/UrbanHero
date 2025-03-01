import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  _WorkerHomeScreenState createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<WasteReport> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // Fetch the tasks (waste reports) from Firestore
  Future<void> fetchTasks() async {
    try {
      String? workerUid = _auth.currentUser?.uid;

      if (workerUid == null) {
        print('Worker UID not found.');
        return;
      }

      final snapshot = await _firestore
          .collection('waste_reports')
          .where('assignedWorker', isEqualTo: workerUid)
          .get();

      setState(() {
        tasks = snapshot.docs.map((doc) {
          return WasteReport(
            id: doc.id,
            description: doc['description'] ?? '',
            imageBase64: doc['imageBase64'] ?? '',
            location: doc['location'] ?? '',
            timestamp: (doc['timestamp'] != null) ? doc['timestamp'].toDate() : DateTime.now(),
            wasteSize: doc['wasteSize'] ?? '',
            status: doc['status'] ?? 'pending', // ✅ Default to 'pending' if null
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profilew'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profilew');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('My Performance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/perform');
              },
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(task: task, onUpdate: fetchTasks);
        },
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final WasteReport task;
  final VoidCallback onUpdate;

  TaskCard({super.key, required this.task, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task #${task.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Description: ${task.description}'),
            const SizedBox(height: 8),
            _buildImage(task.imageBase64),
            const SizedBox(height: 8),
            Text('Location: ${task.location}'),
            const SizedBox(height: 8),
            Text('Waste Size: ${task.wasteSize}'),
            const SizedBox(height: 8),
            Text('Reported At: ${task.timestamp}'),
            const SizedBox(height: 8),
            Text(
              'Status: ${task.status}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: task.status == 'completed' ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            if (task.status == 'Assigned')
              ElevatedButton(
                onPressed: () => _updateStatus(context, 'started'),
                child: const Text('Start'),
              ),

            if (task.status == 'started')
              ElevatedButton(
                onPressed: () => _updateStatus(context, 'completed'),
                child: const Text('Complete'),
              ),

            if (task.status == 'completed')
              const Text(
                'Completed ✅',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageBase64) {
    if (imageBase64.isNotEmpty) {
      return Image.memory(
        const Base64Decoder().convert(imageBase64),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(child: Text('No Image Available')),
      );
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (status == 'completed') {
        await _uploadImage(context, ImageSource.camera); // Pass context here

        if (imageBase64.isEmpty) {
          print("⚠️ No image captured!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected. Please try again.')),
          );
          return;
        }

        // Update Firestore in "waste_reports"
        await _firestore.collection('waste_reports').doc(task.id).update({
          'status': 'completed',
          'completedImageBase64': imageBase64,
        });

        // Save completed report in "reported_issues"
        await _firestore.collection('reported_issues').doc(task.id).set({
          'description': task.description,
          'location': task.location,
          'timestamp': task.timestamp,
          'wasteSize': task.wasteSize,
          'imageBase64': task.imageBase64, // Original waste image
          'completedImageBase64': imageBase64, // Cleaned area image
          'status': 'completed',
        });

      } else {
        await _firestore.collection('waste_reports').doc(task.id).update({
          'status': 'started',
        });
      }

      onUpdate(); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }


  final ImagePicker _picker = ImagePicker();
  String imageBase64 = '';

  Future<void> _uploadImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      final File imgFile = File(image.path);
      final List<int> imageBytes = await imgFile.readAsBytes();
      imageBase64 = base64Encode(imageBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }


}

// WasteReport Model
class WasteReport {
  final String id;
  final String description;
  final String imageBase64;
  final String location;
  final DateTime timestamp;
  final String wasteSize;
  final String status;

  WasteReport({
    required this.id,
    required this.description,
    required this.imageBase64,
    required this.location,
    required this.timestamp,
    required this.wasteSize,
    required this.status, // ✅ Default value
  });
}
