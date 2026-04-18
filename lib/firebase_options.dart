import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web in this project.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for macOS in this project.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Windows in this project.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux in this project.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDteaGXRweF3uXJtKcocEs94CRzNYlNtIk',
    appId: '1:203573212812:android:3cd890a3cec69c9b13eda9',
    messagingSenderId: '203573212812',
    projectId: 'mymedicine-845a3',
    storageBucket: 'mymedicine-845a3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnwO9zKLSaiD-6hx-3zv74NDxmNUSvR8c',
    appId: '1:203573212812:ios:082629df5109f77113eda9',
    messagingSenderId: '203573212812',
    projectId: 'mymedicine-845a3',
    storageBucket: 'mymedicine-845a3.firebasestorage.app',
    iosClientId: '203573212812-2pju0m9fgob0683ar560j9a879fvp6r2.apps.googleusercontent.com',
    iosBundleId: 'com.iiacss.mymedicineapp',
  );
}
