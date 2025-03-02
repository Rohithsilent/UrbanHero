import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int userCredits = 0;
  Stream<DocumentSnapshot>? _creditsStream;

  @override
  void initState() {
    super.initState();
    _initializeCreditsStream();
    _initializeReportListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Initialize the credits stream to get real-time updates
  void _initializeCreditsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // First, ensure the user document exists with a credits field
    _firestore.collection('users').doc(currentUser.uid).get().then((docSnapshot) {
      if (!docSnapshot.exists) {
        // Create user document if it doesn't exist
        _firestore.collection('users').doc(currentUser.uid).set({
          'credits': 0,
          'email': currentUser.email,
          'role': 'user', // Default role
        });
      } else if (docSnapshot.data() != null && !docSnapshot.data()!.containsKey('credits')) {
        // Add credits field if it doesn't exist
        _firestore.collection('users').doc(currentUser.uid).update({
          'credits': 0,
        });
      }

      // Now set up the stream
      _creditsStream = _firestore.collection('users').doc(currentUser.uid).snapshots();

      // Listen to the stream
      _creditsStream!.listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final userData = snapshot.data() as Map<String, dynamic>;
          setState(() {
            userCredits = userData['credits'] ?? 0;
          });
        }
      }, onError: (error) {
        print("Error fetching credits: $error");
      });
    }).catchError((error) {
      print("Error initializing user document: $error");
    });
  }

  /// Set up listeners for different report events
  void _initializeReportListeners() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Listen for newly created reports
    _listenForNewReports(currentUser.uid);

    // Listen for completed reports - note lowercase 'c' in "completed"
    _listenForCompletedReports(currentUser.uid);
  }

  /// Listen for new reports and award initial points
  void _listenForNewReports(String userId) {
    _firestore
        .collection('waste_reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Safely access nested properties with null checks
        final bool pointsAwarded = data['initialPointsAwarded'] == true;
        if (!pointsAwarded) {
          _awardInitialPoints(doc.id, userId);
        }
      }
    }, onError: (error) {
      print("Error listening for new reports: $error");
    });
  }

  /// Listen for completed reports and award completion points
  void _listenForCompletedReports(String userId) {
    _firestore
        .collection('waste_reports')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Note the lowercase 'c' in "completed" and proper null-safe access
        final String status = data['status'] as String? ?? '';
        final bool pointsAwarded = data['completionPointsAwarded'] == true;

        if (status == 'completed' && !pointsAwarded) {
          _awardCompletionPoints(doc.id, userId);
        }
      }
    }, onError: (error) {
      print("Error listening for completed reports: $error");
    });
  }

  /// Award initial points for new report submission
  Future<void> _awardInitialPoints(String reportId, String userId) async {
    try {
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Get the latest user document
        DocumentReference userRef = _firestore.collection('users').doc(userId);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        // Get the report reference
        DocumentReference reportRef = _firestore.collection('waste_reports').doc(reportId);

        // Calculate new credits value
        int currentCredits = 0;
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          currentCredits = userData['credits'] as int? ?? 0;
        }

        int newCredits = currentCredits + 10;

        // Update the user's credits
        transaction.update(userRef, {'credits': newCredits});

        // Mark report as awarded
        transaction.update(reportRef, {'initialPointsAwarded': true});
      });

      print("✅ 10 points awarded for new report: $reportId");
    } catch (e) {
      print("Error awarding initial points: $e");
    }
  }

  /// Award completion points for completed reports
  Future<void> _awardCompletionPoints(String reportId, String userId) async {
    try {
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // Get the latest user document
        DocumentReference userRef = _firestore.collection('users').doc(userId);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        // Get the report reference
        DocumentReference reportRef = _firestore.collection('waste_reports').doc(reportId);

        // Calculate new credits value
        int currentCredits = 0;
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          currentCredits = userData['credits'] as int? ?? 0;
        }

        int newCredits = currentCredits + 20;

        // Update the user's credits
        transaction.update(userRef, {'credits': newCredits});

        // Mark report as awarded completion points
        transaction.update(reportRef, {'completionPointsAwarded': true});
      });

      print("✅ 20 points awarded for completed report: $reportId");
    } catch (e) {
      print("Error awarding completion points: $e");
    }
  }

  /// Deduct credits when user buys an item
  Future<void> buyProduct(int productPrice, String productName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Use a transaction to ensure data consistency
      bool success = await _firestore.runTransaction<bool>((transaction) async {
        // Get the latest user document
        DocumentReference userRef = _firestore.collection('users').doc(currentUser.uid);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists || userSnapshot.data() == null) {
          return false;
        }

        // Get current credits with proper casting
        final userData = userSnapshot.data() as Map<String, dynamic>;
        int currentCredits = userData['credits'] as int? ?? 0;

        // Check if user has enough credits
        if (currentCredits < productPrice) {
          return false;
        }

        // Calculate new credits value
        int newCredits = currentCredits - productPrice;

        // Update the user's credits
        transaction.update(userRef, {'credits': newCredits});

        // Add purchase record
        DocumentReference purchaseRef = _firestore.collection('purchases').doc();
        transaction.set(purchaseRef, {
          'userId': currentUser.uid,
          'productName': productName,
          'productPrice': productPrice,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully purchased $productName!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Not enough points to buy $productName!")),
        );
      }
    } catch (e) {
      print("Error buying product: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred while purchasing $productName. Please try again.")),
      );
    }
  }

  final List<Product> products = [
    Product(
      name: 'Plant',
      price: 200,
      description: 'A beautiful indoor plant to brighten up your space.',
      rating: 4.5,
      imageUrl:
      'https://cdn.pixabay.com/photo/2014/12/11/11/14/blumenstock-564132_960_720.jpg',
    ),
    Product(
      name: 'Glass',
      price: 50,
      description: 'A high-quality glass for everyday use.',
      rating: 4.0,
      imageUrl:
      'https://media.istockphoto.com/id/467521964/photo/isolated-shot-of-disposable-coffee-cup-on-white-background.jpg?s=2048x2048&w=is&k=20&c=CpgJrxWRGtA7ID1IBqAv21o6GTAa1EJOmA2v39rgMq0=',
    ),
    Product(
      name: 'Paper',
      price: 25,
      description: 'Recycled paper for all your writing needs.',
      rating: 4.8,
      imageUrl:
      'https://cdn.pixabay.com/photo/2024/01/15/20/51/plate-8510868_1280.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "Cart",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.white),
                const SizedBox(width: 8.0),
                Text(
                  "$userCredits Pts",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.green,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                "${product.price} Pts",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  Text(
                                    "${product.rating.toStringAsFixed(1)}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Buy Now Button
                    ElevatedButton(
                      onPressed: () => buyProduct(product.price, product.name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Buy",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Product Model
class Product {
  final String name;
  final int price;
  final String description;
  final double rating;
  final String imageUrl;

  Product({
    required this.name,
    required this.price,
    required this.description,
    required this.rating,
    required this.imageUrl,
  });
}