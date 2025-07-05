### Project File Structure

```
/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── match.dart
│   │   └── message.dart
│   ├── screens/
│   │   ├── wrapper.dart
│   │   ├── home_screen.dart
│   │   ├── swipe_screen.dart
│   │   ├── matches_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── view_profile_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── authenticate.dart
│   │   ├── home_wrapper.dart
│   │   ├── location_picker_screen.dart
│   │   ├── map_view_screen.dart
│   │   ├── filter_screen.dart
│   │   └── onboarding/
│   │       ├── onboarding_screen.dart
│   │       └── pages/
│   │           ├── welcome_page.dart
│   │           ├── photo_page.dart
│   │           ├── tags_page.dart
│   │           └── details_page.dart
│   └── services/
│       ├── auth_service.dart
│       ├── database_service.dart
│       ├── location_service.dart
│       ├── gemini_service.dart
│       ├── notification_service.dart
│       └── presence_service.dart
└── ...
```

### Key Dependencies

#### **Flutter App (`pubspec.yaml`)**

*   **Firebase:**
    *   `firebase_core`: Core Firebase functionality.
    *   `firebase_auth`: Authentication.
    *   `cloud_firestore`: Firestore Database.
    *   `firebase_storage`: Cloud Storage.
    *   `firebase_messaging`: Push Notifications.
    *   `firebase_database`: Realtime Database (for presence).
*   **Google Services:**
    *   `google_sign_in`: Google Sign-In integration.
    *   `google_maps_flutter`: Google Maps integration.
*   **AI & State Management:**
    *   `google_generative_ai`: Gemini API for AI features.
    *   `provider`: State management.
*   **UI & Utilities:**
    *   `flutter_card_swiper`: Tinder-like card swiping.
    *   `image_picker`: For selecting images from the gallery or camera.
    *   `geolocator`: For getting the device's location.
    *   `geocoding`: For converting coordinates to addresses.
    *   `rxdart`: Reactive programming utilities.

#### **Firebase Functions (`functions/package.json`)**

*   `firebase-admin`: To interact with Firebase services from the backend.
*   `firebase-functions`: To define and deploy Cloud Functions.
*   `typescript`: The language used for the backend logic.
*   `eslint`: For code linting and quality checks.
