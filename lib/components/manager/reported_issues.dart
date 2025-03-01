import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueReport {
  final String id;
  final String wasteSize;
  final String description;
  final String imageUrl;
  final String location;
  final DateTime timestamp;

  IssueReport({
    required this.id,
    required this.wasteSize,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.timestamp,
  });

  factory IssueReport.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return IssueReport(
      id: doc.id,
      wasteSize: data['wasteSize'] ?? 'Unknown',
      description: data['description'] ?? '',
      imageUrl: data['imageBase64'] ?? '', // Base64 or URL
      location: data['location'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class ReportedIssues extends StatelessWidget {
  const ReportedIssues({super.key});

  Stream<List<IssueReport>> fetchReports() {
    final firestore = FirebaseFirestore.instance;

    return firestore
        .collection('waste_reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => IssueReport.fromFirestore(doc))
          .toList();
    });
  }

  void _showReportDetails(BuildContext context, IssueReport report) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Report Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Report ID', report.id),
                    _buildInfoRow('Waste Size', report.wasteSize),
                    _buildInfoRow('Location', report.location),
                    _buildInfoRow('Date Reported',
                        report.timestamp.toString().split('.')[0]),
                    const SizedBox(height: 15),
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(report.description),
                    if (report.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      const Text(
                        'Attached Image:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImageWidget(report.imageUrl),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      // If the image is a URL
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      );
    } else {
      // If the image is Base64
      try {
        final decodedBytes = base64Decode(imageUrl);
        return Image.memory(
          decodedBytes,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return Container(
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Issues'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<IssueReport>>(
        stream: fetchReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reports found.'));
          } else {
            final reports = snapshot.data!;
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () => _showReportDetails(context, report),
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      'Report #${report.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Size: ${report.wasteSize}'),
                        Text('Location: ${report.location}'),
                        Text(
                            'Date: ${report.timestamp.toString().split('.')[0]}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
