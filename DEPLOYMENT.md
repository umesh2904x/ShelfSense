# ShelfSense deployment

## Configure Firebase

From the project root, generate platform options for your Firebase project:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android,web
```

Enable Email/Password Authentication, create a Firestore database, publish
`firestore.rules`, and add your deployment host to Firebase Authentication's
authorized domains. FlutterFire-generated options and Android configuration are
local files and must not be committed.

## Deploy to Firebase Hosting

Install the Firebase CLI and authenticate with the account that has access to
your Firebase project:

```sh
npm install -g firebase-tools
firebase login
flutter build web --release
firebase deploy --only hosting
```

## Build Android

For local testing:

```sh
flutter build apk --debug
```

For Play Store release builds, create a signing keystore and configure its
credentials locally in `android/keystore.properties`. Keep the keystore and
passwords private; never commit them.

```sh
flutter build appbundle --release
```

## Continuous integration

GitHub Actions runs analysis, tests, and a web build on pushes and pull requests.
It does not deploy the app or require Firebase service-account credentials.
