// import 'package:flutter/material.dart';
// import '../../../services/waste_service.dart';
//
// class WorkerHomeScreen extends StatelessWidget {
//   final WasteService _wasteService = WasteService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Worker Dashboard'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.person),
//             onPressed: () => Navigator.pushNamed(context, '/profile'),
//           ),
//         ],
//       ),
//       body: StreamBuilder<List<WasteReport>>(
//         stream: _wasteService.getWorkerTasks('current_worker_id'), // Replace with actual ID
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//
//           if (!snapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           final tasks = snapshot.data!;
//           return ListView.builder(
//             itemCount: tasks.length,
//             itemBuilder: (context, index) {
//               final task = tasks[index];
//               return TaskCard(task: task);
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// class TaskCard extends StatelessWidget {
//   final WasteReport task;
//
//   const TaskCard({Key? key, required this.task}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.all(8),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'Task #${task.id}',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 _buildStatusChip(task.status),
//               ],
//             ),
//             SizedBox(height: 8),
//             Image.network(
//               task.imageUrl,
//               height: 200,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             SizedBox(height: 8),
//             Text('Location: ${task.location.latitude}, ${task.location.longitude}'),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _updateStatus(context, 'in_progress'),
//                   child: Text('Start'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _updateStatus(context, 'completed'),
//                   child: Text('Complete'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(String status) {
//     Color color;
//     String label;
//
//     switch (status) {
//       case 'pending':
//         color = Colors.orange;
//         label = 'Pending';
//         break;
//       case 'in_progress':
//         color = Colors.blue;
//         label = 'In Progress';
//         break;
//       case 'completed':
//         color = Colors.green;
//         label = 'Completed';
//         break;
//       default:
//         color = Colors.grey;
//         label = 'Unknown';
//     }
//
//     return Chip(
//       label: Text(label),
//       backgroundColor: color.withOpacity(0.2),
//       labelStyle: TextStyle(color: color),
//     );
//   }
//
//   Future<void> _updateStatus(BuildContext context, String status) async {
//     try {
//       final wasteService = WasteService();
//       await wasteService.updateWorkStatus(
//         reportId: task.id,
//         status: status,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Status updated successfully')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to update status')),
//       );
//     }
//   }
// }