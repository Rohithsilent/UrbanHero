import 'dart:convert';
import 'dart:io';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../screens/flutter-login.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  _WorkerHomeScreenState createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  List<WasteReport> pendingTasks = [];
  List<WasteReport> completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch the tasks (waste reports) from Firestore
  Future<void> fetchTasks() async {
    setState(() {
      _isLoading = true;
    });

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

      List<WasteReport> allTasks = snapshot.docs.map((doc) {
        return WasteReport(
          id: doc.id,
          description: doc['description'] ?? '',
          imageBase64: doc['imageBase64'] ?? '',
          location: doc['location'] ?? '',
          timestamp: (doc['timestamp'] != null) ? doc['timestamp'].toDate() : DateTime.now(),
          wasteSize: doc['wasteSize'] ?? '',
          status: doc['status'] ?? 'pending',
        );
      }).toList();

      setState(() {
        pendingTasks = allTasks.where((task) => task.status != 'completed').toList();
        completedTasks = allTasks.where((task) => task.status == 'completed').toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Worker Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: fetchTasks,
          ),
          // IconButton(
          //   icon: const Icon(Icons.person, color: Colors.black87),
          //   onPressed: () => Navigator.pushNamed(context, '/profilew'),
          // ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              // icon: Icon(Icons.work),
              text: 'Active (${pendingTasks.length})',
            ),
            Tab(
              // icon: Icon(Icons.check_circle),
              text: 'Completed (${completedTasks.length})',
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Waste Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _auth.currentUser?.email ?? 'Worker',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profilew');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.blue),
                title: const Text('My Performance'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/perform');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  await _auth.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Active Tasks Tab
          _buildTasksList(pendingTasks, isActive: true),

          // Completed Tasks Tab
          _buildTasksList(completedTasks, isActive: false),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<WasteReport> tasks, {required bool isActive}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.work_off : Icons.check_circle_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active tasks' : 'No completed tasks',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ModernTaskCard(
            task: tasks[index],
            onUpdate: fetchTasks,
            isActive: isActive,
          );
        },
      ),
    );
  }
}

class ModernTaskCard extends StatelessWidget {
  final WasteReport task;
  final VoidCallback onUpdate;
  final bool isActive;

  ModernTaskCard({super.key, required this.task, required this.onUpdate, required this.isActive});

  Future<String> _getAddressFromCoordinates(String locationStr) async {
    try {
      // Parse location string (assuming format is "lat,lng")
      List<String> coordinates = locationStr.split(',');
      if (coordinates.length != 2) return locationStr;

      double lat = double.tryParse(coordinates[0].trim()) ?? 0.0;
      double lng = double.tryParse(coordinates[1].trim()) ?? 0.0;

      // Use the geocoding package to get the address
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
      return locationStr;
    } catch (e) {
      print('Error getting address: $e');
      return locationStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with status overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: _buildImage(task.imageBase64),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildStatusChip(task.status),
              ),
            ],
          ),

          // Task details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '#${task.id.substring(0, 5)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location

                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _getAddressFromCoordinates(task.location),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading address...', style: TextStyle(color: Colors.grey[700]));
                          } else if (snapshot.hasData) {
                            return Text(
                              snapshot.data!,
                              style: TextStyle(color: Colors.grey[700]),
                            );
                          } else {
                            return Text(
                              task.location,
                              style: TextStyle(color: Colors.grey[700]),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Waste size and timestamp
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            task.wasteSize,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(task.timestamp),
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Action buttons
                if (isActive) const SizedBox(height: 16),
                if (isActive) _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;
    String statusText;

    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.access_time;
        statusText = 'Pending';
        break;
      case 'Assigned':
        chipColor = Colors.blue;
        chipIcon = Icons.assignment_ind;
        statusText = 'Assigned';
        break;
      case 'started':
        chipColor = Colors.amber;
        chipIcon = Icons.play_arrow;
        statusText = 'In Progress';
        break;
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help_outline;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imageBase64) {
    if (imageBase64.isNotEmpty) {
      return Image.memory(
        const Base64Decoder().convert(imageBase64),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Image Available'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (task.status == 'Assigned') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(context, 'started'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('START TASK'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    } else if (task.status == 'started') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(context, 'completed'),
          icon: const Icon(Icons.check_circle),
          label: const Text('MARK AS COMPLETE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    } else if (task.status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_empty),
          label: const Text('AWAITING ASSIGNMENT'),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  final ImagePicker _picker = ImagePicker();
  String imageBase64 = '';

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (status == 'completed') {
        await _uploadImage(context, ImageSource.camera);

        if (imageBase64.isEmpty) {
          print("⚠️ No image captured!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected. Please take a photo of the completed task.')),
          );
          return;
        }

        // Update Firestore in "waste_reports"
        await _firestore.collection('waste_reports').doc(task.id).update({
          'status': 'completed',
          'completedImageBase64': imageBase64,
          'completedTimestamp': DateTime.now(),
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
          'completedTimestamp': DateTime.now(),
        });

      } else {
        await _firestore.collection('waste_reports').doc(task.id).update({
          'status': status,
          'startedTimestamp': DateTime.now(),
        });
      }

      onUpdate(); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task ${status == 'completed' ? 'completed' : 'started'}'),
          backgroundColor: status == 'completed' ? Colors.green : Colors.blue,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        SnackBar(content: Text('Error capturing image: $e')),
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
    required this.status,
  });
}