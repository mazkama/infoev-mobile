# 🎨 InfoEV Color Palette System

## 📖 Overview

Sistem color palette yang komprehensif untuk aplikasi InfoEV Flutter dengan dukungan untuk light theme dan persiapan untuk dark mode di masa depan.

## 🗂️ File Structure

```
lib/app/styles/
├── app_colors.dart                 # Main color definitions
├── app_colors_usage_examples.md    # Usage examples and best practices
└── README.md                       # This documentation
```

## 🎯 Features

- ✅ **Comprehensive Color Palette** - 50+ warna yang terorganisir
- ✅ **Semantic Naming** - Nama yang intuitif dan mudah diingat
- ✅ **Categorized Colors** - Dikelompokkan berdasarkan fungsi
- ✅ **Theme Integration** - Terintegrasi dengan ThemeData Flutter
- ✅ **Dark Mode Ready** - Struktur siap untuk implementasi dark mode
- ✅ **Backward Compatible** - Tidak merusak kode widget yang sudah ada
- ✅ **Well Documented** - Dokumentasi lengkap dan contoh penggunaan

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

### 1. Import AppColors

```dart
import 'package:infoev/app/styles/app_colors.dart';
```

### 2. Use in Widgets

```dart
Container(
  color: AppColors.primaryColor,
  child: Text(
    'Hello InfoEV',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)
```

### 3. Theme Integration

```dart
// Sudah dikonfigurasi di main.dart
theme: ThemeData(
  colorScheme: AppColors.lightColorScheme,
  useMaterial3: true,
),
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

## 🌙 Dark Mode Implementation (Future)

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

### Do's ✅
- Selalu gunakan AppColors untuk warna baru
- Gunakan semantic naming (textColor, primaryColor, dll)
- Manfaatkan opacity untuk variasi warna
- Konsisten dengan status colors untuk feedback

### Don'ts ❌
- Jangan hardcode warna hex
- Jangan buat warna baru tanpa menambah ke AppColors
- Jangan ubah warna yang sudah ada tanpa diskusi tim

## 📊 Color Accessibility

Semua warna sudah dipilih dengan mempertimbangkan:
- ✅ WCAG contrast ratio guidelines
- ✅ Color blindness accessibility
- ✅ Consistent visual hierarchy
- ✅ Brand identity alignment

## 🔮 Future Enhancements

- [ ] Dark mode color definitions
- [ ] High contrast theme support
- [ ] Color palette generator tools
- [ ] Automated accessibility testing
- [ ] Dynamic color theming
- [ ] Color animation helpers

## 📞 Support

Untuk pertanyaan atau saran terkait color system:
1. Lihat `app_colors_usage_examples.md` untuk contoh penggunaan
2. Check dokumentasi ini untuk referensi warna
3. Konsultasi dengan tim design untuk perubahan warna

---

**Created for InfoEV Flutter App**  
Version: 1.0.0  
Last Updated: May 27, 2025
