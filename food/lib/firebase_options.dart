
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBCwYTai-Bhd4A5UUjmQNraxvr9QR2899I',
    appId: '1:708853820858:web:02c1e08d5afd10e986c183',
    messagingSenderId: '708853820858',
    projectId: 'mammamiaapp-cf3bc',
    authDomain: 'mammamiaapp-cf3bc.firebaseapp.com',
    storageBucket: 'mammamiaapp-cf3bc.firebasestorage.app',
    measurementId: 'G-EQZWTJLQ5H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBVanM44Js0ZTji4-B8hXnv7PyAmUYfi3Q',
    appId: '1:708853820858:android:800dd234cc17441286c183',
    messagingSenderId: '708853820858',
    projectId: 'mammamiaapp-cf3bc',
    storageBucket: 'mammamiaapp-cf3bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhx06N-Ksa8rljFT8V6luh-cpjNK9my9c',
    appId: '1:708853820858:ios:5d1d74e61f410a4786c183',
    messagingSenderId: '708853820858',
    projectId: 'mammamiaapp-cf3bc',
    storageBucket: 'mammamiaapp-cf3bc.firebasestorage.app',
    iosBundleId: 'com.example.food',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBhx06N-Ksa8rljFT8V6luh-cpjNK9my9c',
    appId: '1:708853820858:ios:5d1d74e61f410a4786c183',
    messagingSenderId: '708853820858',
    projectId: 'mammamiaapp-cf3bc',
    storageBucket: 'mammamiaapp-cf3bc.firebasestorage.app',
    iosBundleId: 'com.example.food',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBCwYTai-Bhd4A5UUjmQNraxvr9QR2899I',
    appId: '1:708853820858:web:418f738d6595789286c183',
    messagingSenderId: '708853820858',
    projectId: 'mammamiaapp-cf3bc',
    authDomain: 'mammamiaapp-cf3bc.firebaseapp.com',
    storageBucket: 'mammamiaapp-cf3bc.firebasestorage.app',
    measurementId: 'G-SKR18Q1D1E',
  );
}
