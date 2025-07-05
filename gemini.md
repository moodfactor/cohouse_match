# Gemini Project: cohouse_match

This document provides a high-level overview of the `cohouse_match` project to assist the Gemini AI assistant.

## Project Overview

`cohouse_match` is a mobile application built with Flutter that connects users looking for co-housing or roommates. It appears to be a "swipe-to-match" style app, similar to Tinder, but focused on finding compatible living partners. Key features include user profiles, matching, and real-time chat.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase Cloud Functions (TypeScript)
- **Database:** Firebase Firestore & Firebase Realtime Database
- **Authentication:** Firebase Authentication
- **Storage:** Firebase Storage
- **AI Features:** Google Gemini API
- **Push Notifications:** Firebase Cloud Messaging
- **Location Services:** Google Maps Platform

## Key Directories

- `lib/`: Contains the core Flutter application code.
  - `lib/models/`: Defines the data models for the application (e.g., `User`, `Match`, `Message`).
  - `lib/screens/`: Contains the UI screens for the application (e.g., `login_screen.dart`, `swipe_screen.dart`, `chat_screen.dart`).
  - `lib/services/`: Houses the business logic and services that interact with backend APIs (e.g., `auth_service.dart`, `database_service.dart`).
  - `lib/widgets/`: Contains reusable UI widgets.
- `functions/`: Contains the Firebase Cloud Functions written in TypeScript.
  - `functions/src/index.ts`: The main entry point for the backend logic.
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Platform-specific code for building the Flutter application.

## Core Features

- **User Authentication:** Users can register and log in using Firebase Authentication, including Google Sign-In.
- **User Profiles:** Users can create and view profiles, likely with details relevant to co-living.
- **Swiping & Matching:** A swipe-based interface (`swipe_screen.dart`) for users to like or dislike potential roommates.
- **Real-time Chat:** Once a match is made, users can communicate through a chat interface (`chat_screen.dart`).
- **Location-based Filtering:** Users can likely filter potential matches based on location (`filter_screen.dart`, `location_picker_screen.dart`).
- **AI-powered Features:** The `gemini_service.dart` suggests the use of the Gemini API, possibly for profile summaries, compatibility scoring, or other smart features.

## Dependencies

### Flutter (`pubspec.yaml`)
- **Firebase:**
    - `firebase_core`
    - `firebase_auth`
    - `cloud_firestore`
    - `firebase_storage`
    - `firebase_messaging`
    - `firebase_database`
- **Google:**
    - `google_sign_in`
    - `google_generative_ai`
    - `google_maps_flutter`
- **State Management:**
    - `provider`
- **UI:**
    - `cupertino_icons`
    - `flutter_card_swiper`
- **Utilities:**
    - `rxdart`
    - `image_picker`
    - `logging`
    - `geolocator`
    - `geocoding`
- **Local Notifications:**
    - `flutter_local_notifications`

### Firebase Functions (`functions/package.json`)
- `firebase-admin`
- `firebase-functions`

## Build Commands

### Flutter
- `flutter pub get`: Install dependencies.
- `flutter run`: Run the app in debug mode.
- `flutter build <platform>`: Build a release version for the specified platform (e.g., `apk`, `appbundle`, `ios`).

### Firebase Functions
- `npm install` (in `functions` directory): Install dependencies.
- `npm run build` (in `functions` directory): Compile TypeScript to JavaScript.
- `firebase deploy --only functions`: Deploy functions to Firebase.
- `firebase emulators:start --only functions`: Run functions locally in the emulator.