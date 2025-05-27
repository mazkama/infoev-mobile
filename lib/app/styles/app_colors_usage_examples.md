# AppColors Usage Examples

## 📋 Cara Menggunakan AppColors di Widget

Berikut adalah contoh-contoh cara menggunakan AppColors dalam widget Flutter Anda:

### 1. Basic Usage

```dart
import 'package:infoev/app/styles/app_colors.dart';

// Container dengan background primary
Container(
  color: AppColors.primaryColor,
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.textOnPrimary),
  ),
)

// Card dengan background dan border
Card(
  color: AppColors.cardBackgroundColor,
  elevation: 4,
  child: Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.borderLight),
      borderRadius: BorderRadius.circular(8),
    ),
    // content here
  ),
)
```

### 2. Text Styling

```dart
// Primary text
Text(
  'Primary Text',
  style: TextStyle(color: AppColors.textColor),
)

// Secondary text
Text(
  'Secondary Text',
  style: TextStyle(color: AppColors.textSecondary),
)

// Tertiary text
Text(
  'Tertiary Text',
  style: TextStyle(color: AppColors.textTertiary),
)
```

### 3. Button Styling

```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonPrimary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  onPressed: () {},
  child: Text('Primary Button'),
)

// Secondary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonSecondary,
    foregroundColor: AppColors.textOnPrimary,
  ),
  onPressed: () {},
  child: Text('Secondary Button'),
)

// Disabled button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonDisabled,
    foregroundColor: AppColors.textTertiary,
  ),
  onPressed: null,
  child: Text('Disabled Button'),
)
```

### 4. Status Colors

```dart
// Success message
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.successColor.withOpacity(0.1),
    border: Border.all(color: AppColors.successColor),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Success Message',
    style: TextStyle(color: AppColors.successColor),
  ),
)

// Error message
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.errorColor.withOpacity(0.1),
    border: Border.all(color: AppColors.errorColor),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Error Message',
    style: TextStyle(color: AppColors.errorColor),
  ),
)

// Warning message
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.warningColor.withOpacity(0.1),
    border: Border.all(color: AppColors.warningColor),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'Warning Message',
    style: TextStyle(color: AppColors.warningColor),
  ),
)
```

### 5. Borders and Dividers

```dart
// Light border
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.borderLight),
    borderRadius: BorderRadius.circular(8),
  ),
  // content here
)

// Medium border
Container(
  decoration: BoxDecoration(
    border: Border.all(color: AppColors.borderMedium, width: 2),
    borderRadius: BorderRadius.circular(8),
  ),
  // content here
)

// Divider
Divider(color: AppColors.dividerColor)
```

### 6. Shadows and Overlays

```dart
// Container with shadow
Container(
  decoration: BoxDecoration(
    color: AppColors.surfaceColor,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  // content here
)

// Modal overlay
Container(
  color: AppColors.overlayColor,
  child: Center(
    child: Container(
      color: AppColors.surfaceColor,
      // modal content
    ),
  ),
)
```

### 7. Shimmer Effect

```dart
// Shimmer loading effect
Container(
  width: double.infinity,
  height: 20,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        AppColors.shimmerBase,
        AppColors.shimmerHighlight,
        AppColors.shimmerBase,
      ],
    ),
    borderRadius: BorderRadius.circular(4),
  ),
)
```

### 8. AppBar Styling

```dart
AppBar(
  backgroundColor: AppColors.surfaceColor,
  foregroundColor: AppColors.textColor,
  elevation: 0,
  title: Text(
    'App Title',
    style: TextStyle(color: AppColors.textColor),
  ),
  iconTheme: IconThemeData(color: AppColors.textColor),
)
```

### 9. Navigation & Links

```dart
// Link text
GestureDetector(
  onTap: () {
    // navigation logic
  },
  child: Text(
    'Click here',
    style: TextStyle(
      color: AppColors.linkColor,
      decoration: TextDecoration.underline,
    ),
  ),
)
```

### 10. Form Elements

```dart
// TextField with AppColors
TextField(
  style: TextStyle(color: AppColors.textColor),
  decoration: InputDecoration(
    hintText: 'Enter text...',
    hintStyle: TextStyle(color: AppColors.textTertiary),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primaryColor),
    ),
    fillColor: AppColors.surfaceColor,
    filled: true,
  ),
)
```

## 🌙 Future Dark Mode Implementation

Struktur sudah disiapkan untuk dark mode:

```dart
// Di main.dart, nanti bisa ditambahkan:
theme: ThemeData(
  colorScheme: AppColors.lightColorScheme,
  useMaterial3: true,
),
darkTheme: ThemeData(
  colorScheme: AppColors.darkColorScheme,
  useMaterial3: true,
),
themeMode: ThemeMode.system, // Mengikuti sistem
```

## 📝 Best Practices

1. **Selalu gunakan AppColors** daripada hardcode warna
2. **Gunakan semantic naming** (primaryColor, textColor, dll)
3. **Konsisten dengan status colors** untuk feedback ke user
4. **Manfaatkan opacity** untuk variasi warna yang sama
5. **Siapkan struktur untuk dark mode** sejak awal

## 🔄 Migration dari Kode Lama

Jika ada kode yang masih menggunakan warna lama:

```dart
// ❌ Lama
Color(0xFF4B0082) // -> ✅ AppColors.primaryColor
Color(0xFFFFA500) // -> ✅ AppColors.accentColor
Colors.white      // -> ✅ AppColors.surfaceColor
Colors.black      // -> ✅ AppColors.textColor
Color(0xFF666666) // -> ✅ AppColors.textSecondary
```
