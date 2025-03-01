import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'cart.dart';


class ChatBot {
  String getResponse(String userQuery) {
    String query = userQuery.toLowerCase();

    if (query.contains('recycle')) {
      return 'To recycle correctly, separate your waste into categories like plastic, paper, metal, and organic.';
    } else if (query.contains('points')) {
      return 'You earn points by uploading images of collected waste. These points can be redeemed for eco-friendly products!';
    } else if (query.contains('upload')) {
      return 'To upload an image, use the camera button or gallery option to select a photo of the waste.';
    } else if (query.contains('how to use')) {
      return 'This app helps you report waste issues in your area. Simply fill out the form with waste size, description, photo, and location!';
    } else if (query.contains('hi') || query.contains('hello')) {
      return 'Hello! Welcome to Urban Hero! How can I help you today?';
    } else if (query.contains('location')) {
      return 'Click the "Get Location" button to automatically detect your current location.';
    } else if (query.contains('size')) {
      return 'You can select the waste size from Small, Medium, Large, or Extra Large depending on the amount of waste.';
    } else if (query.contains('waste types')) {
      return 'Our app can classify Plastic Waste, Electronic Waste, Wet Waste, and Garbage. Just upload a clear image!';
    } else {
      return 'I\'m not sure about that. Try asking about recycling, points, uploading images, or how to use the app!';
    }
  }
}

class WasteClassifier {
  static const List<String> labels = [
    'Plastic Waste',
    'Electronic Waste',
    'Wet Waste',
    'Garbage'
  ];

  // This method simulates classification without actually using TF Lite
  static Future<String?> classifyImage(File imageFile) async {
    try {
      // Generate a consistent classification based on the image content
      final bytes = await imageFile.readAsBytes();

      // Create a simple "fingerprint" from the image data
      int sum = 0;
      for (int i = 0; i < bytes.length; i += 100) {  // Sample every 100th byte
        if (i < bytes.length) {
          sum += bytes[i];
        }
      }

      // Select a waste type based on this value
      final index = sum % labels.length;
      return labels[index];
    } catch (e) {
      print('Classification error: $e');
      return null;
    }
  }

  // No actual model loading needed for this implementation
  static Future<void> loadModel() async {
    print('Simple classifier initialized');
    // Nothing to load
  }

  static void disposeModel() {
    // Nothing to dispose
  }
}
class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _WasteReportFormState();
}

class _WasteReportFormState extends State<SecondPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final ChatBot _chatBot = ChatBot();
  final TextEditingController _messageController = TextEditingController();


  // Form fields
  String? wasteSize;
  String description = '';
  String? imageBase64;
  File? imageFile;
  String location = '';
  String city = '';
  bool isLoading = false;
  bool isChatOpen = false;
  String? classifiedWasteType;
  List<Map<String, dynamic>> chatMessages = [];

  // Dropdown options for waste size
  final List<String> wasteSizes = ['Small', 'Medium', 'Large'];

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    chatMessages.add({
      'isBot': true,
      'message': 'Hello! Welcome to Urban Hero! How can I help you today?'
    });

    // Load the TFLite model
    WasteClassifier.loadModel();
  }

  @override
  void dispose() {
    WasteClassifier.disposeModel();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      // Add user message
      chatMessages.add({
        'isBot': false,
        'message': message
      });

      // Add bot response
      String response = _chatBot.getResponse(message);
      chatMessages.add({
        'isBot': true,
        'message': response
      });

      _messageController.clear();
    });
  }

  Future<void> _uploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        isLoading = true;
        classifiedWasteType = null; // Reset classification when uploading a new image
      });

      final File imgFile = File(image.path);
      imageFile = imgFile;
      final List<int> imageBytes = await imgFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);


      String? wasteType = await WasteClassifier.classifyImage(imgFile);



      setState(() {
        imageBase64 = base64Image;
        classifiedWasteType = wasteType;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error uploading image: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        isLoading = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );


      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );


      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String street = place.street ?? 'Unknown Street';
        String city123 = place.locality ?? 'Unknown City';

        setState(() {
          location = '${position.latitude}, ${position.longitude}';  // Store formatted location
          city= '$street,$city123';
          isLoading = false;
        });
      } else {
        setState(() {
          location = 'Location not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error getting location: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _findNearestWorker(LatLng issueLocation) async {
    try {
      final snapshot = await _firestore.collection('users')
          .where('role', isEqualTo: 'Worker')
          .get();

      double minDistance = double.infinity;
      Map<String, dynamic>? nearestWorker;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('location')) {
          LatLng workerLocation = _parseLatLng(data['location']);
          double distance = Geolocator.distanceBetween(
            issueLocation.latitude, issueLocation.longitude,
            workerLocation.latitude, workerLocation.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestWorker = {
              'id': doc.id,
              'username': data['username'],
            };
          }
        }
      }

      return nearestWorker; // Return nearest worker or null if none found
    } catch (e) {
      print("Error finding nearest worker: $e");
      return null;
    }
  }

  LatLng _parseLatLng(String latLngStr) {
    List<String> parts = latLngStr.split(',');
    double lat = double.parse(parts[0].trim());
    double lon = double.parse(parts[1].trim());
    return LatLng(lat, lon);
  }



  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || imageBase64 == null) {
      _showSnackBar('Please fill all fields and add an image');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      LatLng issueLocation = _parseLatLng(location);
      Map<String, dynamic>? nearestWorker = await _findNearestWorker(issueLocation);

      String assignedWorkerId = nearestWorker?['id'] ?? "";
      String assignedWorkerName = nearestWorker?['username'] ?? "Not Assigned";

      // Determine status based on worker assignment
      String status = assignedWorkerId.isNotEmpty ? "Assigned" : "In Progress";

      await _firestore.collection('waste_reports').add({
        'wasteSize': wasteSize,
        'description': description,
        'imageBase64': imageBase64,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
        'wasteType': classifiedWasteType ?? 'Unknown',
        'assignedWorker': assignedWorkerId,
        'assignedWorkerName': assignedWorkerName,
      });

      setState(() {
        isLoading = false;
      });

      _showSnackBar('Report submitted successfully!');

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        imageBase64 = null;
        location = '';
        classifiedWasteType = null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error submitting report: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Urban Hero',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Cart()),
            ),
          ),
          IconButton(
            icon: Icon(
              isChatOpen ? Icons.chat_bubble : Icons.chat_bubble_outline,
              color: Colors.black,
            ),
            onPressed: () => setState(() => isChatOpen = !isChatOpen),
          ),
        ],
        backgroundColor: Colors.lightGreenAccent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.yellowAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Urban Hero',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Making our city cleaner',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.track_changes_sharp, color: Colors.blue),
              title: const Text('Track Your Issues'),
              onTap: () => Navigator.pushNamed(context, '/trackissues'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profilec'),
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.orange),
              title: const Text('Eco Store'),
              onTap: () => Navigator.pushNamed(context, '/cart'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Waste Issue',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Waste Size Dropdown
                          DropdownButtonFormField<String>(
                            value: wasteSize,
                            decoration: InputDecoration(
                              labelText: 'Waste Size',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.straighten),
                            ),
                            items: wasteSizes.map((size) {
                              return DropdownMenuItem(
                                value: size,
                                child: Text(size),
                              );
                            }).toList(),
                            validator: (value) =>
                            value == null ? 'Please select waste size' : null,
                            onChanged: (value) {
                              setState(() {
                                wasteSize = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Description
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
                            validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter a description' : null,
                            onChanged: (value) {
                              description = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Image Upload Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (imageBase64 != null)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    base64Decode(imageBase64!),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (classifiedWasteType != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 10),
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Classified as: $classifiedWasteType',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showImagePickerModal,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(imageBase64 == null ? 'Add Photo' : 'Change Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'Location: $city',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.location_on),
                            label: Text(location.isEmpty ? 'Get Location' : 'Update Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.black,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      'Submit Report',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isChatOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.lightGreenAccent.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Urban Hero Assistant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => isChatOpen = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final message = chatMessages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Align(
                              alignment: message['isBot']
                                  ? Alignment.centerLeft
                                  : Alignment.centerRight,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: message['isBot']
                                      ? Colors.grey[200]
                                      : Colors.lightGreenAccent.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  message['message'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (text) {
                                if (text.isNotEmpty) {
                                  _sendMessage(text);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.lightGreenAccent,
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.black),
                              onPressed: () {
                                final text = _messageController.text.trim();
                                if (text.isNotEmpty) {
                                  _sendMessage(text);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}