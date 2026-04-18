import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF4F8EF7);       // Vibrant blue
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF06B6D4);     // Cyan/teal
  static const Color accent = Color(0xFFF97316);        // Orange accent

  // Backgrounds
  static const Color background = Color(0xFF0D1117);    // Deep dark
  static const Color surface = Color(0xFF161B22);       // Card surface
  static const Color surfaceElevated = Color(0xFF1C2333);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textHint = Color(0xFF484F58);

  // Status
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);

  // Role colors
  static const Color parentColor = Color(0xFF4F8EF7);   // Blue
  static const Color driverColor = Color(0xFF3FB950);   // Green
  static const Color adminColor = Color(0xFFA855F7);    // Purple

  // Divider & border
  static const Color border = Color(0xFF30363D);
  static const Color divider = Color(0xFF21262D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F8EF7), Color(0xFF06B6D4)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1117), Color(0xFF161B22)],
  );

  static const LinearGradient parentGradient = LinearGradient(
    colors: [Color(0xFF4F8EF7), Color(0xFF2563EB)],
  );

  static const LinearGradient driverGradient = LinearGradient(
    colors: [Color(0xFF3FB950), Color(0xFF059669)],
  );

  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
  );
}
