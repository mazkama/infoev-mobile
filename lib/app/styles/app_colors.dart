import 'package:flutter/material.dart';

/// AppColors class containing all color definitions for InfoEV app
/// Organized by functional categories for easy maintenance and dark mode future support
class AppColors {
  // ============================================================================
  // PRIMARY COLORS
  // ============================================================================

  /// Main brand color - Purple
  static const Color primaryColor = Color(0xFF6B46C1);

  /// Secondary brand color - Orange
  static const Color secondaryColor = Color(0xFFF97316);

  /// Accent color (same as secondary for consistency)
  static const Color accentColor = Color(0xFFF97316);

  /// Lighter variant of primary color
  static const Color primaryLight = Color(0xFF8B5CF6);

  /// Darker variant of primary color
  static const Color primaryDark = Color(0xFF553C9A);

  /// Lighter variant of primary color
  static const Color secondaryLight = Color(0xFFFF9547);

  /// Darker variant of primary color
  static const Color secondaryDark = Color(0xFFDB5F0B);

  // ============================================================================
  // BACKGROUND & SURFACE COLORS
  // ============================================================================

  /// Main background color
  static const Color backgroundColor = Color(0xFFFAFAFA);

  /// Secondary background color
  static const Color backgroundSecondary = Color(0xFFF5F5F7);

  /// Surface color for cards and containers
  static const Color surfaceColor = Color(0xFFFFFFFF);

  /// Card background color
  static const Color cardBackgroundColor = Color(0xFFFFFFFF);

  /// Elevated card background color
  static const Color cardElevated = Color(0xFFFFFBFF);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  /// Primary text color
  static const Color textColor = Color(0xFF1F2937);

  /// Secondary text color
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary text color (lighter)
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Text color on primary background
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Legacy secondary text color (for backward compatibility)
  static const Color secondaryTextColor = Color(0xFF6B7280);

  // ============================================================================
  // INTERACTIVE ELEMENTS
  // ============================================================================

  /// Primary button color
  static const Color buttonPrimary = Color(0xFF6B46C1);

  /// Secondary button color
  static const Color buttonSecondary = Color(0xFFF97316);

  /// Disabled button color
  static const Color buttonDisabled = Color(0xFFE5E7EB);

  /// Link color
  static const Color linkColor = Color(0xFF3B82F6);

  static Color ChipButtonColor({required bool isSelected}) {
    return isSelected ? Color(0xFFF97316).withAlpha(45) : Color(0xFFF5F5F7);
  }

  /// Chip text color
  static Color ChipTextColor({required bool isSelected}) {
    return isSelected ? Color(0xFFF97316) : Color(0xFF1F2937);
  
  }

  // ============================================================================
  // STATUS COLORS
  // ============================================================================

  /// Success color (green)
  static const Color successColor = Color(0xFF10B981);

  /// Warning color (yellow)
  static const Color warningColor = Color(0xFFF59E0B);

  /// Error color (red)
  static const Color errorColor = Color(0xFFEF4444);

  /// Info color (blue)
  static const Color infoColor = Color(0xFF3B82F6);

  // ============================================================================
  // BORDERS & EFFECTS
  // ============================================================================

  /// Light border color
  static const Color borderLight = Color(0xFFE5E7EB);

  /// Medium border color
  static const Color borderMedium = Color(0xFFD1D5DB);

  /// Divider color
  static const Color dividerColor = Color(0xFFF3F4F6);

  /// Light shadow color
  static const Color shadowLight = Color(0x0F000000);

  /// Medium shadow color
  static const Color shadowMedium = Color(0x1A000000);

  /// Overlay color for modals/dialogs
  static const Color overlayColor = Color(0x4D000000);

  // ============================================================================
  // SHIMMER & LOADING
  // ============================================================================

  /// Shimmer base color
  static const Color shimmerBase = Color(0xFFE5E7EB);

  /// Shimmer highlight color
  static const Color shimmerHighlight = Color(0xFFF9FAFB);

  // ============================================================================
  // THEME HELPERS
  // ============================================================================

  /// Get ColorScheme for light theme
  static ColorScheme get lightColorScheme => ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColor,
    background: backgroundColor,
    error: errorColor,
    onPrimary: textOnPrimary,
    onSecondary: textOnPrimary,
    onSurface: textColor,
    onBackground: textColor,
    onError: textOnPrimary,
  );

  /// Placeholder for future dark theme implementation
  /// TODO: Implement dark color scheme
  static ColorScheme get darkColorScheme => ColorScheme.dark(
    primary: primaryLight,
    secondary: secondaryColor,
    surface: const Color(0xFF1F1F1F),
    background: const Color(0xFF121212),
    error: errorColor,
    onPrimary: textOnPrimary,
    onSecondary: textColor,
    onSurface: textOnPrimary,
    onBackground: textOnPrimary,
    onError: textOnPrimary,
  );
}
