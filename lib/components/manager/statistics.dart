
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class Statistics extends StatelessWidget {
  final Map<String, double> chartData;

  const Statistics({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            PieChart(
              dataMap: chartData,
              animationDuration: const Duration(milliseconds: 800),
              chartType: ChartType.ring,
              colorList: const [
                Colors.green,
                Colors.red,
                Colors.orange,
              ],
              legendOptions: const LegendOptions(
                showLegends: true,
                legendPosition: LegendPosition.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}