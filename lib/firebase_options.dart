// Generated from android/app/google-services.json for project cnno-app-g19.
// Firebase client config is not secret: access is controlled by firestore.rules
// and storage.rules. Regenerate with `flutterfire configure` if the project changes.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web is used for demos on a laptop; Android is the target platform.
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('CNNO is configured for Android and web only.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcG9USxqmMxcSv6FR4_muIvhNA9Fw-zpI',
    appId: '1:269163833631:android:63a3f253c139df80cce82a',
    messagingSenderId: '269163833631',
    projectId: 'cnno-app-g19',
    storageBucket: 'cnno-app-g19.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARyFBCVZz0ybgOB7qi1dq8Z4zvBX-aoyA',
    appId: '1:269163833631:web:31d3554c227c9346cce82a',
    messagingSenderId: '269163833631',
    projectId: 'cnno-app-g19',
    authDomain: 'cnno-app-g19.firebaseapp.com',
    storageBucket: 'cnno-app-g19.firebasestorage.app',
  );
}
