import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<LatLng> coordinates = [];
  List<Map<String, dynamic>> zones = [];
  String _zoneType = 'restricted';
  TextEditingController latController = TextEditingController();
  TextEditingController longController = TextEditingController();
  TextEditingController zoneNameController = TextEditingController();
  List<Polygon> polygons = [];

  void deleteZone(int index) {
    setState(() {
      zones.removeAt(index);
      polygons.removeAt(index);
    });
  }

  Widget _buildPolygonLayer() {
    // Only create the PolygonLayer if there are polygons to display
    if (polygons.isEmpty && coordinates.isEmpty) {
      return const SizedBox.shrink(); // Return empty widget if no polygons
    }

    List<Polygon> allPolygons = List<Polygon>.from(polygons);

    // Add the current in-progress polygon if there are coordinates
    if (coordinates.isNotEmpty) {
      allPolygons.add(
        Polygon(
          points: coordinates,
          color: _zoneType == 'restricted'
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          borderStrokeWidth: 2.0,
          borderColor: _zoneType == 'restricted'
              ? Colors.red
              : Colors.green,
        ),
      );
    }

    return PolygonLayer(polygons: allPolygons);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MapZones'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(17.380326, 78.382345),
              minZoom: 6.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: coordinates.map(
                      (coordinate) => Marker(
                    point: coordinate,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 30.0,
                    ),
                  ),
                ).toList(),
              ),
              _buildPolygonLayer(), // Use the new method here
            ],
          ),
          DraggableScrollableSheet(
            minChildSize: 0.2,
            maxChildSize: 0.7,
            initialChildSize: 0.5,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  controller: scrollController,
                  children: [
                    TextField(
                      controller: zoneNameController,
                      decoration: const InputDecoration(
                        labelText: 'Zone Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: longController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => _zoneType = 'restricted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _zoneType == 'restricted' ? Colors.red : Colors.grey,
                          ),
                          child: const Text('Restricted'),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() => _zoneType = 'throwable'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _zoneType == 'throwable' ? Colors.green : Colors.grey,
                          ),
                          child: const Text('Throwable'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            double lat = double.tryParse(latController.text) ?? 0.0;
                            double lon = double.tryParse(longController.text) ?? 0.0;
                            if (lat != 0.0 && lon != 0.0) {
                              setState(() {
                                coordinates.add(LatLng(lat, lon));
                              });
                            }
                          },
                          child: const Text('Add Coordinates'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (coordinates.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please add coordinates before creating a zone')),
                              );
                              return;
                            }
                            if (coordinates.length < 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('At least 4 coordinates are required to create a zone')),
                              );
                              return;
                            }
                            setState(() {
                              String zoneName = zoneNameController.text.isEmpty
                                  ? 'Zone ${zones.length + 1}'
                                  : zoneNameController.text;

                              zones.add({
                                'name': zoneName,
                                'coordinates': List.from(coordinates),
                                'type': _zoneType,
                              });

                              polygons.add(
                                Polygon(
                                  points: List.from(coordinates),
                                  color: _zoneType == 'restricted'
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.green.withOpacity(0.5),
                                  borderStrokeWidth: 3.0,
                                  borderColor: _zoneType == 'restricted'
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              );
                              coordinates.clear();
                              zoneNameController.clear();
                            });
                          },
                          child: const Text('Add Zone'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Added Zones:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(zones[index]['name']),
                            subtitle: Text('Coordinates: ${zones[index]['coordinates'].map((coord) => '(${coord.latitude}, ${coord.longitude})').join(', ')}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteZone(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}