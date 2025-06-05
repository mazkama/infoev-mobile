// filepath: /Users/alfaroo/Flutter/infoev-mobile/lib/app/styles/app_text.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppText class containing all text style definitions for InfoEV app
/// Organized by functional categories with Poppins font and responsive sizing
/// Uses flutter_screenutil for responsive typography across different screen sizes
class AppText {
  // ============================================================================
  // BASE FONT CONFIGURATION
  // ============================================================================

  /// Get TextStyle with Poppins font
  static TextStyle _poppinsStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      color: color ?? AppColors.textColor,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  // ============================================================================
  // DISPLAY TEXT STYLES (Large titles, hero text)
  // ============================================================================

  /// Display Large - For hero sections and major headings
  static TextStyle get displayLarge => _poppinsStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display Medium - For major section titles
  static TextStyle get displayMedium => _poppinsStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// Display Small - For subsection titles
  static TextStyle get displaySmall => _poppinsStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  // ============================================================================
  // HEADLINE TEXT STYLES (Page titles, card headers)
  // ============================================================================

  /// Headline Large - For main page titles
  static TextStyle get headlineLarge =>
      _poppinsStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);

  /// Headline Medium - For section headers
  static TextStyle get headlineMedium =>
      _poppinsStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  /// Headline Small - For card titles and subsections
  static TextStyle get headlineSmall =>
      _poppinsStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);

  // ============================================================================
  // TITLE TEXT STYLES (Component titles, form labels)
  // ============================================================================

  /// Title Large - For prominent component titles
  static TextStyle get titleLarge => _poppinsStyle(fontSize: 16);

  /// Title Medium - For standard component titles
  static TextStyle get titleMedium => _poppinsStyle(fontSize: 14);

  /// Title Small - For small component titles
  static TextStyle get titleSmall => _poppinsStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ============================================================================
  // BODY TEXT STYLES (Content text, descriptions)
  // ============================================================================

  /// Body Large - For main content text
  static TextStyle get bodyLarge =>
      _poppinsStyle(fontSize: 16, fontWeight: FontWeight.w400);

  /// Body Medium - For standard body text
  static TextStyle get bodyMedium =>
      _poppinsStyle(fontSize: 14, fontWeight: FontWeight.w400);

  /// Body Small - For secondary content text
  static TextStyle get bodySmall => _poppinsStyle(fontSize: 13);

  // ============================================================================
  // LABEL TEXT STYLES (Form fields, buttons, badges)
  // ============================================================================

  /// Label Large - For prominent labels and button text
  static TextStyle get labelLarge => _poppinsStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );

  /// Label Medium - For standard labels
  static TextStyle get labelMedium => _poppinsStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );

  /// Label Small - For small labels and captions
  static TextStyle get labelSmall => _poppinsStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ============================================================================
  // APPBAR TEXT STYLES
  // ============================================================================

  /// AppBar Title - For main app bar titles
  static TextStyle get appBarTitle =>
      _poppinsStyle(fontSize: 20, fontWeight: FontWeight.w600);

  /// AppBar Subtitle - For app bar subtitles
  static TextStyle get appBarSubtitle =>
      _poppinsStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.3);

  /// AppBar Action Text - For action buttons in app bar
  static TextStyle get appBarAction =>
      _poppinsStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3);

  // ============================================================================
  // BUTTON TEXT STYLES
  // ============================================================================

  /// Primary Button Text - For main action buttons
  static TextStyle get buttonPrimary => _poppinsStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.2,
  );

  /// Secondary Button Text - For secondary action buttons
  static TextStyle get buttonSecondary => _poppinsStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  /// Small Button Text - For compact buttons
  static TextStyle get buttonSmall => _poppinsStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );

  /// Text Button - For text-only buttons
  static TextStyle get buttonText => _poppinsStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // ============================================================================
  // FORM TEXT STYLES
  // ============================================================================

  /// Input Field Text - For text input content
  static TextStyle get inputText =>
      _poppinsStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4);

  /// Input Label Text - For input field labels
  static TextStyle get inputLabel =>
      _poppinsStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3);

  /// Input Hint Text - For placeholder text
  static TextStyle get inputHint =>
      _poppinsStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4);

  /// Input Error Text - For validation error messages
  static TextStyle get inputError =>
      _poppinsStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3);

  /// Input Helper Text - For helper/description text
  static TextStyle get inputHelper =>
      _poppinsStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3);

  // ============================================================================
  // SPECIAL TEXT STYLES
  // ============================================================================

  /// Caption Text - For image captions, timestamps
  static TextStyle get caption =>
      _poppinsStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3);

  /// Overline Text - For category labels, section headers
  static TextStyle get overline => _poppinsStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 1.5,
  );

  /// Link Text - For clickable links
  static TextStyle get link => _poppinsStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    decoration: TextDecoration.underline,
  );

  /// Error Text - For error messages
  static TextStyle get error => _poppinsStyle(fontSize: 16);

  /// Success Text - For success messages
  static TextStyle get success => _poppinsStyle(fontSize: 16);

  /// Warning Text - For warning messages
  static TextStyle get warning => _poppinsStyle(fontSize: 16);

  /// Warning Text - For warning messages
  static TextStyle get info => _poppinsStyle(fontSize: 16);

  // ============================================================================
  // SPECIFIC PAGE STYLES (Based on JelajahPage.dart analysis)
  // ============================================================================

  /// Brand Card Title - For brand names in cards (16sp)
  static TextStyle get brandCardTitle =>
      _poppinsStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3);

  /// Search Page Title - For search page headings (16sp)
  static TextStyle get searchPageTitle => _poppinsStyle(fontSize: 18);

  /// Search Item Title - For search result titles (14sp)
  static TextStyle get searchItemTitle => _poppinsStyle(fontSize: 15);

  /// Filter Chip Text - For filter chips and small labels (12sp)
  static TextStyle filterChipStyle({required bool isSelected, Color? color}) {
    return _poppinsStyle(
      fontSize: 13,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
  }

  /// Section Header - For section headers in search results (12sp)
  static TextStyle get sectionHeader =>
      _poppinsStyle(fontSize: 13, fontWeight: FontWeight.w600);

  /// Vehicle Count - For "X kendaraan" labels (12sp)
  static TextStyle get vehicleCount =>
      _poppinsStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.3);

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get custom text style with Poppins font
  static TextStyle custom({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      color: color ?? AppColors.textColor,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Apply color to existing text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to existing text style
  static TextStyle withWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }

  /// Apply size to existing text style
  static TextStyle withSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize.sp);
  }

  // ============================================================================
  // THEME INTEGRATION
  // ============================================================================

  /// Get TextTheme for Material Design
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
