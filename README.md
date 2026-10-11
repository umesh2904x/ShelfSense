# ShelfSense

ShelfSense helps you keep track of expiry dates for groceries, medicine, soap,
skincare, and other everyday essentials. Add an item, see what needs attention,
and get timely reminders on Android and iOS.

## Features

- Email and password sign-in
- Organize items by category and quantity
- Sort items by expiry date and see their status at a glance
- Schedule local expiry reminders on Android and iOS
- Responsive Flutter interface for web and mobile

## Getting started

1. Install Flutter and Dart.
2. Get the project dependencies:

   ```sh
   flutter pub get
   ```

3. Configure Firebase for your own project:

   ```sh
   dart pub global activate flutterfire_cli
   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android,web
   ```

   Sign in to the Firebase account that owns the project when prompted. FlutterFire
   generates `lib/firebase_options.dart` and the Android Firebase configuration.
   These local configuration files are intentionally not included in this repository.
4. In Firebase Console, enable Email/Password Authentication, create a Firestore
   database, and publish the rules in `firestore.rules`.
5. Run the app:

   ```sh
   flutter run -d chrome
   ```

   For Android, start an emulator or connect a device and run `flutter run`.

## Notifications

Allow notifications in the Android or iOS app to receive reminders 7 days before,
3 days before, and on an item's expiry date. Scheduled local notifications are
not available in the web app.

## Security

Firebase configuration, Android signing credentials, local SDK paths, and build
outputs are excluded from Git. Never commit service-account keys, keystores, or
other private credentials.
