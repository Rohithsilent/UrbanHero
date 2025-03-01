import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();
  final TextEditingController issueController = TextEditingController();

  List<Map<String, dynamic>> reportedIssues = [];
  double _currentZoom = 10.0; // Default zoom level

  @override
  void initState() {
    super.initState();
    _fetchReportedIssues();

    // ✅ Listen for zoom changes and update state
    _mapController.mapEventStream.listen((event) {
      setState(() {
        _currentZoom = _mapController.camera.zoom; // ✅ Update zoom level in state
      });
    });
  }

  // Fetch reported issues from Firestore
  Future<void> _fetchReportedIssues() async {
    try {
      final snapshot = await _firestore.collection('waste_reports').get();
      List<Map<String, dynamic>> issues = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('location')) {
          List<String> latLng = data['location'].split(',');
          double? lat = double.tryParse(latLng[0].trim());
          double? lon = double.tryParse(latLng[1].trim());

          if (lat != null && lon != null) {
            issues.add({
              'id': doc.id,
              'location': LatLng(lat, lon),
              'description': data['description'] ?? "No Description",
              'status': data['status'] ?? "Unassigned",
              'assignedWorkerName': data['assignedWorkerName'] ?? "Not Assigned",
              'formattedAddress': data['formattedAddress'] ?? "Unknown Address",
            });
          }
        }
      }

      setState(() {
        reportedIssues = issues;
      });
    } catch (e) {
      print("Error fetching reported issues: $e");
    }
  }

  // Report a new issue when tapping the map
  void _reportIssue(LatLng point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: TextField(
          controller: issueController,
          decoration: const InputDecoration(labelText: 'Issue Description'),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (issueController.text.isNotEmpty) {
                await _firestore.collection('waste_reports').add({
                  'description': issueController.text,
                  'location': '${point.latitude}, ${point.longitude}',
                  'formattedAddress': 'Fetching...', // Placeholder
                  'status': 'Unassigned',
                });

                _fetchReportedIssues(); // Refresh markers
                Navigator.pop(context);
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Issues Map'),
        backgroundColor: Colors.green,
      ),
      body: FlutterMap(
        mapController: _mapController, // Attach controller
        options: MapOptions(
          initialCenter: const LatLng(17.380326, 78.382345),
          minZoom: 6.0,
          maxZoom: 18.0,
          onTap: (_, point) => _reportIssue(point),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),

          // ✅ Heatmap is always visible
          HeatMapLayer(
            heatMapDataSource: InMemoryHeatMapDataSource(
              data: reportedIssues.expand((issue) {
                LatLng location = issue['location'];
                return [
                  WeightedLatLng(location, 1.0), // Center Point (High Intensity)
                  WeightedLatLng(_offsetLocation(location, 0.5, 0.0), 0.6), // 500m Offset
                  WeightedLatLng(_offsetLocation(location, -0.5, 0.0), 0.6),
                  WeightedLatLng(_offsetLocation(location, 0.0, 0.5), 0.6),
                  WeightedLatLng(_offsetLocation(location, 0.0, -0.5), 0.6),
                  WeightedLatLng(_offsetLocation(location, 1.0, 0.0), 0.3), // 1km Offset
                  WeightedLatLng(_offsetLocation(location, -1.0, 0.0), 0.3),
                  WeightedLatLng(_offsetLocation(location, 0.0, 1.0), 0.3),
                  WeightedLatLng(_offsetLocation(location, 0.0, -1.0), 0.3),
                ];
              }).toList(),
            ),
          ),

          // ✅ Show markers only if zoom level is 14 or higher
          if (_currentZoom >= 14.0)
            MarkerLayer(
              markers: reportedIssues.map((issue) {
                Color markerColor;
                switch (issue['status']) {
                  case 'In Progress':
                    markerColor = Colors.yellow;
                    break;
                  case 'Resolved':
                    markerColor = Colors.green;
                    break;
                  default:
                    markerColor = Colors.red; // Unassigned
                }

                return Marker(
                  point: issue['location'],
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showIssueDetails(issue),
                    child: Icon(Icons.location_on, color: markerColor, size: 35.0),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ✅ Show issue details when a marker is tapped
  void _showIssueDetails(Map<String, dynamic> issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Issue Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("📌 Location: ${issue['formattedAddress']}"),
            Text("📝 Description: ${issue['description']}"),
            Text("📍 Status: ${issue['status']}"),
            Text("👷 Assigned Worker: ${issue['assignedWorkerName']}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  // ✅ Adjust location by km offsets
  LatLng _offsetLocation(LatLng base, double kmNorthSouth, double kmEastWest) {
    const double earthRadius = 6371.0;
    double latOffset = (kmNorthSouth / earthRadius) * (180 / 3.141592653589793);
    double lonOffset = (kmEastWest / earthRadius) * (180 / 3.141592653589793) /
        (cos(base.latitude * 3.141592653589793 / 180));

    return LatLng(base.latitude + latOffset, base.longitude + lonOffset);
  }
}
