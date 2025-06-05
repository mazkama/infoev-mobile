# 🎨 InfoEV Design System

## 📖 Overview

Sistem design yang komprehensif untuk aplikasi InfoEV Flutter, mencakup color palette dan typography system dengan dukungan responsive design dan dark mode.

## 🗂️ File Structure

```
lib/app/styles/
├── app_colors.dart                 # Color definitions
├── app_text.dart                   # Typography system
├── app_text_usage_examples.md      # Text styles usage examples
└── README.md                       # This documentation
```

## 🎯 Features

### Color System (app_colors.dart)
- ✅ **Comprehensive Color Palette** - 50+ warna yang terorganisir
- ✅ **Semantic Naming** - Nama yang intuitif dan mudah diingat
- ✅ **Categorized Colors** - Dikelompokkan berdasarkan fungsi
- ✅ **Theme Integration** - Terintegrasi dengan ThemeData Flutter
- ✅ **Dark Mode Ready** - Struktur siap untuk implementasi dark mode

### Typography System (app_text.dart)
- ✅ **Poppins Font Family** - Google Fonts integration
- ✅ **Responsive Typography** - Flutter ScreenUtil integration
- ✅ **Hierarchical Structure** - Display > Headline > Title > Body > Label
- ✅ **Special Purpose Styles** - AppBar, Buttons, Forms, Status
- ✅ **Material Design 3** - Compatible dengan TextTheme terbaru
- ✅ **Utility Methods** - Helper functions untuk customization

## 🏗️ Architecture

### Color Categories

1. **Primary Colors** - Warna brand utama
2. **Background & Surface** - Warna background dan surface
3. **Text Colors** - Warna teks dengan hierarki
4. **Interactive Elements** - Warna untuk button dan interaksi
5. **Status Colors** - Warna untuk feedback (success, error, warning, info)
6. **Borders & Effects** - Warna untuk border, shadow, dan efek visual
7. **Shimmer & Loading** - Warna untuk loading states

### Theme Integration

AppColors terintegrasi langsung dengan Flutter ThemeData melalui:
- `AppColors.lightColorScheme` - ColorScheme untuk light theme
- `AppColors.darkColorScheme` - ColorScheme untuk dark theme (placeholder)

## 🚀 Quick Start

### 1. Initialize ScreenUtil

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/styles/app_text.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: AppColors.lightColorScheme,
            textTheme: AppText.textTheme,
            useMaterial3: true,
          ),
          home: YourHomePage(),
        );
      },
    );
  }
}
```

### 2. Import Styles

```dart
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/styles/app_text.dart';
```

### 3. Use Colors

```dart
Container(
  color: AppColors.primaryColor,
  child: Text(
    'Hello InfoEV',
    style: AppText.headlineLarge.copyWith(
      color: AppColors.textOnPrimary,
    ),
  ),
)
```

### 4. Use Typography

```dart
Text('Page Title', style: AppText.headlineLarge),
Text('Body content', style: AppText.bodyMedium),
Text('Button Text', style: AppText.buttonPrimary),
```

## 🎨 Color Reference

### Primary Colors
- `primaryColor` - Main brand purple (#6B46C1)
- `secondaryColor` - Brand orange (#F97316)
- `accentColor` - Same as secondary for consistency
- `primaryLight` - Lighter purple variant (#8B5CF6)
- `primaryDark` - Darker purple variant (#553C9A)

### Background Colors
- `backgroundColor` - Main background (#FAFAFA)
- `backgroundSecondary` - Secondary background (#F5F5F7)
- `surfaceColor` - Surface for cards (#FFFFFF)
- `cardBackgroundColor` - Card background (#FFFFFF)
- `cardElevated` - Elevated card background (#FFFBFF)

### Text Colors
- `textColor` - Primary text (#1F2937)
- `textSecondary` - Secondary text (#6B7280)
- `textTertiary` - Tertiary text (#9CA3AF)
- `textOnPrimary` - Text on primary background (#FFFFFF)

### Status Colors
- `successColor` - Success green (#10B981)
- `warningColor` - Warning yellow (#F59E0B)
- `errorColor` - Error red (#EF4444)
- `infoColor` - Info blue (#3B82F6)

### Interactive Elements
- `buttonPrimary` - Primary button (#6B46C1)
- `buttonSecondary` - Secondary button (#F97316)
- `buttonDisabled` - Disabled button (#E5E7EB)
- `linkColor` - Link color (#3B82F6)

## 📝 Typography Reference

### Display Styles (Hero Text)
- `displayLarge` - 32sp, Bold - Hero sections and major headings
- `displayMedium` - 28sp, SemiBold - Major section titles  
- `displaySmall` - 24sp, SemiBold - Subsection titles

### Headline Styles (Page Titles)
- `headlineLarge` - 22sp, SemiBold - Main page titles
- `headlineMedium` - 20sp, SemiBold - Section headers
- `headlineSmall` - 18sp, SemiBold - Card titles and subsections

### Title Styles (Component Titles)
- `titleLarge` - 16sp, SemiBold - Prominent component titles
- `titleMedium` - 14sp, Medium - Standard component titles
- `titleSmall` - 12sp, Medium - Small component titles

### Body Styles (Content Text)
- `bodyLarge` - 16sp, Regular - Main content text
- `bodyMedium` - 14sp, Regular - Standard body text
- `bodySmall` - 12sp, Regular - Secondary content text

### Label Styles (UI Elements)
- `labelLarge` - 14sp, Medium - Buttons, prominent labels
- `labelMedium` - 12sp, Medium - Standard labels
- `labelSmall` - 10sp, Medium - Small labels and captions

### AppBar Styles
- `appBarTitle` - 20sp, SemiBold - App bar titles
- `appBarSubtitle` - 14sp, Regular - App bar subtitles
- `appBarAction` - 14sp, Medium - Action buttons

### Button Styles
- `buttonPrimary` - 16sp, SemiBold - Main action buttons
- `buttonSecondary` - 16sp, Medium - Secondary buttons
- `buttonSmall` - 14sp, Medium - Compact buttons
- `buttonText` - 14sp, Medium - Text-only buttons

### Special Purpose Styles (Based on actual app usage)
- `pageTitle` - 22sp, Bold - Page headings like "Jelajah"
- `brandCardTitle` - 16sp, Bold - Brand names in cards
- `searchItemTitle` - 14sp, SemiBold - Search result titles
- `filterChip` - 12sp, Regular - Filter chips
- `sectionHeader` - 12sp, SemiBold - Section headers
- `vehicleCount` - 12sp, Regular - Vehicle count labels

### Form Styles
- `inputText` - 16sp, Regular - Input field content
- `inputLabel` - 14sp, Medium - Input labels
- `inputHint` - 16sp, Regular - Placeholder text
- `inputError` - 12sp, Regular - Error messages
- `inputHelper` - 12sp, Regular - Helper text

### Special Styles
- `caption` - 12sp, Regular - Image captions, timestamps
- `overline` - 10sp, Medium - Category labels (ALL CAPS)
- `link` - 14sp, Medium - Clickable links (underlined)
- `error` - 14sp, Medium - Error messages
- `success` - 14sp, Medium - Success messages
- `warning` - 14sp, Medium - Warning messages

### Typography Utilities
```dart
// Custom text style
AppText.custom(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: AppColors.primaryColor,
)

// Modify existing styles
AppText.withColor(AppText.bodyLarge, AppColors.errorColor)
AppText.withWeight(AppText.bodyMedium, FontWeight.bold)
AppText.withSize(AppText.bodyMedium, 18)
```

## 📦 Dependencies

Sistem design ini menggunakan package external berikut:

```yaml
dependencies:
  # Typography & Responsive Design
  flutter_screenutil: ^5.9.0    # Responsive sizing
  google_fonts: ^6.1.0          # Poppins font family
  
  # Core Flutter
  flutter:
    sdk: flutter
```

### Setup Dependencies

Pastikan dependencies sudah ditambahkan di `pubspec.yaml` dan jalankan:

```bash
flutter pub get
```

Struktur sudah disiapkan untuk implementasi dark mode:

```dart
// Di AppColors class sudah ada:
static ColorScheme get darkColorScheme => ColorScheme.dark(
  // Dark color definitions here
);

// Di main.dart nanti bisa ditambahkan:
darkTheme: ThemeData(
  colorScheme: AppColors.darkColorScheme,
  useMaterial3: true,
),
themeMode: ThemeMode.system,
```

## 📱 Responsive Typography

Semua font size menggunakan ScreenUtil untuk responsivitas:

```dart
// Font size otomatis menyesuaikan ukuran layar
AppText.headlineLarge  // 22.sp (responsive)
AppText.bodyMedium     // 14.sp (responsive)

// Untuk custom size
AppText.custom(fontSize: 16) // Otomatis menjadi 16.sp
```

## 🛠️ Implementation Guide

### 1. Initialize in main.dart

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app/styles/app_colors.dart';
import 'app/styles/app_text.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Base design size
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: AppColors.lightColorScheme,
            textTheme: AppText.textTheme,
            useMaterial3: true,
          ),
          home: HomePage(),
        );
      },
    );
  }
}
```

### 2. Using in Widgets

```dart
// Import both systems
import '../styles/app_colors.dart';
import '../styles/app_text.dart';

// Use in widgets
AppBar(
  backgroundColor: AppColors.primaryColor,
  title: Text('InfoEV', style: AppText.appBarTitle),
)

Text('Article Title', style: AppText.headlineMedium)
Text('Body content', style: AppText.bodyMedium)

ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryColor,
  ),
  child: Text('Action', style: AppText.buttonPrimary),
)
```

## 📋 Migration Guide

### From Old Colors

Jika Anda memiliki kode yang menggunakan warna lama:

```dart
// ❌ Before
Color(0xFF4B0082)     // -> ✅ AppColors.primaryColor
Color(0xFFFFA500)     // -> ✅ AppColors.accentColor
Colors.white          // -> ✅ AppColors.surfaceColor
Colors.black          // -> ✅ AppColors.textColor
Color(0xFF666666)     // -> ✅ AppColors.textSecondary
```

### Widget Updates

**PENTING:** Anda TIDAK perlu mengubah kode widget yang sudah ada. AppColors dapat digunakan secara bertahap:

1. Gunakan AppColors untuk widget baru
2. Secara bertahap migrate widget lama saat ada perubahan
3. Kode lama tetap berfungsi normal

## 🛠️ Development Guidelines

### Colors - Do's ✅
- Selalu gunakan AppColors untuk warna baru
- Gunakan semantic naming (textColor, primaryColor, dll)
- Manfaatkan opacity untuk variasi warna
- Konsisten dengan status colors untuk feedback

### Colors - Don'ts ❌
- Jangan hardcode warna hex
- Jangan buat warna baru tanpa menambah ke AppColors
- Jangan ubah warna yang sudah ada tanpa diskusi tim

### Typography - Do's ✅
- Gunakan hierarchy yang konsisten (Display > Headline > Title > Body > Label)
- Pilih text style yang sesuai dengan konteks (appBarTitle untuk AppBar, dll)
- Gunakan AppText.custom() untuk one-off styling
- Test pada berbagai ukuran layar

### Typography - Don'ts ❌
- Jangan hardcode font size tanpa .sp
- Jangan skip hierarchy level (misalnya dari displayLarge ke bodySmall)
- Jangan gunakan text style yang tidak sesuai konteks
- Jangan lupa initialize ScreenUtil

## 📊 Accessibility

### Colors
- ✅ WCAG contrast ratio guidelines
- ✅ Color blindness accessibility
- ✅ Consistent visual hierarchy
- ✅ Brand identity alignment

### Typography
- ✅ Responsive font scaling
- ✅ Proper line heights for readability
- ✅ Sufficient color contrast
- ✅ Appropriate font weights

## 🔮 Future Enhancements

### Color System
- [ ] Dark mode color definitions
- [ ] High contrast theme support
- [ ] Color palette generator tools
- [ ] Automated accessibility testing
- [ ] Dynamic color theming

### Typography System
- [ ] Additional font weight variants
- [ ] Custom font family support
- [ ] Typography animation helpers
- [ ] Advanced responsive breakpoints
- [ ] Text scaling preferences

## 📞 Support

Untuk pertanyaan atau saran:

### Colors
1. Lihat `app_colors_usage_examples.md` (jika ada)
2. Check dokumentasi ini untuk referensi warna
3. Konsultasi dengan tim design untuk perubahan warna

### Typography
1. **Lihat `app_text_usage_examples.md`** untuk contoh lengkap
2. Check dokumentasi ini untuk referensi text styles
3. Test implementasi pada berbagai device size

---

**Created for InfoEV Flutter App**  
**Design System Version: 2.0.0**  
**Last Updated: June 5, 2025**  

### Changelog
- **v2.0.0** - Added comprehensive typography system with Poppins font
- **v1.0.0** - Initial color palette system
