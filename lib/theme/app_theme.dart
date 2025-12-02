import 'package:flutter/material.dart';

/// App Design System - Centralized theme and styling
class AppTheme {
  // === COLOR PALETTE ===

  // Primary gradient colors
  static const Color primaryDark = Color(0xFF0D0D1A);
  static const Color primaryMid = Color(0xFF1A1A2E);
  static const Color primaryLight = Color(0xFF16213E);

  // Accent colors
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentPink = Color(0xFFFF2E63);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentPurple = Color(0xFF7B2CBF);

  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);

  // === GRADIENTS ===

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D0D1A),
      Color(0xFF1A1A2E),
      Color(0xFF0F3460),
      Color(0xFF1A1A2E),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentPink],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
  );

  // === TYPOGRAPHY ===

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: white,
    letterSpacing: 4,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: white,
    letterSpacing: 2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: white,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: white,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: white,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: white,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: white70,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: white70,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
    letterSpacing: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: white50,
  );

  // === SPACING ===

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // === BORDER RADIUS ===

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusRound = 100;

  // === SHADOWS ===

  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glowCyan = [
    BoxShadow(
      color: accentCyan.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowPink = [
    BoxShadow(
      color: accentPink.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> glowGold = [
    BoxShadow(
      color: accentGold.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // === DECORATIONS ===

  static BoxDecoration get glassCard => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: white10, width: 1),
    boxShadow: shadowMedium,
  );

  static BoxDecoration glassCardWithBorder(Color borderColor) => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: borderColor, width: 2),
    boxShadow: [
      BoxShadow(
        color: borderColor.withValues(alpha: 0.3),
        blurRadius: 16,
        spreadRadius: 2,
      ),
    ],
  );

  // === ANIMATIONS ===

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  static const Curve animCurve = Curves.easeOutCubic;
}

/// Reusable UI Components
class AppWidgets {
  /// Glass-morphism card container
  static Widget glassCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
      margin: margin,
      decoration: borderColor != null
          ? AppTheme.glassCardWithBorder(borderColor)
          : AppTheme.glassCard,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  /// Primary gradient button
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.glowPink,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.white,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: AppTheme.white, size: 20),
                    const SizedBox(width: AppTheme.spacingS),
                  ],
                  Text(text, style: AppTheme.labelLarge),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary outline button
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? color,
  }) {
    final buttonColor = color ?? AppTheme.white50;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: buttonColor, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: buttonColor, size: 18),
                  const SizedBox(width: AppTheme.spacingS),
                ],
                Text(
                  text,
                  style: AppTheme.labelLarge.copyWith(color: buttonColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section title with optional action
  static Widget sectionTitle(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headlineMedium),
        if (action != null) action,
      ],
    );
  }

  /// Animated icon button
  static Widget iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
    double size = 24,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white10,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Icon(
              icon,
              color: color ?? AppTheme.white,
              size: size,
            ),
          ),
        ),
      ),
    );
  }

  /// Background container with gradient
  static Widget backgroundContainer({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: child,
    );
  }
}
