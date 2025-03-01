import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrackIssuesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrackIssuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Your Issues"),
        backgroundColor: Colors.yellowAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('waste_reports').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No issues reported yet."));
          }

          var issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              var issueData = issues[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      if (issueData.containsKey('imageBase64') && (issueData['imageBase64'] as String).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(issueData['imageBase64']),
                            width: double.infinity, // Full width
                            height: 200, // Increased height
                            fit: BoxFit.cover, // Ensures it covers the area properly
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 200,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                        ),

                      const SizedBox(height: 10),

                      // Description Section
                      Text(
                        issueData['description'] ?? 'No description',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),

                      const SizedBox(height: 5),

                      // Details Section
                      Text("Waste Size: ${issueData['wasteSize'] ?? 'Unknown'}"),
                      Text("Location: ${issueData['location'] ?? 'Unknown'}"),

                      Text(
                        "Status: ${issueData['status'] ?? 'Pending'}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: issueData['status'] == 'Resolved' ? Colors.green : Colors.red,
                        ),
                      ),

                      Text(
                        "Reported on: ${issueData['timestamp'] != null ? (issueData['timestamp'] as Timestamp).toDate().toString() : 'Unknown'}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
