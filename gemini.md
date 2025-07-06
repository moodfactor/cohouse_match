# Gemini Project: cohouse_match

This document provides a high-level overview of the `cohouse_match` project to assist the Gemini AI assistant.

## Project Overview

`cohouse_match` is a mobile application built with Flutter that connects users looking for co-housing or roommates. It appears to be a "swipe-to-match" style app, similar to Tinder, but focused on finding compatible living partners. Key features include user profiles, matching, and real-time chat.

## Gemini CLI Configuration

To ensure the Gemini CLI always uses MCP servers, you need to configure them in a `settings.json` file. This file can be located either in your project's `.gemini/settings.json` or in your user's home directory `~/.gemini/settings.json`.

Here's an example of how to configure an MCP server in `settings.json`:

```json
{
  "mcpServers": {
    "myServer": {
      "command": "path/to/your/mcp/server/executable",
      "args": ["--arg1", "value1"],
      "env": {
        "API_KEY": "$MY_API_TOKEN"
      },
      "cwd": "./server-directory",
      "timeout": 30000,
      "trust": false
    }
  }
}
```

Replace `"myServer"` with a descriptive name for your MCP server, and `"path/to/your/mcp/server/executable"` with the actual path to your MCP server's executable. You can also specify `args`, `env`, `cwd`, `timeout`, and `trust` as needed for your specific MCP server setup.

The Gemini CLI will automatically attempt to connect to and discover tools from all configured MCP servers when it starts.

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
- **Real-time Chat:** Once a match is made, users can communicate through a chat interface (`chat_screen.dart`), now including image sharing capabilities.
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