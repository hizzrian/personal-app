# Personal App

A personal Flutter app with three main features:

## Features

### 1. Notes
- Create, edit, delete notes
- Search by title, body, or tags
- Pin important notes
- Tag system for organization
- Word & character count
- Swipe to delete

### 2. Job Tracker
- Track job applications
- 8 status stages: Applied → Screening → Interview → Technical → Offer → Accepted/Rejected/Withdrawn
- Filter by status
- Stats overview (total, active, offers)
- Company, position, location, salary, date, notes
- Color-coded status badges

### 3. QR Code
- **Generate**: Create QR codes from text, URL, email, phone, or WiFi
- **Scan from Image**: Pick image from gallery and detect QR code
- **Live Camera Scan**: Real-time QR code scanning
- Copy result to clipboard or share

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK (Android)
flutter build apk --release

# Build IPA (iOS)
flutter build ios --release
```

## Requirements
- Flutter SDK >= 3.0.0
- Android: min SDK 21
- iOS: min 12.0

## Permissions
- **Camera**: Required for live QR code scanning
- **Photo Library**: Required for scanning QR from images
- **Storage**: Required for image access on Android

## Tech Stack
- Flutter (Dart)
- SQLite (sqflite) for local storage
- qr_flutter for QR generation
- mobile_scanner for camera QR scanning
- image_picker for gallery access
- share_plus for sharing content
