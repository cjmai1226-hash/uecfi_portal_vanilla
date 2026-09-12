import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark = false;

  // App brand colors: Inspired by Accenture Design System (Electric Violet, Cyber Accents & Deep Obsidian)
  static Color get primaryColor => isDark ? const Color(0xFFA100FF) : const Color(0xFFA100FF);
  static Color get secondaryColor => isDark ? const Color(0xFF00E5FF) : const Color(0xFF7500C0);
  static Color get backgroundColor => isDark ? const Color(0xFF0D0D12) : const Color(0xFFF7F7FA);
  static Color get cardColor => isDark ? const Color(0xFF16161F) : const Color(0xFFFFFFFF);
  static Color get textColor => isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
  static Color get textSecondaryColor => isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
  static Color get borderLightColor => isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

  static ThemeData get lightTheme {
    const primary = Color(0xFFA100FF); // Accenture Electric Violet
    const secondary = Color(0xFF7500C0); // Deep Violet Accent
    const background = Color(0xFFF7F7FA); // Architectural Studio Light Gray
    const card = Color(0xFFFFFFFF);
    const text = Color(0xFF0E0E14); // Ultra-crisp Onyx Text
    const textSecondary = Color(0xFF6E6E82); // Refined Slate Gray Text
    const borderLight = Color(0xFFE5E5ED); // Crisp High-Tech Border

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Graphik',
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: borderLight,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: Color(0xFFFF2A55), // High-Tech Crimson Red
        onError: Colors.white,
        surface: card,
        onSurface: text,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Modern 16px radius
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 6,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: text, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: text, fontSize: 26, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: textSecondary, fontSize: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEEEF4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF2A55), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF2A55), width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFFA100FF); // Accenture Electric Violet
    const darkSecondary = Color(0xFF00E5FF); // Cyber Cyan Accent
    const darkBackground = Color(0xFF0D0D12); // Deep Obsidian Dark Mode
    const darkCard = Color(0xFF16161F); // Dark Graphite Slate Card
    const darkText = Color(0xFFF5F5FA); // High Contrast Pristine Text
    const darkTextSecondary = Color(0xFF9E9EAF); // Purple-Tinted Gray Text
    const darkBorder = Color(0xFF262633); // Subtle Precision Border

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Graphik',
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkBorder,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Colors.white,
        secondary: darkSecondary,
        onSecondary: Colors.white,
        error: Color(0xFFFF2A55),
        onError: Colors.white,
        surface: darkCard,
        onSurface: darkText,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        indicatorColor: darkPrimary,
        labelColor: darkPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: darkBorder,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: darkPrimary.withValues(alpha: 0.18),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary, size: 26);
          }
          return const IconThemeData(color: darkTextSecondary, size: 24);
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkText, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkText, fontSize: 26, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: darkText, fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkText, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: darkText, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF2A55), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF2A55), width: 2),
        ),
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get contentColor => isDarkMode
      ? const Color(0xFFF5F5FA)
      : const Color(0xFF0E0E14);

  Color get secondaryContentColor => isDarkMode
      ? const Color(0xFFA0A0AB)
      : const Color(0xFF6E6E82);
}
