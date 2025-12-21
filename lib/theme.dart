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

class AppTheme {
  // Brand Colors (kept for backwards compatibility)
  static const Color _deepPurple = Color(0xFF673AB7);
  static const Color _vibrantOrange = Color(0xFFFF9800);
  
  // Luxury Dark Mode Palette
  static const Color _darkBackground = Color(0xFF121212); // "OLED" optimized dark
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkSurfaceVariant = Color(0xFF2C2C2C);

  // Use system fonts for instant loading - no font flash!
  // These are universally available on all platforms
  static const String _fontFamily = 'Segoe UI';
  static const List<String> _fontFallback = ['Roboto', 'Helvetica', 'Arial', 'sans-serif'];

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.apply(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _deepPurple,
        primary: _deepPurple,
        secondary: _vibrantOrange,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.grey[50], // Slightly off-white for "Clean" look
      useMaterial3: true,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // For glassmorphism
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600, // Modern weight
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Minimalist
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Soft, friendly, modern
          side: BorderSide(color: Colors.grey.shade200, width: 1), // Subtle definition
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _vibrantOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    // Standard "Material" Dark Mode
    const Color darkBackground = Color(0xFF121212);
    const Color darkSurface = Color(0xFF1E1E1E);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _deepPurple,
        brightness: Brightness.dark,
        primary: Colors.deepPurpleAccent, // Maximum Vibrancy
        secondary: _vibrantOrange,
        surface: darkBackground,
        onSurface: Colors.white,
        primaryContainer: darkSurface,
        onPrimaryContainer: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      useMaterial3: true,
      textTheme: _buildTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _fontFallback,
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1, // Slight elevation for depth
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none, // Remove strict border
        ),
        color: darkSurface, 
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: darkSurface,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _vibrantOrange,
        foregroundColor: Colors.white, 
        elevation: 4,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
    );
  }
}
