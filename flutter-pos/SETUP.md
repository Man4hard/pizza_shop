# Ahmed Fast Food POS — Setup Guide

## Overview
**Fully offline** Flutter app for Android & Windows desktop.
No internet, no server, no backend needed — all data is stored locally using SQLite.

---

## Requirements

| Tool | Where to get |
|---|---|
| Flutter SDK (3.x) | https://flutter.dev/docs/get-started/install |
| Android Studio | https://developer.android.com/studio |
| Windows Desktop: Visual Studio Build Tools | https://visualstudio.microsoft.com/downloads/ |

---

## Setup Steps

### 1. Clone the repository
```
git clone https://github.com/Man4hard/pizza_shop.git
cd pizza_shop/flutter-pos
```

### 2. Install dependencies
```
flutter pub get
```

### 3. Run on Android (emulator or real device)
```
flutter run
```

### 4. Build Android APK
```
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### 5. Build for Windows Desktop
```
flutter config --enable-windows-desktop
flutter build windows --release
```
Executable location: `build/windows/x64/runner/Release/ahmed_pos.exe`

---

## First Launch
On first launch the app automatically:
- Creates a local SQLite database on the device/PC
- Seeds all 51 products across 5 categories with correct prices
- Ready to take orders immediately — no configuration needed

---

## Install APK on Android Tablet
1. Copy `app-release.apk` to your tablet via USB or WhatsApp
2. Go to Settings → Security → Enable "Install Unknown Apps"
3. Open the APK and tap Install
4. Done!

---

## Features
- **POS Screen** — Take orders, pick pizza sizes, view cart, print bills
- **Orders Screen** — View pending / completed / cancelled orders
- **Sales History** — Filter by date range, see daily totals
- **Dashboard** — Today's sales, top products, hourly chart
- **Products Manager** — Add / edit / delete products, toggle availability

---

## App Structure

```
lib/
├── main.dart                  # App entry point & SQLite init
├── theme/
│   └── app_theme.dart         # Dark theme & colors
├── models/
│   ├── category.dart
│   ├── product.dart
│   ├── order.dart
│   └── sale_record.dart
├── services/
│   ├── database_service.dart  # ALL local SQLite operations
│   └── cart_provider.dart     # Cart state management
├── screens/
│   ├── pos_screen.dart
│   ├── orders_screen.dart
│   ├── sales_screen.dart
│   ├── dashboard_screen.dart
│   └── products_screen.dart
└── widgets/
    ├── product_card.dart
    ├── cart_item_tile.dart
    ├── payment_dialog.dart
    ├── bill_dialog.dart
    └── stat_card.dart
```

---

## Data Storage
All data is stored in a local SQLite file — no internet required:
- **Android:** `/data/data/com.ahmed.pos/databases/ahmed_pos.db`
- **Windows:** `%LOCALAPPDATA%\ahmed_pos\ahmed_pos.db`

Data persists across restarts and is never lost unless the app is uninstalled.
