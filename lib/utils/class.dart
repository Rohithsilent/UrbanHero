class Issue {
  final String issueNumber;
  final String description;
  final String status;
  final String imagePath; // Added field for image path

  Issue({
    required this.issueNumber,
    required this.description,
    required this.status,
    required this.imagePath, // Include image path in constructor
  });
}
