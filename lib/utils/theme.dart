import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.green;
  static const Color secondaryColor = Colors.black54;
  static const Color backgroundColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: Colors.grey[200],
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: secondaryColor, fontSize: 16),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}