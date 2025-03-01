import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? workerLocation; // Stores latitude,longitude

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🔍 Fetch user's location
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ✅ Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable location services'))
      );
      return;
    }

    // ✅ Request permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied.'))
        );
        return;
      }
    }

    // ✅ Get current location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );

    setState(() {
      workerLocation = "${position.latitude}, ${position.longitude}"; // Store location
    });
  }

  // 📝 Signup function
  Future<void> signupUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Map<String, dynamic> userData = {
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
      };

      // 📌 Store location if user is a Worker
      if (selectedRole == "Worker" && workerLocation != null) {
        userData['location'] = workerLocation;
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!'), backgroundColor: Colors.green),
      );

      switch (selectedRole) {
        case "Citizen":
          Navigator.pushReplacementNamed(context, '/citizen-dashboard');
          break;
        case "Worker":
          Navigator.pushReplacementNamed(context, '/worker-dashboard');
          break;
        case "Manager":
          Navigator.pushReplacementNamed(context, '/manager-dashboard');
          break;
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 24),
                          Text('Create Account', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 24),

                          // Username Input
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              labelText: "Username",
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
                          ),

                          const SizedBox(height: 16),

                          // Email Input
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) => value!.isEmpty || !value.contains('@')
                                ? 'Please enter a valid email'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          // Password Input
                          TextFormField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),

                          const SizedBox(height: 16),

                          // Role Selection
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            decoration: const InputDecoration(labelText: "Select Role"),
                            items: ["Citizen", "Worker", "Manager"].map((role) {
                              return DropdownMenuItem(value: role, child: Text(role));
                            }).toList(),
                            onChanged: (value) async {
                              setState(() {
                                selectedRole = value;
                              });

                              if (value == "Worker") {
                                await _getCurrentLocation();
                              }
                            },
                          ),

                          const SizedBox(height: 24),

                          // Signup Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : () => signupUser(context),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Sign Up"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
