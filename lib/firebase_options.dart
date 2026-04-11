import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase has not been configured for Web yet. Run flutterfire configure to add web options.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase has not been configured for this platform yet. Run flutterfire configure and add the matching platform configuration file.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDQm3MtIOy4lCliJIcqFDjxkwAz3yYvaIg',
    appId: '1:315216426936:android:781d39bd7a0690ca2a814d',
    messagingSenderId: '315216426936',
    projectId: 'msq-wallet-b0374',
    storageBucket: 'msq-wallet-b0374.firebasestorage.app',
  );
}
