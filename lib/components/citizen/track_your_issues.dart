import 'dart:io';

import 'package:flutter/material.dart';
import '../../utils/class.dart';

class TrackIssuesPage extends StatelessWidget {
  final List<Issue> issues = [
    Issue(
      issueNumber: 'Issue No. 1',
      description: 'Plastic waste near the park.',
      status: 'In Progress',
      imagePath: 'https://img.freepik.com/premium-photo/spilled-recycling-man-made-garbage-park-forest-near-city-empty-used-dirty-waste-plastic-bottles-caps-bags-carton-paper-boxes-environmental-total-pollution-ecological-problem-global-warming_643018-1042.jpg', // Update with your image path
    ),
    Issue(
      issueNumber: 'Issue No. 2',
      description: 'Organic waste not collected on time.',
      status: 'Resolved',
      imagePath: 'https://static.toiimg.com/thumb/msid-81642167,width-400,resizemode-4/81642167.jpg', // Update with your image path
    ),
    Issue(
      issueNumber: 'Issue No. 3',
      description: 'Huge piles of waste',
      status: 'Pending',
      imagePath: 'https://plus.unsplash.com/premium_photo-1663099654523-d3862b7742cd?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8d2FzdGV8ZW58MHx8MHx8fDA%3D', // Update with your image path
    ),
    // Add more issues as needed
  ];

  TrackIssuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Your Issues"),
        backgroundColor: Colors.yellowAccent,
      ),
      body: ListView.builder(
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              title: Row(
                children: [
                  // Display image with fixed size
                  Container(
                    width: 80, // Fixed width
                    height: 80, // Fixed height
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey), // Optional border
                      image: DecorationImage(
                        image: FileImage(File(issue.imagePath)), // Use FileImage for local files
                        fit: BoxFit.cover, // Cover to fill the container
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between image and text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.issueNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold), // Bold for issue number
                        ),
                        Text(issue.description),
                        const SizedBox(height: 5),
                        Text(
                          'Status: ${issue.status}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: issue.status == 'Resolved' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}