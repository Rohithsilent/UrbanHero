import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
// Add this import at the top of your file
import 'dart:convert';

class WasteReportDashboard extends StatelessWidget {
  final String? userId; // Optional: If you want to filter by user

  const WasteReportDashboard({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Management Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Statistics
            _buildStatisticsSection(context),

            // Status Distribution Chart
            _buildStatusDistributionCard(context),

            // Waste Type Distribution Chart
            _buildWasteTypeDistributionCard(context),

            // Recent Reports List
            _buildRecentReportsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reports found'));
        }

        final reports = snapshot.data!.docs;
        final totalReports = reports.length;

        // Count reports by status
        final Map<String, int> statusCounts = {
          'Not Assigned': 0,
          'Assigned': 0,
          'In Progress': 0,
          'started': 0,
          'completed': 0,
        };

        for (var doc in reports) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'Not Assigned';
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }

        // Calculate completion rate
        final completionRate = totalReports > 0
            ? (statusCounts['completed'] ?? 0) / totalReports * 100
            : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    'Total Reports',
                    totalReports.toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'Completion Rate',
                    '${completionRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    'Pending Action',
                    (statusCounts['Not Assigned'] ?? 0).toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'In Progress',
                    ((statusCounts['In Progress'] ?? 0) +
                        (statusCounts['started'] ?? 0) +
                        (statusCounts['Assigned'] ?? 0)).toString(),
                    Icons.autorenew,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistributionCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reports = snapshot.data!.docs;
        final Map<String, int> statusData = {
          'Not Assigned': 0,
          'Assigned': 0,
          'In Progress': 0,
          'started': 0,
          'completed': 0,
        };

        for (var doc in reports) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'Not Assigned';
          statusData[status] = (statusData[status] ?? 0) + 1;
        }

        final List<PieChartSectionData> sections = [];
        final colors = [
          Colors.red[300]!,
          Colors.orange,
          Colors.amber,
          Colors.blue,
          Colors.green,
        ];

        int i = 0;
        statusData.forEach((key, value) {
          if (value > 0) {
            sections.add(
              PieChartSectionData(
                color: colors[i % colors.length],
                value: value.toDouble(),
                title: '$key\n${value}',
                radius: 80,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }
          i++;
        });

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports by Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: sections.isNotEmpty
                      ? PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  )
                      : const Center(child: Text('No data to display')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWasteTypeDistributionCard(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getReportsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final reports = snapshot.data!.docs;
        final Map<String, int> wasteTypeData = {};

        for (var doc in reports) {
          final data = doc.data() as Map<String, dynamic>;
          final wasteType = data['wasteType'] as String? ?? 'Unknown';
          wasteTypeData[wasteType] = (wasteTypeData[wasteType] ?? 0) + 1;
        }

        final List<BarChartGroupData> barGroups = [];
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.purple,
          Colors.orange,
          Colors.teal,
        ];

        int i = 0;
        wasteTypeData.forEach((key, value) {
          // Create bar groups WITHOUT any visible values
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value.toDouble(),
                  color: colors[i % colors.length],
                  width: 22,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                )
              ],
              // Do NOT set any indicators here
            ),
          );
          i++;
        });

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports by Waste Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 260,
                  child: barGroups.isNotEmpty
                      ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: wasteTypeData.values
                          .fold(0, (max, value) => value > max ? value : max)
                          .toDouble() * 1.2,
                      barGroups: barGroups,
                      // ONLY show values when tapping
                      barTouchData: BarTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey.shade700,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String wasteName = wasteTypeData.keys.elementAt(group.x.toInt());
                            return BarTooltipItem(
                              '${rod.toY.toInt()} reports',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(
                                  text: '\n',
                                ),
                                TextSpan(
                                  text: wasteName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Ensure no indicator persists after tap is released
                        touchCallback: (event, response) {
                          // This can be customized to clear any persistent indicators
                          return;
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < wasteTypeData.keys.length) {
                                String label = wasteTypeData.keys.elementAt(value.toInt());
                                // Split long waste type names
                                if (label.length > 10) {
                                  var words = label.split(' ');
                                  if (words.length > 1) {
                                    // Join first word on first line, rest on second line
                                    label = '${words[0]}\n${words.sublist(1).join(' ')}';
                                  } else if (label.length > 12) {
                                    // For very long single words
                                    label = '${label.substring(0, 10)}...';
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              // Only show integers, not decimals
                              if (value == value.roundToDouble() && value % 2 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        // Explicitly disable top titles to ensure no values show
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 2,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.4)),
                          left: BorderSide(color: Colors.grey.withOpacity(0.4)),
                        ),
                      ),
                    ),
                  )
                      : const Center(child: Text('No data to display')),
                ),

                // Helper text to guide users
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Tap on bars to see number of reports',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentReportsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reports',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full reports list
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _getReportsStream(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No reports found'));
                }

                final reports = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = reports[index].data() as Map<String, dynamic>;
                    final reportId = reports[index].id;
                    final status = data['status'] as String? ?? 'Not Assigned';
                    final wasteType = data['wasteType'] as String? ?? 'Unknown';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final formattedDate = timestamp != null
                        ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                        : 'Pending';

                    return ListTile(
                      title: Text(
                        'Report #${reportId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$wasteType • $formattedDate'),
                      trailing: _buildStatusChip(status),
                      onTap: () {
                        // Navigate to report detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskStatusDetailPage(reportId: reportId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Completed':
        chipColor = Colors.green;
        break;
      case 'Started':
      case 'In Progress':
        chipColor = Colors.blue;
        break;
      case 'Assigned':
        chipColor = Colors.orange;
        break;
      case 'Not Assigned':
      default:
        chipColor = Colors.red;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.all(4),
    );
  }

  // Helper method to get Firestore stream
  Stream<QuerySnapshot> _getReportsStream({int? limit}) {
    Query query = FirebaseFirestore.instance.collection('waste_reports');

    // Apply user filter if provided
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    // Sort by timestamp
    query = query.orderBy('timestamp', descending: true);

    // Apply limit if provided
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }
}

class TaskStatusDetailPage extends StatelessWidget {
  final String reportId;

  const TaskStatusDetailPage({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('waste_reports')
              .doc(reportId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Report not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Not Assigned';
            final timestamp = data['timestamp'] as Timestamp?;
            final formattedDate = timestamp != null
                ? DateFormat('MMM dd, yyyy').format(timestamp.toDate())
                : 'Pending';

            return Column(
              children: [
                // Status tracker visualization
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Status',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Report Date: $formattedDate'),
                        const SizedBox(height: 16),
                        _buildStatusTracker(context, status),
                        const SizedBox(height: 16),
                        _buildStatusDetails(context, data),
                      ],
                    ),
                  ),
                ),

                // Report details
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Waste Type', data['wasteType'] ?? 'Unknown'),
                        _buildDetailRow('Description', data['description'] ?? ''),
                        _buildDetailRow('Location', data['location'] ?? 'Not specified'),
                        _buildDetailRow('Assigned Worker', data['assignedWorkerName'] ?? 'Not assigned'),

                        // Image if available
                        if (data['imageBase64'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Waste Image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(data['imageBase64']),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusTracker(BuildContext context, String currentStatus) {
    // Normalize status for comparison (handle different cases and variants)
    String normalizedStatus = currentStatus.toLowerCase();

    // Map of statuses with their display names and order
    final statusMap = {
      'not assigned': {'display': 'Not Assigned', 'order': 0},
      'assigned': {'display': 'Assigned', 'order': 1},
      'in progress': {'display': 'In Progress', 'order': 2},
      'started': {'display': 'Started', 'order': 3},
      'completed': {'display': 'Completed', 'order': 4},
    };

    // Get current status index (default to 0 if not found)
    final currentIndex = statusMap[normalizedStatus]?['order'] as int? ?? 0;

    // Create properly typed ordered statuses for display
    final List<String> orderedStatuses = [
      statusMap['not assigned']!['display'] as String,
      statusMap['assigned']!['display'] as String,
      statusMap['in progress']!['display'] as String,
      statusMap['started']!['display'] as String,
      statusMap['completed']!['display'] as String,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          orderedStatuses.length,
              (index) {
            final isActive = index <= currentIndex;
            final isLast = index == orderedStatuses.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column for circle and connecting line
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      // Status circle
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? Colors.green.shade700 : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: isActive
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      // Connecting line (if not the last item)
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 30,
                          color: index < currentIndex ? Colors.green : Colors.grey[300],
                        ),
                    ],
                  ),
                ),

                // Status text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderedStatuses[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusDetails(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Not Assigned';

    String message;
    switch (status.toLowerCase()) {
      case 'not assigned':
        message = 'Your report has been received and is waiting to be assigned to a worker.';
        break;
      case 'assigned':
        message = 'A worker has been assigned to your report and will begin work soon.';
        break;
      case 'in progress':
        message = 'Your report is currently being processed by the assigned worker.';
        break;
      case 'started':
        message = 'Work has started at the reported location.';
        break;
      case 'completed':
        message = 'Report Resolved:Report has been fully processed and the issue has been resolved';
        break;
      default:
        message = 'Status update pending.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.toLowerCase() == 'completed' ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: status.toLowerCase() == 'completed' ? Colors.green.shade100 : Colors.blue.shade100
        ),
      ),
      child: Row(
        children: [
          Icon(
              status.toLowerCase() == 'completed' ? Icons.check_circle_outline : Icons.info_outline,
              color: status.toLowerCase() == 'completed' ? Colors.green : Colors.blue
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: status.toLowerCase() == 'completed' ? Colors.green.shade700 : Colors.blue,
                  fontSize: 14
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

