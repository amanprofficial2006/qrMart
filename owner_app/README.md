# qrMart Owner Flutter App

This folder contains a Flutter scaffold for the owner side of qrMart. It is wired to the existing backend owner APIs used by the current React owner panel.

## What is included

- Login and direct shop registration using `/api/v1/auth/login` and `/api/v1/auth/register`
- Owner dashboard tabs for orders, products, shop profile, and QR code
- Product create, update, and delete
- Shop profile update plus logo and payment QR uploads
- Order status updates and custom customer notifications
- QR fetch and refresh
- Shared token storage with `shared_preferences`
- Foreground order alert sound plus Firebase Messaging hooks for background notifications

## What is not wired yet

- Google sign-in for owners
- Socket.IO real-time order streaming
- Final native Firebase project files such as `google-services.json` and `GoogleService-Info.plist`

## Next steps on a machine with Flutter installed

```bash
cd owner_app
flutter create .
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Release/APK builds use the production backend by default:

```txt
https://qrmart.onrender.com
```

## Firebase push notification setup

The app already contains Firebase Messaging code, but the native Firebase app config still has to be supplied for each build.

### Android

1. In Firebase Console, add an Android app for this package name or update the package name in `owner_app/android/app/build.gradle.kts` first:
   `com.example.qrmart_owner`
2. Download `google-services.json`.
3. Place it at `owner_app/android/app/google-services.json`.
4. Run the app again. The Gradle Google Services plugin is now auto-applied when that file exists.

### iOS or manual dart-define fallback

If you are not using native Firebase config files, pass the Firebase values manually:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=FIREBASE_API_KEY=your_api_key --dart-define=FIREBASE_PROJECT_ID=your_project_id --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id --dart-define=FIREBASE_STORAGE_BUCKET=your_storage_bucket --dart-define=FIREBASE_APP_ID=your_android_or_ios_app_id
```

Without a valid platform `FIREBASE_APP_ID`, the owner app will show the in-app warning that Firebase notifications are not configured for this build yet.

## API base URL notes

- Android emulator: `http://10.0.2.2:5000`
- iOS simulator: `http://localhost:5000`
- Physical device: use your computer's LAN IP, for example `http://192.168.1.10:5000`
- Production APK default: `https://qrmart.onrender.com`

## Suggested follow-up work

1. Add Google sign-in for parity with the current web onboarding flow.
2. Finalize iOS Firebase setup and Apple push notification capabilities.
3. Replace polling with Socket.IO live updates for `order:new` and `order:updated`.
