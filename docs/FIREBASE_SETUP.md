# Firebase setup

Do this once per Firebase project. Commands run from the repository folder.

## 1. Tools

```
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

## 2. Project and app config

```
firebase projects:create cnno-app-<suffix> --display-name "CNNO App"
flutterfire configure --project=cnno-app-<suffix> --platforms=android --android-package-name=com.cinnamoncodes.cnno_app
```

This writes `lib/firebase_options.dart` and `android/app/google-services.json`. These hold the Firebase client config, which is not secret: access is controlled by `firestore.rules` and `storage.rules`.

## 3. Turn on the services (Firebase console)

1. **Authentication > Sign-in method**: enable **Email/Password**.
2. **Firestore Database > Create database**: production mode, location **asia-southeast1 (Singapore)**.
3. **Storage > Get started** (needed for admin product photos).

Then deploy the rules:

```
firebase use cnno-app-<suffix>
firebase deploy --only firestore:rules,storage
```

## 4. Make an admin

Register in the app, then in **Firestore > users > (uid)** set `role` to `admin`. Log in again and use **Settings > Load CNNO menu**.

## 5. AI and email receipts (Cloud Functions)

Cloud Functions need the **Blaze (pay as you go)** plan. Usage at CNNO's size should stay within the free quota, but a billing account is required. Set a budget alert in Google Cloud.

1. Get a Gemini API key from https://aistudio.google.com/apikey
2. Store it as a secret (never in code):
   ```
   firebase functions:secrets:set GEMINI_API_KEY
   ```
3. Deploy:
   ```
   cd functions && npm install && cd ..
   firebase deploy --only functions
   ```
4. Email receipts (FR-10): install the **Trigger Email from Firestore** extension (`firebase ext:install firebase/firestore-send-email`), collection `mail`, with an SMTP account for CNNO's email. The `sendReceipt` function writes each receipt into `mail`.

Without step 5 the app still works: the recommendation uses a simple rule and the assistant tells customers to contact CNNO.
