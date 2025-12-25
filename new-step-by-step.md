# Flutter Story App - Step by Step Livecode
## JagoFlutter Academy 2026
### Arsitektur Clean Architecture + BLoC + Freezed

---

# OVERVIEW ARSITEKTUR

## Diagram Flow Data: API → BLoC → UI

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER STORY APP                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │   UI/PAGE    │◄───│     BLOC     │◄───│  DATASOURCE  │◄─── API SERVER   │
│  │              │    │              │    │              │                   │
│  │ BlocBuilder  │    │ Event→State │    │ HTTP Client  │                   │
│  │ BlocConsumer │    │ Either<L,R> │    │ Dartz Either │                   │
│  └──────────────┘    └──────────────┘    └──────────────┘                  │
│         │                   │                   │                           │
│         │    dispatch       │      call         │         HTTP              │
│         │    ─────────►     │    ─────────►     │      ─────────►           │
│         │                   │                   │                           │
│         │◄─────────         │◄─────────         │◄─────────                 │
│              emit state          Either              JSON                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Teknologi | Versi | Kegunaan |
|-----------|-------|----------|
| Flutter | 3.10+ | Framework UI |
| flutter_bloc | 9.1.1 | State Management |
| freezed | 3.0.0 | Code Generation untuk Immutable State |
| dartz | 0.10.1 | Functional Programming (Either) |
| http | 1.2.0 | HTTP Client |
| shared_preferences | 2.3.2 | Local Storage |
| image_picker | 1.1.2 | Pilih Gambar |
| cached_network_image | 3.4.1 | Cache Gambar |

## Struktur Folder Project

```
lib/
├── main.dart                         # Entry point aplikasi
├── bloc_providers.dart               # Service locator untuk semua BLoC
├── core/
│   ├── components/                   # Reusable widgets
│   │   ├── app_button.dart
│   │   ├── app_text_field.dart
│   │   └── loading_indicator.dart
│   ├── constants/
│   │   ├── app_colors.dart           # Warna aplikasi
│   │   ├── app_sizes.dart            # Ukuran standar
│   │   └── variables.dart            # API endpoints
│   ├── extensions/
│   │   └── build_context_ext.dart    # Extension untuk navigasi & snackbar
│   └── utils/
│       └── api_handler.dart          # HTTP helper dengan Either
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart    # SharedPreferences
│   │   └── auth_remote_datasource.dart   # API calls auth
│   │   └── story_remote_datasource.dart  # API calls story
│   └── models/
│       ├── auth_response_model.dart
│       ├── user_model.dart
│       ├── story_model.dart
│       └── stories_response_model.dart
└── presentation/
    ├── auth/
    │   ├── blocs/
    │   │   ├── login/
    │   │   │   ├── login_bloc.dart
    │   │   │   ├── login_event.dart
    │   │   │   └── login_state.dart
    │   │   ├── register/
    │   │   │   ├── register_bloc.dart
    │   │   │   ├── register_event.dart
    │   │   │   └── register_state.dart
    │   │   └── logout/
    │   │       ├── logout_bloc.dart
    │   │       ├── logout_event.dart
    │   │       └── logout_state.dart
    │   ├── pages/
    │   │   ├── login_page.dart
    │   │   └── register_page.dart
    │   └── widgets/
    ├── story/
    │   ├── blocs/
    │   │   ├── get_stories/
    │   │   ├── create_story/
    │   │   ├── update_story/
    │   │   └── delete_story/
    │   ├── pages/
    │   │   ├── home_page.dart
    │   │   ├── add_story_page.dart
    │   │   ├── story_detail_page.dart
    │   │   └── edit_story_page.dart
    │   └── widgets/
    │       └── story_card.dart
    ├── profile/
    │   ├── blocs/
    │   │   └── profile/
    │   └── pages/
    │       └── profile_page.dart
    └── splash/
        └── pages/
            └── splash_page.dart
```

---

# BACKEND API DOCUMENTATION

## Base URL
```
http://10.0.2.2:8000/api    # Android Emulator
http://localhost:8000/api    # iOS Simulator
http://192.168.x.x:8000/api  # Physical Device
```

## API Endpoints

### 1. Authentication

#### POST /register
**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (201):**
```json
{
  "status": true,
  "message": "Register berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2024-01-01T00:00:00.000000Z",
      "updated_at": "2024-01-01T00:00:00.000000Z"
    },
    "token": "1|abcdefghijklmnopqrstuvwxyz..."
  }
}
```

#### POST /login
**Request:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Login berhasil",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    },
    "token": "2|abcdefghijklmnopqrstuvwxyz..."
  }
}
```

**Response Error (401):**
```json
{
  "status": false,
  "message": "Email atau password salah"
}
```

#### POST /logout (Protected)
**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Logout berhasil"
}
```

#### GET /profile (Protected)
**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "email_verified_at": null,
  "created_at": "2024-01-01T00:00:00.000000Z",
  "updated_at": "2024-01-01T00:00:00.000000Z"
}
```

### 2. Story Management

#### GET /my-stories (Protected)
**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Daftar cerita saya",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "title": "Judul Cerita",
        "content": "Isi cerita...",
        "image": "stories/abc123.jpg",
        "image_url": "http://localhost:8000/storage/stories/abc123.jpg",
        "created_at": "2024-01-01T00:00:00.000000Z",
        "updated_at": "2024-01-01T00:00:00.000000Z",
        "user": {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com"
        }
      }
    ],
    "last_page": 1,
    "per_page": 10,
    "total": 1
  }
}
```

#### POST /stories (Protected, Multipart)
**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request (Form Data):**
```
title: "Judul Cerita"
content: "Isi cerita lengkap..."
image: (file) gambar.jpg
```

**Response (201):**
```json
{
  "status": true,
  "message": "Cerita berhasil dibuat",
  "data": {
    "id": 1,
    "user_id": 1,
    "title": "Judul Cerita",
    "content": "Isi cerita lengkap...",
    "image": "stories/abc123.jpg",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

#### PUT /stories/{id} (Protected, Multipart dengan _method=PUT)
**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request (Form Data):**
```
_method: PUT
title: "Judul Baru"
content: "Isi cerita yang diupdate..."
image: (file) gambar_baru.jpg (optional)
```

**Response (200):**
```json
{
  "status": true,
  "message": "Cerita berhasil diupdate",
  "data": {
    "id": 1,
    "user_id": 1,
    "title": "Judul Baru",
    "content": "Isi cerita yang diupdate...",
    "image": "stories/xyz789.jpg",
    "user": {...}
  }
}
```

**Response Error (403):**
```json
{
  "status": false,
  "message": "Anda tidak memiliki izin untuk mengupdate cerita ini"
}
```

#### DELETE /stories/{id} (Protected)
**Headers:**
```
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "status": true,
  "message": "Cerita berhasil dihapus"
}
```

---

# PART 1: SETUP PROJECT

## Step 1: Create Flutter Project

```bash
flutter create flutter_story_app
cd flutter_story_app
```

## Step 2: Setup Dependencies

Edit `pubspec.yaml`:

```yaml
name: flutter_story_app
description: Story App SaaS - JagoFlutter Academy

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # HTTP Client
  http: ^1.2.0

  # State Management
  flutter_bloc: ^9.1.1

  # Code Generation untuk Immutable State
  freezed_annotation: ^3.0.0

  # Functional Programming (Either)
  dartz: ^0.10.1

  # Local Storage
  shared_preferences: ^2.3.2

  # Image Picker
  image_picker: ^1.1.2

  # Cached Network Image
  cached_network_image: ^3.4.1

  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

  # Code Generators
  build_runner: ^2.4.8
  freezed: ^3.0.0

flutter:
  uses-material-design: true
```

```bash
flutter pub get
```

## Step 3: Buat Folder Structure

```bash
# Di dalam folder lib/
mkdir -p core/components
mkdir -p core/constants
mkdir -p core/extensions
mkdir -p core/utils
mkdir -p data/datasources
mkdir -p data/models
mkdir -p presentation/auth/blocs/login
mkdir -p presentation/auth/blocs/register
mkdir -p presentation/auth/blocs/logout
mkdir -p presentation/auth/pages
mkdir -p presentation/auth/widgets
mkdir -p presentation/story/blocs/get_stories
mkdir -p presentation/story/blocs/create_story
mkdir -p presentation/story/blocs/update_story
mkdir -p presentation/story/blocs/delete_story
mkdir -p presentation/story/pages
mkdir -p presentation/story/widgets
mkdir -p presentation/profile/blocs/profile
mkdir -p presentation/profile/pages
mkdir -p presentation/splash/pages
```

---

# PART 2: CORE LAYER

## Step 4: API Constants

Buat file `lib/core/constants/variables.dart`:

```dart
class Variables {
  // Ganti dengan IP address komputer kamu
  // Untuk Android Emulator: 10.0.2.2
  // Untuk iOS Simulator: localhost
  // Untuk Device fisik: IP address komputer (misal: 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String profile = '$baseUrl/profile';

  // Story endpoints
  static const String stories = '$baseUrl/stories';
  static const String myStories = '$baseUrl/my-stories';

  static String storyById(int id) => '$baseUrl/stories/$id';
}
```

## Step 5: Colors Constants

Buat file `lib/core/constants/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // Secondary Colors
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondary = Colors.white;

  // Background & Surface
  static const Color background = Color(0xFFFFFBFE);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Status Colors
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFED6C02);

  // Neutral Colors
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF616161);
  static const Color divider = Color(0xFFE0E0E0);

  // Outline
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
}
```

## Step 6: Sizes Constants

Buat file `lib/core/constants/app_sizes.dart`:

```dart
class AppSizes {
  // Padding & Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Font Sizes
  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 20.0;
  static const double fontXxl = 24.0;
  static const double fontDisplay = 32.0;

  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardImageHeight = 200.0;

  // App Bar
  static const double appBarHeight = 56.0;

  // Avatar
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 72.0;
}
```

## Step 7: BuildContext Extensions

Buat file `lib/core/extensions/build_context_ext.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

extension BuildContextExt on BuildContext {
  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  /// Push ke halaman baru
  Future<T?> push<T>(Widget page) {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push dan replace halaman saat ini
  Future<T?> pushReplacement<T>(Widget page) {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push dan hapus semua halaman sebelumnya
  Future<T?> pushAndRemoveUntil<T>(
    Widget page,
    bool Function(Route<dynamic>) predicate,
  ) {
    return Navigator.pushAndRemoveUntil<T>(
      this,
      MaterialPageRoute(builder: (_) => page),
      predicate,
    );
  }

  /// Pop halaman saat ini
  void pop<T>([T? result]) => Navigator.pop<T>(this, result);

  // ═══════════════════════════════════════════════════════════════
  // DEVICE SIZE
  // ═══════════════════════════════════════════════════════════════

  double get deviceHeight => MediaQuery.of(this).size.height;
  double get deviceWidth => MediaQuery.of(this).size.width;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  // ═══════════════════════════════════════════════════════════════
  // SNACKBAR
  // ═══════════════════════════════════════════════════════════════

  void showSnackBar(String message, {Color? backgroundColor, IconData? icon}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void showSuccess(String message) {
    showSnackBar(
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  void showError(String message) {
    showSnackBar(
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error,
    );
  }

  void showWarning(String message) {
    showSnackBar(
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
    );
  }

  void showInfo(String message) {
    showSnackBar(
      message,
      backgroundColor: AppColors.primary,
      icon: Icons.info,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG
  // ═══════════════════════════════════════════════════════════════

  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> showLoadingDialog({String message = 'Loading...'}) {
    return showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
```

## Step 8: Reusable Components

### App Button

Buat file `lib/core/components/app_button.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

enum AppButtonType { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppSizes.buttonHeightMd;

    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Widget button;

    switch (type) {
      case AppButtonType.primary:
        button = FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: child,
        );
        break;

      case AppButtonType.secondary:
        button = FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: AppColors.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: child,
        );
        break;

      case AppButtonType.outlined:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ),
          child: child,
        );
        break;

      case AppButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(isFullWidth ? double.infinity : 0, buttonHeight),
            foregroundColor: AppColors.primary,
          ),
          child: child,
        );
        break;
    }

    return button;
  }
}
```

### App Text Field

Buat file `lib/core/components/app_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      style: const TextStyle(fontSize: AppSizes.fontLg),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
    );
  }
}
```

### Loading Indicator

Buat file `lib/core/components/loading_indicator.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: color ?? AppColors.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: color ?? AppColors.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: LoadingIndicator(message: message),
          ),
      ],
    );
  }
}
```

### Empty State Widget

Buat file `lib/core/components/empty_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconXl,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSizes.lg),
              AppButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Error State Widget

Buat file `lib/core/components/error_state.dart`:

```dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: AppSizes.iconXl,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppSizes.fontMd,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              AppButton(
                text: 'Coba Lagi',
                onPressed: onRetry,
                isFullWidth: false,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Step 9: API Handler

Buat file `lib/core/utils/api_handler.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiHandler {
  static const String _tokenKey = 'auth_token';

  // ═══════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADERS
  // ═══════════════════════════════════════════════════════════════

  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await getToken();
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // HTTP METHODS
  // ═══════════════════════════════════════════════════════════════

  /// GET Request
  static Future<Either<String, Map<String, dynamic>>> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      return const Left('Tidak ada koneksi internet');
    } on HttpException {
      return const Left('Terjadi kesalahan pada server');
    } catch (e) {
      return Left('Error: $e');
    }
  }

  /// POST Request
  static Future<Either<String, Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      return const Left('Tidak ada koneksi internet');
    } on HttpException {
      return const Left('Terjadi kesalahan pada server');
    } catch (e) {
      return Left('Error: $e');
    }
  }

  /// POST Multipart (untuk upload file)
  static Future<Either<String, Map<String, dynamic>>> postMultipart(
    String url, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'image',
  }) async {
    try {
      final headers = await _getHeaders(isMultipart: true);
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          fileField,
          file.path,
        ));
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      return const Left('Tidak ada koneksi internet');
    } on HttpException {
      return const Left('Terjadi kesalahan pada server');
    } catch (e) {
      return Left('Error: $e');
    }
  }

  /// PUT Request
  static Future<Either<String, Map<String, dynamic>>> put(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      return const Left('Tidak ada koneksi internet');
    } on HttpException {
      return const Left('Terjadi kesalahan pada server');
    } catch (e) {
      return Left('Error: $e');
    }
  }

  /// DELETE Request
  static Future<Either<String, Map<String, dynamic>>> delete(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } on SocketException {
      return const Left('Tidak ada koneksi internet');
    } on HttpException {
      return const Left('Terjadi kesalahan pada server');
    } catch (e) {
      return Left('Error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RESPONSE HANDLER
  // ═══════════════════════════════════════════════════════════════

  static Either<String, Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Right(data);
      } else if (response.statusCode == 401) {
        removeToken();
        return Left(data['message'] ?? 'Sesi telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 403) {
        return Left(data['message'] ?? 'Anda tidak memiliki akses');
      } else if (response.statusCode == 404) {
        return Left(data['message'] ?? 'Data tidak ditemukan');
      } else if (response.statusCode == 422) {
        // Validation error
        final errors = data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return Left(firstError.first.toString());
          }
        }
        return Left(data['message'] ?? 'Validasi gagal');
      } else {
        return Left(data['message'] ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      return Left('Error parsing response: $e');
    }
  }
}
```

---

# PART 3: DATA LAYER - MODELS

## Step 10: User Model

Buat file `lib/data/models/user_model.dart`:

```dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

## Step 11: Auth Response Model

Buat file `lib/data/models/auth_response_model.dart`:

```dart
import 'user_model.dart';

class AuthResponseModel {
  final bool status;
  final String message;
  final UserModel user;
  final String token;

  const AuthResponseModel({
    required this.status,
    required this.message,
    required this.user,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResponseModel(
      status: json['status'] as bool,
      message: json['message'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': {
        'user': user.toJson(),
        'token': token,
      },
    };
  }
}
```

## Step 12: Story Model

Buat file `lib/data/models/story_model.dart`:

```dart
import 'user_model.dart';

class StoryModel {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String? image;
  final String? imageUrl;
  final UserModel? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.image,
    this.imageUrl,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'image': image,
      'image_url': imageUrl,
      'user': user?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  StoryModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    String? image,
    String? imageUrl,
    UserModel? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format waktu untuk ditampilkan
  String get formattedDate {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 7) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}
```

## Step 13: Stories Response Model (Pagination)

Buat file `lib/data/models/stories_response_model.dart`:

```dart
import 'story_model.dart';

class StoriesResponseModel {
  final bool status;
  final String message;
  final List<StoryModel> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const StoriesResponseModel({
    required this.status,
    required this.message,
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory StoriesResponseModel.fromJson(Map<String, dynamic> json) {
    final paginatedData = json['data'] as Map<String, dynamic>;
    final items = paginatedData['data'] as List<dynamic>;

    return StoriesResponseModel(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: items.map((e) => StoryModel.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: paginatedData['current_page'] as int? ?? 1,
      lastPage: paginatedData['last_page'] as int? ?? 1,
      perPage: paginatedData['per_page'] as int? ?? 10,
      total: paginatedData['total'] as int? ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => data.isEmpty;
}
```

---

**Lanjut ke Part 2...**

Dokumen dilanjutkan di file `new-step-by-step-part2.md`
