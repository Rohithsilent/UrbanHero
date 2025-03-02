import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Standings extends StatefulWidget {
  const Standings({Key? key}) : super(key: key);

  @override
  State<Standings> createState() => _StandingsState();
}

class _StandingsState extends State<Standings> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> userRankings = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRankings();
  }

  Future<void> _fetchUserRankings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all waste reports grouped by userId
      final reportsSnapshot = await _firestore.collection('waste_reports').get();

      // Map to store user data: userId -> {completedReports, totalReports, username}
      Map<String, Map<String, dynamic>> userStats = {};

      // Process all waste reports
      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final status = data['status'] as String;

        // Initialize user stats if not already present
        if (!userStats.containsKey(userId)) {
          userStats[userId] = {
            'completedReports': 0,
            'totalReports': 0,
            'userId': userId,
            'username': 'Unknown User', // Default name, will be updated later
            'role': '', // Will be updated when we fetch user info
          };
        }

        // Update stats
        userStats[userId]!['totalReports'] = (userStats[userId]!['totalReports'] as int) + 1;

        // Count completed reports
        if (status == 'completed') {
          userStats[userId]!['completedReports'] = (userStats[userId]!['completedReports'] as int) + 1;
        }
      }

      // Get user info for all users and filter only citizens
      List<Map<String, dynamic>> citizenRankings = [];

      for (String userId in userStats.keys) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              // Update user info
              if (userData.containsKey('username')) {
                userStats[userId]!['username'] = userData['username'];
              }

              // Check if user is a citizen and only include citizens
              if (userData.containsKey('role') && userData['role'] == 'Citizen') {
                userStats[userId]!['role'] = userData['role'];
                citizenRankings.add(userStats[userId]!);
              }
            }
          }
        } catch (e) {
          print('Error fetching user info for $userId: $e');
        }
      }

      // Sort by completed reports (descending) and then by total reports (ascending)
      citizenRankings.sort((a, b) {
        int completedComparison = (b['completedReports'] as int).compareTo(a['completedReports'] as int);
        if (completedComparison != 0) {
          return completedComparison; // Sort by completed reports first
        }
        // If same number of completed reports, prioritize the one with fewer total reports
        return (a['totalReports'] as int).compareTo(b['totalReports'] as int);
      });

      // Add rank to each user
      for (int i = 0; i < citizenRankings.length; i++) {
        citizenRankings[i]['rank'] = i + 1;
      }

      setState(() {
        userRankings = citizenRankings;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching rankings: $e');
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading standings: $e');
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

  String _getUserAchievementLevel(int completedReports) {
    if (completedReports >= 20) return 'Earth Guardian';
    if (completedReports >= 15) return 'Eco Warrior';
    if (completedReports >= 10) return 'Community Hero';
    if (completedReports >= 5) return 'Active Citizen';
    return 'Beginner';
  }

  Color _getAchievementColor(int completedReports) {
    if (completedReports >= 20) return Colors.teal;
    if (completedReports >= 15) return Colors.green;
    if (completedReports >= 10) return Colors.blue;
    if (completedReports >= 5) return Colors.amber;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Citizen Rankings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.lightGreenAccent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchUserRankings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightGreenAccent.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Urban Heroes Leaderboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Citizens ranked by completed reports',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top 3 users - displayed prominently
              if (userRankings.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Second place
                      if (userRankings.length >= 2)
                        _buildTopUserCard(userRankings[1], 2, 0.85),

                      // First place
                      _buildTopUserCard(userRankings[0], 1, 1.0),

                      // Third place
                      if (userRankings.length >= 3)
                        _buildTopUserCard(userRankings[2], 3, 0.75),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Divider with label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Complete Rankings', style: TextStyle(color: Colors.black54)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Full list of users
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userRankings.length,
                itemBuilder: (context, index) {
                  final user = userRankings[index];
                  final bool isCurrentUser = currentUser != null &&
                      user['userId'] == currentUser.uid;

                  // Calculate completion percentage safely
                  final int totalReports = user['totalReports'] as int;
                  final int completedReports = user['completedReports'] as int;
                  final double completionPercentage = totalReports > 0
                      ? (completedReports / totalReports * 100)
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: isCurrentUser ? 3 : 1,
                    color: isCurrentUser
                        ? Colors.lightGreenAccent.withOpacity(0.2)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCurrentUser
                          ? const BorderSide(color: Colors.lightGreenAccent, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          '${user['rank']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      title: Text(
                        user['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed: ${user['completedReports']} / ${user['totalReports']} reports',
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getAchievementColor(user['completedReports']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getAchievementColor(user['completedReports']),
                              ),
                            ),
                            child: Text(
                              _getUserAchievementLevel(user['completedReports']),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getAchievementColor(user['completedReports']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${completionPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text('success rate'),
                        ],
                      ),
                    ),
                  );
                },
              ),

              if (userRankings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No citizen data available yet. Start reporting issues to be on the leaderboard!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopUserCard(Map<String, dynamic> user, int rank, double scale) {
    Color medalColor;
    IconData medalIcon;

    switch (rank) {
      case 1:
        medalColor = Colors.amber;
        medalIcon = Icons.emoji_events;
        break;
      case 2:
        medalColor = Colors.grey[400]!;
        medalIcon = Icons.emoji_events;
        break;
      case 3:
        medalColor = Colors.brown[300]!;
        medalIcon = Icons.emoji_events;
        break;
      default:
        medalColor = Colors.grey;
        medalIcon = Icons.emoji_events;
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: medalColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: medalColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    medalIcon,
                    color: medalColor,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: medalColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 24,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user['username'],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getAchievementColor(user['completedReports']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${user['completedReports']} Complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getAchievementColor(user['completedReports']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}