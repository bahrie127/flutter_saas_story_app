# Flutter Story App

Aplikasi Flutter untuk berbagi cerita dengan fitur autentikasi, upload gambar, dan lokasi menggunakan Clean Architecture + BLoC Pattern.

## Features

- **Authentication**: Login, Register, Logout
- **Story Management**: Create, Read, Update, Delete stories
- **Image Upload**: Ambil foto dari kamera atau galeri
- **Location**: Integrasi Google Maps untuk menampilkan lokasi story
- **Profile**: Halaman profil pengguna

## Tech Stack

- **Flutter** - UI Framework
- **BLoC** - State Management
- **Freezed** - Code Generation untuk immutable classes
- **Dio** - HTTP Client
- **Shared Preferences** - Local Storage
- **Google Maps Flutter** - Maps Integration
- **Image Picker** - Camera & Gallery Access
- **Cached Network Image** - Image Caching

## Project Structure

```
lib/
├── core/
│   ├── components/          # Reusable UI components
│   ├── constants/           # App colors, sizes, variables
│   ├── extensions/          # BuildContext extensions
│   └── utils/               # Helper utilities
├── data/
│   ├── datasources/         # Remote & Local datasources
│   └── models/              # Data models
├── presentation/
│   ├── auth/                # Login, Register pages & blocs
│   ├── profile/             # Profile page & bloc
│   ├── splash/              # Splash screen
│   └── story/               # Story pages & blocs
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Installation

1. Clone repository
```bash
git clone https://github.com/bahrie127/flutter_saas_story_app.git
cd flutter_saas_story_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Generate freezed files
```bash
dart run build_runner build --delete-conflicting-outputs
```

4. Run app
```bash
flutter run
```

## API

Aplikasi ini menggunakan Story API dari:
- Base URL: `https://story-api.dicoding.dev/v1`

## Screenshots

Coming soon...

## License

MIT License
