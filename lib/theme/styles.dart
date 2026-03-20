import 'package:flutter/material.dart';

/// App Color Palette — Premium Islamic-inspired design
class AppColors {
  // Brand
  static const primary = Color(0xFF0D7377); // Deep emerald teal
  static const accent  = Color(0xFFD4A574); // Warm gold

  // Emerald range
  static const emerald      = Color(0xFF115E59); // Deep emerald green
  static const emeraldLight = Color(0xFF14897E); // Lighter emerald for hover/active

  // Gold range
  static const gold      = Color(0xFFC9A96E); // Muted gold
  static const goldLight = Color(0xFFE8D5B0); // Soft gold for subtle highlights

  // Dark surfaces
  static const darkSurface   = Color(0xFF0F1A2E); // Rich navy-black
  static const darkSurfaceAlt = Color(0xFF1A1A2E); // Slightly lighter dark

  // Cream / light tones
  static const cream      = Color(0xFFFFF8E7); // Warm cream
  static const creamMuted = Color(0xFFF5F0E8); // Muted warm white

  // Rose accent
  static const rose      = Color(0xFF8B5E6B); // Dusty rose
  static const roseLight = Color(0xFFA87B87); // Lighter rose

  // Surfaces & backgrounds
  static const background     = Color(0xFFF7F3EE); // Warm off-white
  static const cardBackground = Colors.white;
  static const surface        = cardBackground;

  // Text
  static const textPrimary   = Color(0xFF1A1A2E); // Near-black with warmth
  static const textSecondary = Color(0xFF6B7280); // Slate grey
  static const onSurface     = textPrimary;
  static const onPrimary     = Color(0xFFFFF8E7); // Cream on dark

  // Status
  static const error   = Color(0xFFB91C1C); // Deep red
  static const success = Color(0xFF166534); // Forest green
  static const warning = Color(0xFFB45309); // Amber
  static const info    = Color(0xFF0E7490); // Teal-cyan
  static const white   = Colors.white;

  // Feature colors — Islamic palette
  static const scanner     = Color(0xFF0D7377); // Emerald teal (scan halal)
  static const restaurants = Color(0xFF166534); // Forest green (halal dining)
  static const prayer      = Color(0xFFC9A96E); // Gold (salah / sacred)
  static const events      = Color(0xFF115E59); // Deep emerald (community)
  static const blog        = Color(0xFF8B5E6B); // Dusty rose (editorial)

  // Halal semantics — refined
  static const halal       = Color(0xFF166534); // Rich forest green
  static const haram       = Color(0xFFB91C1C); // Deep crimson
  static const conditional = Color(0xFFB45309); // Warm amber
  static const unknown     = Color(0xFF9CA3AF); // Cool grey

  // Steps
  static const stepDone    = Color(0xFF166534);
  static const stepSkipped = Color(0xFF9CA3AF);
  static const stepActive  = Color(0xFF0D7377);
  static const stepError   = Color(0xFFB91C1C);

  // Five Pillars of Islam
  static const pillarShahadah = Color(0xFFC9A96E); // Gold — declaration of faith
  static const pillarSalah    = Color(0xFF0D7377); // Emerald teal — prayer
  static const pillarZakat    = Color(0xFF166534); // Forest green — charity
  static const pillarSawm     = Color(0xFF1A1A2E); // Deep night — fasting
  static const pillarHajj     = Color(0xFF8B5E6B); // Dusty rose — pilgrimage

  // Dividers & borders
  static const divider    = Color(0xFFE5E0D8); // Warm light border
  static const borderLight = Color(0xFFD6D0C6); // Slightly stronger border
}

/// Spacing & Radius tokens
class AppSpacing {
  static const xs  = 4.0;
  static const s   = 8.0;
  static const m   = 12.0;
  static const l   = 16.0;
  static const xl  = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  static const s   = 8.0;
  static const m   = 12.0;
  static const l   = 16.0;
  static const xl  = 20.0;
  static const xxl = 28.0;
}

/// Text styles — Poppins body / Playfair Display headings concept
/// (Using fontFamily strings; switch to GoogleFonts calls once google_fonts is added)
class AppTextStyles {
  // Display / heading family (Playfair Display concept)
  static const _headingFamily = 'Playfair Display';
  // Body family (Poppins concept)
  static const _bodyFamily = 'Poppins';

  // Title — largest display text
  static const title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: _headingFamily,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // Subtitle — secondary display text
  static const subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: _headingFamily,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Heading — section headers
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: _headingFamily,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  // Card title — for card headers
  static const cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: _headingFamily,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.3,
  );

  // Pillars tab — for Five Pillars navigation
  static const pillarsTab = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFamily: _bodyFamily,
    color: AppColors.gold,
    letterSpacing: 0.8,
    height: 1.4,
  );

  // Body
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: _bodyFamily,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Button
  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: _bodyFamily,
    color: AppColors.onPrimary,
    letterSpacing: 0.3,
  );

  // Error
  static const error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _bodyFamily,
    color: AppColors.error,
  );

  // Success
  static const success = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _bodyFamily,
    color: AppColors.success,
  );

  // Instruction
  static const instruction = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: _bodyFamily,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Caption
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: _bodyFamily,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Label — small uppercase
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontFamily: _bodyFamily,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
    height: 1.4,
  );
}

/// Buttons
class AppButtons {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    textStyle: AppTextStyles.button,
    elevation: 0,
    shadowColor: Colors.transparent,
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    textStyle: AppTextStyles.button,
    elevation: 0,
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.emerald,
    foregroundColor: AppColors.onPrimary,
    minimumSize: const Size(160, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
    textStyle: AppTextStyles.button.copyWith(fontSize: 16),
    elevation: 0,
  );

  static ButtonStyle textButton = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
  );

  static ButtonStyle goldButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.gold,
    foregroundColor: AppColors.darkSurface,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    textStyle: AppTextStyles.button.copyWith(color: AppColors.darkSurface),
    elevation: 0,
  );

  static ButtonStyle outlinedButton = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
    side: const BorderSide(color: AppColors.primary, width: 1.5),
    textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
  );
}

/// Cards
class AppCards {
  static CardTheme card({
    Color backgroundColor = AppColors.cardBackground,
    double elevation = 0,
    double radius = AppRadius.l,
  }) {
    return CardTheme(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: AppColors.divider, width: 0.5),
      ),
      elevation: elevation,
    );
  }

  static List<BoxShadow> modalShadows = [
    BoxShadow(
      blurRadius: 32,
      offset: const Offset(0, 12),
      color: AppColors.darkSurface.withOpacity(0.15),
    ),
    BoxShadow(
      blurRadius: 8,
      offset: const Offset(0, 2),
      color: AppColors.darkSurface.withOpacity(0.06),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      blurRadius: 16,
      offset: const Offset(0, 4),
      color: AppColors.darkSurface.withOpacity(0.08),
    ),
  ];
}

/// Gradients
class AppGradients {
  // Home / general background
  static const homeBackground = LinearGradient(
    colors: [AppColors.primary, AppColors.emerald],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Auth screens — deep immersive background
  static const authBackground = LinearGradient(
    colors: [
      AppColors.darkSurface,
      AppColors.darkSurfaceAlt,
      Color(0xFF0D2B2E), // dark emerald tint
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  // Five Pillars section gradient
  static const pillarGradient = LinearGradient(
    colors: [
      AppColors.pillarShahadah,
      AppColors.pillarSalah,
      AppColors.pillarZakat,
      AppColors.pillarHajj,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Card shimmer / loading effect
  static const cardShimmer = LinearGradient(
    colors: [
      AppColors.creamMuted,
      AppColors.cream,
      AppColors.creamMuted,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Emerald to gold — premium accent gradient
  static const emeraldGold = LinearGradient(
    colors: [AppColors.emerald, AppColors.gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle surface gradient for elevated cards
  static const surfaceGlow = LinearGradient(
    colors: [
      AppColors.cardBackground,
      AppColors.cream,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Input decorations
class AppInput {
  static InputDecoration decoration({
    String? label,
    String? hint,
    IconData? prefix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.l),
      borderSide: const BorderSide(color: AppColors.divider),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary.withOpacity(0.6)),
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      prefixIcon: prefix != null ? Icon(prefix, color: AppColors.primary) : null,
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
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
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        fontSize: 13,
      ),
      shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.3))),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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

  static Color pillarColor(int index) {
    const colors = [
      AppColors.pillarShahadah,
      AppColors.pillarSalah,
      AppColors.pillarZakat,
      AppColors.pillarSawm,
      AppColors.pillarHajj,
    ];
    return colors[index % colors.length];
  }

  static Color featureColor(String feature) {
    switch (feature.toLowerCase()) {
      case 'scanner':     return AppColors.scanner;
      case 'restaurants': return AppColors.restaurants;
      case 'prayer':      return AppColors.prayer;
      case 'events':      return AppColors.events;
      case 'blog':        return AppColors.blog;
      default:            return AppColors.primary;
    }
  }
}
