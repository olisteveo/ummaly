import 'package:flutter/material.dart';

/// App Color Palette
class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF); // Purple from Ummaly branding
  static const accent = Color(0xFF4CAF50);  // Optional green accent

  // Surfaces & backgrounds
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;

  // Text
  static const text = Color(0xFF333333);
  static const textPrimary = text;
  static const textSecondary = Color(0xFF737373);

  // Status (generic)
  static const error = Colors.red;
  static const white = Colors.white;

  // Feature category colors for dashboard cards
  static const scanner = Color(0xFF6C63FF);
  static const restaurants = Color(0xFF4CAF50);
  static const prayer = Color(0xFFFF9800);
  static const events = Color(0xFF009688);
  static const blog = Color(0xFFE91E63);

  // Optional semantic aliases
  static const surface = cardBackground;
  static const onSurface = textPrimary;
  static const onPrimary = white;

  // ---- New: Halal status semantic colors ----
  static const halal = Color(0xFF2E7D32);        // deep green
  static const haram = Color(0xFFC62828);        // deep red
  static const conditional = Color(0xFFEF6C00);  // amber-ish
  static const unknown = Color(0xFF9E9E9E);      // grey

  // ---- New: Step/status colors for the checklist/overlay ----
  static const stepDone = Color(0xFF2E7D32);
  static const stepSkipped = Color(0xFF9E9E9E);
  static const stepActive = Color(0xFF3949AB);   // indigo-ish
  static const stepError = Color(0xFFC62828);
}

/// App Text Styles
class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
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

  // Style for scan instructions
  static const instruction = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Small, subtle caption (useful for step details)
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

/// App Button Styles
class AppButtons {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
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

  // Smaller button (used for “Scan Again”)
  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.scanner.withOpacity(0.8),
    foregroundColor: AppColors.white,
    minimumSize: const Size(160, 45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: AppTextStyles.button.copyWith(fontSize: 16),
  );

  // Subtle text button (e.g., “Change” or “View details”)
  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

/// App Card Styles (used for dashboard feature cards and product cards)
class AppCards {
  static CardTheme card({
    Color backgroundColor = AppColors.cardBackground,
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

  // Common shadow for modals/overlays
  static List<BoxShadow> modalShadows = [
    BoxShadow(
      blurRadius: 24,
      offset: const Offset(0, 8),
      color: Colors.black.withOpacity(0.25),
    ),
  ];
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

/// Helpers for consistent styling logic across widgets
class AppStyleHelpers {
  /// Map halal status string to a color. Expects lowercase/uppercase variants.
  static Color halalStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'halal':
        return AppColors.halal;
      case 'haram':
        return AppColors.haram;
      case 'conditional':
        return AppColors.conditional;
      case 'unknown':
      default:
        return AppColors.unknown;
    }
  }

  /// Chip style for status badges
  static ChipThemeData statusChipTheme(Color color) {
    return ChipThemeData(
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      shape: StadiumBorder(side: BorderSide(color: color)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  /// Returns an icon + color pair for step states.
  static (IconData, Color) stepVisual(String status) {
    switch (status) {
      case 'done':
        return (Icons.check_circle, AppColors.stepDone);
      case 'skipped':
        return (Icons.remove_circle, AppColors.stepSkipped);
      case 'error':
        return (Icons.error, AppColors.stepError);
      default:
        return (Icons.more_horiz, AppColors.stepActive);
    }
  }
}
