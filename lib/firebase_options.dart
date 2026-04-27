import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'Platform not supported',
        );
    }
  }

  // 🔥 ANDROID CONFIG
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACHwRWdezxYtSV8XVu39riCEnrfOyMWZg',
    appId: '1:436543886888:android:cf5e0f01a8c27e14a2c71d',
    messagingSenderId: 'ANDROID_SENDER_ID',
    projectId: 'myapp-bec98',
    storageBucket: 'myapp-bec98.firebasestorage.app',
  );

  // 🌐 WEB CONFIG
  static const FirebaseOptions web = FirebaseOptions(
  apiKey: "AIzaSyADAkLEGsH8KD3T_5eqP6B0ILJZ35peU_o",
  authDomain: "myapp-bec98.firebaseapp.com",
  databaseURL: "https://myapp-bec98-default-rtdb.firebaseio.com",
  projectId: "myapp-bec98",
  storageBucket: "myapp-bec98.firebasestorage.app",
  messagingSenderId: "436543886888",
  appId: "1:436543886888:web:ab9eed25d8f36599a2c71d",
  measurementId: "G-2LNTWWJ9EW"
  );
}