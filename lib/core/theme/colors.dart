import 'package:flutter/material.dart';

/// WiFiPort brand colors
class AppColors {
  // Primary brand colors
  static const Color primaryDark = Color(0xFF004A54);    // Verde petróleo
  static const Color primary = Color(0xFF33C4B4);        // Verde agua
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Extended palette
  static const Color background = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF0D1B1E);
  static const Color surfaceDark = Color(0xFF142328);
  static const Color cardDark = Color(0xFF1A2E33);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Connection quality colors
  static const Color connectionExcellent = Color(0xFF10B981);
  static const Color connectionGood = Color(0xFF84CC16);
  static const Color connectionFair = Color(0xFFF59E0B);
  static const Color connectionPoor = Color(0xFFEF4444);
  
  // Gradient for primary buttons/elements
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceDark, backgroundDark],
  );
}
