import 'package:flutter/material.dart';

class ReportIssue extends StatefulWidget {
  const ReportIssue({super.key});

  @override
  _ReportIssueState createState() => _ReportIssueState();
}

class _ReportIssueState extends State<ReportIssue> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Waste Issue"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Add padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              items: ['Plastic', 'Organic', 'Metal']
                  .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ))
                  .toList(),
              onChanged: (value) {},
              decoration: const InputDecoration(
                labelText: 'Select Waste Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe the waste issue in your area',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              child: ScaleTransition(
                scale: _buttonScaleAnimation,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
