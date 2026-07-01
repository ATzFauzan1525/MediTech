import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFNEP0IaaZM1TpQzyIUE0ImK1_VWJ5kRE',
    appId: '1:64801931635:android:496795dde4ec55e24e8506',
    messagingSenderId: '64801931635',
    projectId: 'medisync-f44b1',
    storageBucket: 'medisync-f44b1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '64801931635',
    projectId: 'medisync-f44b1',
    storageBucket: 'medisync-f44b1.firebasestorage.app',
    iosBundleId: 'com.meditech.medisync',
  );
}
