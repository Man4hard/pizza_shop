# SlicePOS Flutter App - Setup Guide

## Requirements
- Flutter SDK 3.0+
- Android Studio (for Android) or Xcode (for iOS/macOS)
- Dart SDK (bundled with Flutter)

## 1. Install Dependencies

```bash
flutter pub get
```

## 2. Configure the API URL

Open `lib/services/api_service.dart` and change the base URL to point to your Laravel server:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP/api';
```

Examples:
- Local development: `http://192.168.1.100/api`
- Android emulator connecting to local machine: `http://10.0.2.2/api`
- Production server: `https://yourserver.com/api`

## 3. Run the App

```bash
# For Android
flutter run

# For specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

## 4. Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

## App Structure

```
lib/
├── main.dart              # App entry point & navigation
├── theme/
│   └── app_theme.dart     # Dark theme & colors
├── models/
│   ├── category.dart      # Category model
│   ├── product.dart       # Product model
│   ├── order.dart         # Order, OrderItem, CartItem models
│   └── sale_record.dart   # Sales models
├── services/
│   ├── api_service.dart   # All API calls to Laravel backend
│   └── cart_provider.dart # State management for cart
├── screens/
│   ├── pos_screen.dart    # Main POS ordering screen
│   ├── orders_screen.dart # Orders list (pending/completed/cancelled)
│   ├── sales_screen.dart  # Sales history with date filter
│   └── dashboard_screen.dart # Analytics & daily summary
└── widgets/
    ├── product_card.dart   # Product tile with quantity control
    ├── cart_item_tile.dart # Cart item row (swipe to delete)
    ├── payment_dialog.dart # Payment method & discount dialog
    ├── bill_dialog.dart    # Receipt/bill viewer with print option
    └── stat_card.dart      # Dashboard stat card
```

## Features
- Desktop-first split-screen layout (menu + cart side-by-side)
- Mobile bottom navigation
- Dark themed UI with pizza-red accent color
- Real-time cart with quantity controls
- Customer name, table number, order notes
- Cash, Card, Digital payment options
- Discount support
- Bill/receipt viewer with print button
- Sales history with date range filter
- Dashboard with hourly sales chart & top products
- Swipe-to-delete cart items
