import 'package:flutter/material.dart';

/// App Color Palette
class AppColors {
  static const primary = Color(0xFF6C63FF); // Purple from Ummaly branding
  static const accent = Color(0xFF4CAF50);  // Optional green accent
  static const background = Color(0xFFF5F5F5);
  static const text = Color(0xFF333333);
  static const error = Colors.red;
  static const white = Colors.white;

  // Feature category colors for dashboard cards
  static const scanner = Color(0xFF6C63FF);       // Purple for barcode scanner
  static const restaurants = Color(0xFF4CAF50);   // Green for restaurant lookup
  static const prayer = Color(0xFFFF9800);        // Orange for prayer times
  static const events = Color(0xFF009688);        // Teal for events
  static const blog = Color(0xFFE91E63);          // Pink for blog posts
}

/// App Text Styles
class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static const success = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
  );

  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // NEW: Style for scan instructions
  static const instruction = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );
}

/// App Button Styles
class AppButtons {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: AppTextStyles.button,
  );

  // NEW: Smaller button (used for “Scan Again”)
  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.scanner.withOpacity(0.8),
    foregroundColor: AppColors.white,
    minimumSize: const Size(160, 45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: AppTextStyles.button.copyWith(fontSize: 16),
  );
}

/// App Card Styles (used for dashboard feature cards)
class AppCards {
  static CardTheme card({
    Color backgroundColor = AppColors.primary,
    double elevation = 4,
    double radius = 16,
  }) {
    return CardTheme(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      elevation: elevation,
    );
  }
}

/// App Gradients (for screens like Home)
class AppGradients {
  static const LinearGradient homeBackground = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.accent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

