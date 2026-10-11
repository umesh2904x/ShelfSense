# Firebase Setup Instructions for ShelfSense

Follow these steps to configure Firebase for the ShelfSense app.

## 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `app-shelfsense` (or your preferred name)
4. Enable/disable Google Analytics as desired
5. Click **"Create project"**

## 2. Enable Email/Password Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click **"Email/Password"**
3. Enable **"Email/Password"** toggle
4. Optionally enable **"Email link (passwordless sign-in)"**
5. Click **"Save"**

## 3. Create Firestore Database

1. Go to **Firestore Database** → **Create database**
2. Choose **"Start in test mode"** (we'll secure it next)
3. Select a location close to your users (e.g., `us-central1` or `asia-south1`)
4. Click **"Enable"**

## 4. Set Firestore Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Replace the default rules with the rules from `firestore.rules` (see below)
3. Click **"Publish"**

## 5. Generate platform configuration

Run FlutterFire CLI from the project root:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=app-shelfsense --platforms=android,web
```

Sign in with the Google account that owns the Firebase project. The CLI registers
missing platform apps and generates `lib/firebase_options.dart` and Android's
`google-services.json`. These local configuration files are git-ignored; do not
commit Firebase credentials or Android signing keys.

## 6. Configure authorized domains

In Firebase Console → **Authentication** → **Settings** → **Authorized domains**, add:
- `app-shelfsense.web.app`
- `app-shelfsense.firebaseapp.com`
- `localhost` (for development)

## 7. Install Dependencies & Run

```bash
flutter pub get
flutter run
```

## 8. Test the App

1. Open the app on your device/emulator
2. Sign up with a new account
3. Add a product with an expiry date
4. Verify it appears in the list
5. In the app, choose **Enable** in the expiry reminders card and allow notifications when prompted
6. Add a product and check its reminders on an Android or iOS device

ShelfSense schedules reminders 7 days before, 3 days before, and on the expiry date at 9 AM.
Scheduled local reminders are available in the Android and iOS apps; the web app can track
expiry dates but does not schedule notifications.

---

## Firestore Security Rules (firestore.rules)

Copy these rules to Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Users can only access their own products subcollection
      match /products/{productId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

These rules ensure:
- Users can only read/write their own user document
- Users can only read/write their own products
- Unauthenticated users have no access

---

## Troubleshooting

### "Default FirebaseApp is not initialized"
- Ensure `google-services.json` is in `android/app/`
- Check that `apply plugin: 'com.google.gms.google-services'` is in `android/app/build.gradle.kts`
- Run `flutter clean && flutter pub get`

### Notifications not showing
- Grant notification permission when prompted (Android 13+)
- Check Settings → Apps → ShelfSense → Notifications
- Ensure exact alarm permission is granted

### Firestore permission denied
- Verify security rules are published
- Check that user is authenticated (check Auth tab in Firebase Console)
- Ensure `request.auth.uid` matches the user document ID

### Build errors
- Run `flutter clean`
- Delete `android/.gradle` and `android/app/build`
- Run `flutter pub get` and `flutter run` again

### "Unsupported Gradle project" error
- Run `flutter create --platforms=android .` to regenerate Android project
- Ensure `dev.flutter.flutter-gradle-plugin` is applied in `android/app/build.gradle.kts`
- Ensure `google-services` plugin is in root `android/build.gradle.kts`