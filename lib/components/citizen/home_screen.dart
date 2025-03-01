import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
    } else {
      return 'I\'m not sure about that. Try asking about recycling, points, uploading images, or how to use the app!';
    }
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
  String location = '';
  bool isLoading = false;
  bool isChatOpen = false;
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
      });

      final File imgFile = File(image.path);
      final List<int> imageBytes = await imgFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      setState(() {
        imageBase64 = base64Image;
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

      setState(() {
        location = '${position.latitude}, ${position.longitude}';
        isLoading = false;
      });
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || imageBase64 == null) {
      _showSnackBar('Please fill all fields and add an image');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await _firestore.collection('waste_reports').add({
        'wasteSize': wasteSize,
        'description': description,
        'imageBase64': imageBase64,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(imageBase64!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
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
                            'Location: $location',
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
    ],
      )
    );
  }
}
//
// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:location/location.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'cart.dart';
//
// class ChatBot {
//   String getResponse(String userQuery) {
//     String query = userQuery.toLowerCase();
//
//     if (query.contains('recycle')) {
//       return 'To recycle correctly, separate your waste into categories like plastic, paper, metal, and organic.';
//     } else if (query.contains('points')) {
//       return 'You earn points by uploading images of collected waste. These points can be redeemed for eco-friendly products!';
//     } else if (query.contains('upload')) {
//       return 'To upload an image, go to the “Upload Waste” section, select a photo, and submit!';
//     } else if (query.contains('how to use')) {
//       return 'This app helps you collect, report, and recycle waste. You can also track your points and redeem them for rewards.';
//     } else if (query.contains("hi")) {
//       return 'Hello, Welcome To Urban Hero!';
//     } else {
//       return 'Sorry, I did not understand. Try asking about recycling or points!';
//     }
//   }
// }
//
// class SecondPage extends StatefulWidget {
//   const SecondPage({super.key});
//
//   @override
//   _SecondPageState createState() => _SecondPageState();
// }
//
// class _SecondPageState extends State<SecondPage> {
//   XFile? _selectedImage;
//   LocationData? _locationData;
//   bool _isChatOpen = false;
//   final ChatBot _chatBot = ChatBot();
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, String>> _messages = [];
//   final TextEditingController _volumeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   String? _selectedVolume;
//
//   // Pick image from gallery
//   Future<void> _pickImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       _selectedImage = image;
//     });
//   }
//
//   // Capture image using camera
//   Future<void> _captureImageWithCamera() async {
//     final ImagePicker picker = ImagePicker();
//     try {
//       final XFile? image = await picker.pickImage(source: ImageSource.camera);
//       if (image != null) {
//         setState(() {
//           _selectedImage = image;
//         });
//       } else {
//         print("No image captured.");
//       }
//     } catch (e) {
//       print("Error accessing camera: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Unable to access the camera on this device.")),
//       );
//     }
//   }
//
//   // Get location
//   Future<void> _getLocation() async {
//     final Location location = Location();
//     LocationData locationData = await location.getLocation();
//     setState(() {
//       _locationData = locationData;
//     });
//   }
//
//   // Toggle chat window visibility
//   void _toggleChat() {
//     setState(() {
//       _isChatOpen = !_isChatOpen;
//       if (_messages.isEmpty) {
//         _messages.add({
//           "sender": "ChatBot",
//           "text": _chatBot.getResponse("hello"),
//         });
//       }
//     });
//   }
//
//   // Send message to chatbot
//   void _sendMessage(String message) {
//     setState(() {
//       _messages.add({
//         "sender": "You",
//         "text": message,
//       });
//       String response = _chatBot.getResponse(message);
//       _messages.add({
//         "sender": "ChatBot",
//         "text": response,
//       });
//       _messageController.clear();
//     });
//   }
//
//   // Submit waste details to Firebase
//   Future<void> _submitWasteDetails() async {
//     if (_selectedImage == null || _locationData == null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text("Please complete all fields (image, location, etc.)."),
//       ));
//       return;
//     }
//
//     // Upload image to Firebase Storage
//     final storageRef = FirebaseStorage.instance.ref().child('waste_images/${DateTime.now().toString()}.jpg');
//     await storageRef.putFile(File(_selectedImage!.path));
//     String imageUrl = await storageRef.getDownloadURL();
//
//     // Submit data to Firestore
//     final wasteCollection = FirebaseFirestore.instance.collection('wasteReports');
//     await wasteCollection.add({
//       'volume': _selectedVolume,
//       'description': _descriptionController.text,
//       'imageUrl': imageUrl,
//       'location': {
//         'latitude': _locationData!.latitude,
//         'longitude': _locationData!.longitude,
//       },
//       'timestamp': FieldValue.serverTimestamp(),
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text("Waste reported successfully!"),
//     ));
//
//     // Clear fields after submission
//     setState(() {
//       _selectedImage = null;
//       _locationData = null;
//       _volumeController.clear();
//       _descriptionController.clear();
//     });
//   }
//
//   // Show image preview in a dialog
//   void _showImagePreview() {
//     if (_selectedImage != null) {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return Dialog(
//             backgroundColor: Colors.black,
//             child: Container(
//               color: Colors.black,
//               child: Center(
//                 child: Image.file(
//                   File(_selectedImage!.path),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Urban Hero"),
//         backgroundColor: Colors.yellowAccent,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.shopping_cart),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => Cart()),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.yellowAccent,
//               ),
//               child: Text(
//                 'Menu',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: Icon(Icons.track_changes_sharp),
//               title: Text('Track Your Issues'),
//               onTap: () {
//                 Navigator.pushNamed(context, '/trackissues');
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.contact_page_sharp),
//               title: Text('Profile'),
//               onTap: () {
//                 Navigator.pushNamed(context, '/profilec');
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.store),
//               title: Text('Eco Store'),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => Cart()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: GestureDetector(
//         onTap: () {
//           if (_isChatOpen) {
//             _toggleChat(); // Close the chat if tapping outside
//           }
//         },
//         child: Stack(
//           children: [
//             Center(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Report Waste Issue",
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     SizedBox(height: 20),
//                     DropdownButtonFormField<String>(
//                       value: _selectedVolume, // Replace controller with value
//                       items: ['Large', 'Medium', 'Small']
//                           .map((String value) => DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       ))
//                           .toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedVolume = value; // Store the selected volume
//                         });
//                       },
//                       decoration: InputDecoration(
//                         labelText: 'Select Waste Volume',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     TextField(
//                       controller: _descriptionController,
//                       maxLines: 3,
//                       decoration: InputDecoration(
//                         labelText: 'Describe the waste issue in your area',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         ElevatedButton.icon(
//                           onPressed: _pickImage,
//                           icon: Icon(Icons.upload_file),
//                           label: Text('Upload Image'),
//                         ),
//                         ElevatedButton.icon(
//                           onPressed: _captureImageWithCamera,
//                           icon: Icon(Icons.camera_alt),
//                           label: Text('Capture Image'),
//                         ),
//                       ],
//                     ),
//                     // Preview Button for showing full image in dialog
//                     if (_selectedImage != null)
//                       ElevatedButton(
//                         onPressed: _showImagePreview,
//                         child: Text('Preview Image'),
//                       ),
//                     //Image preview
//                     SizedBox(height: 20),
//                   ElevatedButton.icon(
//                     onPressed: _getLocation,
//                     icon: Icon(Icons.location_on),
//                     label: Text('Get Location'),
//                   ),
//                     if (_locationData != null)
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Text(
//                           'Latitude: ${_locationData!.latitude}, Longitude: ${_locationData!.longitude}',
//                           style: TextStyle(fontSize: 16),
//                         ),
//                       ),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _submitWasteDetails,
//                       child: Text("Submit Waste Issue"),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_isChatOpen)
//               Positioned(
//                 bottom: 0,
//                 child: Container(
//                   width: screenWidth,
//                   height: screenHeight * 0.4,
//                   color: Colors.white,
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: ListView.builder(
//                           itemCount: _messages.length,
//                           itemBuilder: (context, index) {
//                             final message = _messages[index];
//                             return ListTile(
//                               title: Align(
//                                 alignment: message['sender'] == "ChatBot"
//                                     ? Alignment.centerLeft
//                                     : Alignment.centerRight,
//                                 child: Container(
//                                   padding: EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: message['sender'] == "ChatBot"
//                                         ? Colors.grey[300]
//                                         : Colors.blue[200],
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(message['text'] ?? ""),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: _messageController,
//                                 decoration: InputDecoration(
//                                   hintText: 'Ask me anything...',
//                                   border: OutlineInputBorder(),
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.send),
//                               onPressed: () {
//                                 String userMessage = _messageController.text.trim();
//                                 if (userMessage.isNotEmpty) {
//                                   _sendMessage(userMessage);
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
