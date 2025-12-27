import 'package:flutter/material.dart';

/// Centralized color definitions for the app.
/// Change colors here to update them throughout the app.
class AppColors {
  // ============ BRAND COLORS ============
  /// Primary brand purple (used for FAB selected states, highlights)
  static const Color primaryPurple = Color(0xFF673AB7);  // Deep Purple 500
  
  /// Button purple - lower saturation for dark mode visibility
  static const Color buttonPurple = Color(0xFF7C4DFF);   // Deep Purple Accent 200
  
  /// Light purple for dark mode buttons (even less saturated)
  static Color buttonPurpleDark = Color(0xFF9575CD);     // Deep Purple 300
  
  /// Secondary accent color (orange for FAB, badges)
  static const Color accentOrange = Color(0xFFFF9800);   // Orange 500
  
  // ============ REQUEST/PENDING SECTION COLORS ============
  /// Light mode: Pending request container background
  static Color pendingBgLight = Color(0xFFFFF3E0);       // Orange 50
  
  /// Light mode: Pending request border
  static Color pendingBorderLight = Color(0xFFFFCC80);   // Orange 200
  
  /// Light mode: Pending icon and text
  static Color pendingAccentLight = Color(0xFFF57C00);   // Orange 700
  
  /// Dark mode: Pending request container background
  static Color pendingBgDark = Color(0xFF3D2E00);        // Dark orange-brown
  
  /// Dark mode: Pending request border
  static Color pendingBorderDark = Color(0xFF5D4500);    // Darker orange-brown
  
  /// Dark mode: Pending icon and text
  static Color pendingAccentDark = Color(0xFFFFB74D);    // Orange 300
  
  // ============ SEMANTIC COLORS ============
  static const Color success = Color(0xFF4CAF50);        // Green
  static const Color error = Color(0xFFF44336);          // Red
  static const Color warning = Color(0xFFFF9800);        // Orange
  static const Color info = Color(0xFF2196F3);           // Blue
  
  // ============ HELPER METHODS ============
  /// Get button colors based on brightness
  static Color getButtonBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? buttonPurpleDark : buttonPurple;
  }
  
  /// Get pending section colors based on brightness
  static Color getPendingBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? pendingBgDark : pendingBgLight;
  }
  
  static Color getPendingBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? pendingBorderDark : pendingBorderLight;
  }
  
  static Color getPendingAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? pendingAccentDark : pendingAccentLight;
  }
}
