import 'package:UrbanHero/components/citizen/standings.dart';
import 'package:UrbanHero/screens/flutter-login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/citizen/cart.dart';
import 'components/citizen/home_screen.dart';
import 'components/citizen/profilec.dart';
import 'components/citizen/throwable.dart';
import 'components/citizen/track_your_issues.dart';
import 'components/manager/manager_home.dart';
import 'components/manager/mappage.dart';
import 'components/manager/profilem.dart';
import 'components/manager/worker_management.dart';
import 'components/worker/detection.dart';
import 'components/worker/profilew.dart';
import 'components/worker/worker_home.dart';
import 'components/worker/worker_stats.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _determineHomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('userRole') ?? 'guest'; // Default role

    switch (userRole) {
      case 'citizen':
        return const SecondPage(); // Citizen Dashboard
      case 'worker':
        return  WorkerHomeScreen(); // Worker Dashboard
      case 'manager':
        return  const ManagerPage(); // Manager Dashboard
      default:
        return  const LoginScreen(); // Redirect to login if no session
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GG',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<Widget>(
        future: _determineHomeScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading app"));
          }
          return snapshot.data ??  const LoginScreen();
        },
      ),
      routes: {

        '/Loginpage': (context) =>  const LoginScreen(),
        '/profilew': (context) =>  const Profilew(),
        '/profilem': (context) =>  const ProfileManager(),
        '/profilec': (context) =>  const Profilec(),
        '/map': (context) => const MapPage(),
        '/throw': (context) =>  const PolyGeofence(),
        '/res': (context) =>  const PolyGeofenceServic(),
        '/citizen-dashboard': (context) =>  const SecondPage(),
        '/perform': (context) =>  const WorkerStatsScreen(),
        '/worker-dashboard': (context) =>  WorkerHomeScreen(),
        '/manager-dashboard': (context) =>  const ManagerPage(),
        '/trackissues': (context) => TrackIssuesPage(),
        '/cart': (context) => Cart(),
        '/assign': (context) => const WorkerManagement(),
        '/Standings': (context) => const Standings(),

      },
    );
  }
}
