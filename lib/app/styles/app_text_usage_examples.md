# AppText Usage Examples

Panduan lengkap penggunaan sistem typography InfoEV dengan contoh praktis untuk berbagai skenario UI.

## 📋 Table of Contents

1. [Basic Usage](#basic-usage)
2. [AppBar Examples](#appbar-examples)
3. [Button Examples](#button-examples)
4. [Form Examples](#form-examples)
5. [Card & List Examples](#card--list-examples)
6. [Status Messages](#status-messages)
7. [Custom Modifications](#custom-modifications)
8. [Responsive Design](#responsive-design)
9. [Best Practices](#best-practices)

---

## Basic Usage

### Display Text Hierarchy

```dart
// Hero section
Text(
  'Welcome to InfoEV',
  style: AppText.displayLarge,
)

// Page main title
Text(
  'Latest EV News',
  style: AppText.headlineLarge,
)

// Section header
Text(
  'Popular Articles',
  style: AppText.headlineMedium,
)

// Card title
Text(
  'Tesla Model Y Review',
  style: AppText.titleLarge,
)

// Body content
Text(
  'The Tesla Model Y continues to dominate the electric vehicle market with its impressive range and performance.',
  style: AppText.bodyMedium,
)

// Caption
Text(
  'Published 2 hours ago',
  style: AppText.caption,
)
```

### Text Color Variations

```dart
// Primary text
Text('Main content', style: AppText.bodyLarge)

// Secondary text with color
Text(
  'Secondary information',
  style: AppText.bodyMedium.copyWith(
    color: AppColors.textSecondary,
  ),
)

// Tertiary text
Text(
  'Less important info',
  style: AppText.bodySmall.copyWith(
    color: AppColors.textTertiary,
  ),
)
```

---

## AppBar Examples

### Basic AppBar

```dart
AppBar(
  backgroundColor: AppColors.primaryColor,
  title: Text(
    'InfoEV News',
    style: AppText.appBarTitle,
  ),
  actions: [
    TextButton(
      onPressed: () {},
      child: Text(
        'Search',
        style: AppText.appBarAction,
      ),
    ),
  ],
)
```

### AppBar with Subtitle

```dart
AppBar(
  backgroundColor: AppColors.primaryColor,
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'EV Charging',
        style: AppText.appBarTitle,
      ),
      Text(
        '23 stations nearby',
        style: AppText.appBarSubtitle,
      ),
    ],
  ),
)
```

### Custom AppBar with Profile

```dart
AppBar(
  backgroundColor: AppColors.primaryColor,
  title: Text(
    'Profile',
    style: AppText.appBarTitle,
  ),
  actions: [
    IconButton(
      onPressed: () {},
      icon: Icon(Icons.settings, color: AppColors.textOnPrimary),
    ),
    TextButton(
      onPressed: () {},
      child: Text(
        'Edit',
        style: AppText.appBarAction,
      ),
    ),
  ],
)
```

---

## Button Examples

### Primary Action Buttons

```dart
// Main CTA button
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.textOnPrimary,
  ),
  child: Text(
    'Find Charging Station',
    style: AppText.buttonPrimary,
  ),
)

// Secondary button
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.primaryColor),
  ),
  child: Text(
    'View Details',
    style: AppText.buttonSecondary.copyWith(
      color: AppColors.primaryColor,
    ),
  ),
)
```

### Small Buttons

```dart
// Compact button for cards
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondaryColor,
    minimumSize: Size(80, 32),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
  child: Text(
    'Book Now',
    style: AppText.buttonSmall.copyWith(
      color: AppColors.textOnPrimary,
    ),
  ),
)

// Text button
TextButton(
  onPressed: () {},
  child: Text(
    'Learn More',
    style: AppText.buttonText,
  ),
)
```

### Floating Action Button

```dart
FloatingActionButton.extended(
  onPressed: () {},
  backgroundColor: AppColors.primaryColor,
  icon: Icon(Icons.add, color: AppColors.textOnPrimary),
  label: Text(
    'Add Review',
    style: AppText.buttonPrimary,
  ),
)
```

---

## Form Examples

### Text Input Fields

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Input label
    Text(
      'Email Address',
      style: AppText.inputLabel,
    ),
    SizedBox(height: 8),
    
    // Text field
    TextFormField(
      style: AppText.inputText,
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: AppText.inputHint,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
      ),
    ),
    
    // Helper text
    SizedBox(height: 4),
    Text(
      'We will never share your email with anyone',
      style: AppText.inputHelper,
    ),
  ],
)
```

### Form with Validation

```dart
TextFormField(
  style: AppText.inputText,
  decoration: InputDecoration(
    labelText: 'Password',
    labelStyle: AppText.inputLabel,
    hintText: 'Enter your password',
    hintStyle: AppText.inputHint,
    errorStyle: AppText.inputError,
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  },
)
```

### Search Field

```dart
TextField(
  style: AppText.inputText,
  decoration: InputDecoration(
    hintText: 'Search EV models...',
    hintStyle: AppText.inputHint,
    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: AppColors.backgroundSecondary,
  ),
)
```

---

## Card & List Examples

### News Article Card

```dart
Card(
  color: AppColors.surfaceColor,
  elevation: 2,
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Article title
        Text(
          'New Tesla Supercharger Network Expansion',
          style: AppText.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        
        // Article summary
        Text(
          'Tesla announces plans to expand their Supercharger network with 500 new stations across Indonesia.',
          style: AppText.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 12),
        
        // Metadata row
        Row(
          children: [
            Text(
              'Technology',
              style: AppText.overline.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 16),
            Text(
              '3 hours ago',
              style: AppText.caption,
            ),
          ],
        ),
      ],
    ),
  ),
)
```

### EV Station List Item

```dart
ListTile(
  leading: CircleAvatar(
    backgroundColor: AppColors.primaryLight,
    child: Icon(Icons.ev_station, color: AppColors.textOnPrimary),
  ),
  title: Text(
    'PLN Ultra Fast Charging',
    style: AppText.titleMedium,
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Senayan City Mall, Jakarta',
        style: AppText.bodySmall,
      ),
      SizedBox(height: 4),
      Row(
        children: [
          Text(
            'Available',
            style: AppText.labelSmall.copyWith(
              color: AppColors.successColor,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '2.1 km away',
            style: AppText.caption,
          ),
        ],
      ),
    ],
  ),
  trailing: Text(
    'Rp 2,500/kWh',
    style: AppText.labelMedium.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primaryColor,
    ),
  ),
)
```

### Settings Item

```dart
ListTile(
  leading: Icon(Icons.notifications, color: AppColors.textSecondary),
  title: Text(
    'Push Notifications',
    style: AppText.titleMedium,
  ),
  subtitle: Text(
    'Receive updates about charging status',
    style: AppText.bodySmall.copyWith(
      color: AppColors.textSecondary,
    ),
  ),
  trailing: Switch(
    value: true,
    onChanged: (value) {},
    activeColor: AppColors.primaryColor,
  ),
)
```

---

## Status Messages

### Success Message

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.successColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.successColor.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Icon(Icons.check_circle, color: AppColors.successColor),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Charging session started successfully!',
          style: AppText.success,
        ),
      ),
    ],
  ),
)
```

### Error Message

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.errorColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: AppColors.errorColor),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Failed to connect to charging station. Please try again.',
          style: AppText.error,
        ),
      ),
    ],
  ),
)
```

### Warning Banner

```dart
Container(
  width: double.infinity,
  padding: EdgeInsets.all(16),
  color: AppColors.warningColor.withOpacity(0.1),
  child: Row(
    children: [
      Icon(Icons.warning, color: AppColors.warningColor),
      SizedBox(width: 12),
      Expanded(
        child: Text(
          'Battery level is low. Find a charging station nearby.',
          style: AppText.warning,
        ),
      ),
    ],
  ),
)
```

---

## Custom Modifications

### Using Utility Methods

```dart
// Change text color
Text(
  'Custom colored text',
  style: AppText.withColor(AppText.bodyLarge, AppColors.primaryColor),
)

// Change font weight
Text(
  'Bold text',
  style: AppText.withWeight(AppText.bodyMedium, FontWeight.bold),
)

// Change font size
Text(
  'Larger text',
  style: AppText.withSize(AppText.bodyMedium, 18),
)

// Chain modifications
Text(
  'Custom styled text',
  style: AppText.withColor(
    AppText.withWeight(AppText.bodyLarge, FontWeight.w600),
    AppColors.secondaryColor,
  ),
)
```

### Creating Custom Styles

```dart
// One-off custom style
Text(
  'Special heading',
  style: AppText.custom(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
    letterSpacing: 0.5,
  ),
)

// Extending existing style
Text(
  'Modified body text',
  style: AppText.bodyLarge.copyWith(
    color: AppColors.secondaryColor,
    fontStyle: FontStyle.italic,
    decoration: TextDecoration.underline,
  ),
)
```

---

## Responsive Design

### Screen Size Considerations

```dart
// Text automatically scales with ScreenUtil
Text(
  'This text scales responsively',
  style: AppText.headlineLarge, // 22.sp on all devices
)

// Custom responsive sizing
Text(
  'Custom responsive text',
  style: AppText.custom(
    fontSize: 16, // Becomes 16.sp automatically
    fontWeight: FontWeight.w500,
  ),
)
```

### Adaptive Text Layouts

```dart
// Different text sizes for different screen sizes
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      // Tablet layout
      return Text(
        'Large screen title',
        style: AppText.displayLarge,
      );
    } else {
      // Mobile layout
      return Text(
        'Mobile title',
        style: AppText.headlineLarge,
      );
    }
  },
)
```

---

## Best Practices

### ✅ Do's

```dart
// Use semantic text styles
Text('Page Title', style: AppText.headlineLarge)

// Combine with appropriate colors
Text(
  'Error message',
  style: AppText.error, // Already has error color
)

// Use hierarchy consistently
Column(
  children: [
    Text('Main Title', style: AppText.headlineLarge),
    Text('Subtitle', style: AppText.titleMedium),
    Text('Body content', style: AppText.bodyMedium),
  ],
)

// Apply proper contrast
Text(
  'Text on primary background',
  style: AppText.bodyLarge.copyWith(
    color: AppColors.textOnPrimary,
  ),
)
```

### ❌ Don'ts

```dart
// Don't hardcode font sizes
Text(
  'Bad example',
  style: TextStyle(fontSize: 16), // ❌ Not responsive
)

// Don't skip the hierarchy
Column(
  children: [
    Text('Title', style: AppText.displayLarge),
    Text('Subtitle', style: AppText.bodySmall), // ❌ Skips hierarchy
  ],
)

// Don't use conflicting styles
Text(
  'Button text',
  style: AppText.caption, // ❌ Too small for buttons
)
```

### Performance Tips

```dart
// Reuse text styles when possible
final titleStyle = AppText.titleLarge;

ListView.builder(
  itemBuilder: (context, index) {
    return Text(
      items[index].title,
      style: titleStyle, // ✅ Reused style
    );
  },
)

// Cache custom styles
class MyStyles {
  static final specialTitle = AppText.custom(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );
}
```

---

## Common UI Patterns

### Loading States

```dart
// Shimmer text placeholder
Container(
  height: 20,
  width: 200,
  decoration: BoxDecoration(
    color: AppColors.shimmerBase,
    borderRadius: BorderRadius.circular(4),
  ),
)

// Loading text
Text(
  'Loading...',
  style: AppText.bodyMedium.copyWith(
    color: AppColors.textTertiary,
  ),
)
```

### Empty States

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(
      Icons.inbox,
      size: 64,
      color: AppColors.textTertiary,
    ),
    SizedBox(height: 16),
    Text(
      'No charging history',
      style: AppText.titleLarge.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    SizedBox(height: 8),
    Text(
      'Your charging sessions will appear here',
      style: AppText.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      textAlign: TextAlign.center,
    ),
  ],
)
```

---

**Tips for Implementation:**
- Always test text styles on different screen sizes
- Ensure proper contrast ratios for accessibility
- Use semantic styles rather than arbitrary font sizes
- Combine text styles with appropriate colors from AppColors
- Test with different content lengths to ensure proper overflow handling
