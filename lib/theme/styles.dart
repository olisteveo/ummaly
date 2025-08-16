import 'package:flutter/material.dart';

/// App Color Palette
class AppColors {
  // Brand
  static const primary = Color(0xFF6C63FF); // Ummaly purple
  static const accent  = Color(0xFF4CAF50); // green accent

  // Surfaces & backgrounds
  static const background    = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const surface       = cardBackground;

  // Text
  static const textPrimary   = Color(0xFF333333);
  static const textSecondary = Color(0xFF737373);
  static const onSurface     = textPrimary;
  static const onPrimary     = Colors.white;

  // Status
  static const error = Colors.red;
  static const white = Colors.white;

  // Feature colors
  static const scanner     = Color(0xFF6C63FF);
  static const restaurants = Color(0xFF4CAF50);
  static const prayer      = Color(0xFFFF9800);
  static const events      = Color(0xFF009688);
  static const blog        = Color(0xFFE91E63);

  // Halal semantics
  static const halal       = Color(0xFF2E7D32);
  static const haram       = Color(0xFFC62828);
  static const conditional = Color(0xFFEF6C00);
  static const unknown     = Color(0xFF9E9E9E);

  // Steps
  static const stepDone    = Color(0xFF2E7D32);
  static const stepSkipped = Color(0xFF9E9E9E);
  static const stepActive  = Color(0xFF3949AB);
  static const stepError   = Color(0xFFC62828);
}

/// Spacing & Radius tokens
class AppSpacing {
  static const xs = 4.0;
  static const s  = 8.0;
  static const m  = 12.0;
  static const l  = 16.0;
  static const xl = 24.0;
}

class AppRadius {
  static const s  = 8.0;
  static const m  = 12.0;
  static const l  = 16.0;
  static const xl = 20.0;
}

/// Text styles
class AppTextStyles {
  static const heading = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const body    = TextStyle(fontSize: 16, color: AppColors.textPrimary);
  static const button  = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.white);
  static const error   = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error);
  static const success = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.accent);
  static const instruction = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const caption  = TextStyle(fontSize: 12, color: AppColors.textSecondary);
}

/// Buttons
class AppButtons {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    textStyle: AppTextStyles.button,
    elevation: 2,
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.scanner.withOpacity(0.9),
    foregroundColor: AppColors.white,
    minimumSize: const Size(160, 45),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
    textStyle: AppTextStyles.button.copyWith(fontSize: 16),
  );

  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

/// Cards
class AppCards {
  static CardTheme card({ Color backgroundColor = AppColors.cardBackground, double elevation = 2, double radius = AppRadius.l }) {
    return CardTheme(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      elevation: elevation,
    );
  }

  static List<BoxShadow> modalShadows = [
    BoxShadow(blurRadius: 24, offset: const Offset(0, 8), color: Colors.black.withOpacity(0.18)),
  ];
}

/// Gradients
class AppGradients {
  static const homeBackground = LinearGradient(
    colors: [AppColors.primary, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Input decorations (consistent with Scan screens)
class AppInput {
  static InputDecoration decoration({ String? label, String? hint, IconData? prefix }) {
    const borderSide = BorderSide(color: Color(0x1F000000));
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.l), borderSide: borderSide);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
    );
  }
}

/// Misc helpers
class AppStyleHelpers {
  static Color halalStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'halal':       return AppColors.halal;
      case 'haram':       return AppColors.haram;
      case 'conditional': return AppColors.conditional;
      default:            return AppColors.unknown;
    }
  }

  static ChipThemeData statusChipTheme(Color color) {
    return ChipThemeData(
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      shape: StadiumBorder(side: BorderSide(color: color)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  static (IconData, Color) stepVisual(String status) {
    switch (status) {
      case 'done':    return (Icons.check_circle, AppColors.stepDone);
      case 'skipped': return (Icons.remove_circle, AppColors.stepSkipped);
      case 'error':   return (Icons.error, AppColors.stepError);
      default:        return (Icons.more_horiz, AppColors.stepActive);
    }
  }
}
