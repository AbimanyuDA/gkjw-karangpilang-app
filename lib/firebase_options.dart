// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCl7aABzvHrrApncIqx63Z3v49Lw0nsYCc',
    appId: '1:133821426056:android:0b8cca101128725b13b23d',
    messagingSenderId: '133821426056',
    projectId: 'gkjw-karangpilang-app',
    storageBucket: 'gkjw-karangpilang-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0t9onqMWfwpJNQepTAYzPDxF1Mcdu78k',
    appId: '1:133821426056:ios:2b42e128d1d4109913b23d',
    messagingSenderId: '133821426056',
    projectId: 'gkjw-karangpilang-app',
    storageBucket: 'gkjw-karangpilang-app.firebasestorage.app',
    iosBundleId: 'com.gkjw.gkjwKarangpilang',
  );
}
