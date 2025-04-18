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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAClNXhegiF0fQscFNmVTAFoy9I8GhhRXo',
    appId: '1:975458631666:web:d98c148b2ddf07b2eeb56b',
    messagingSenderId: '975458631666',
    projectId: 'prueba-b-36681',
    authDomain: 'prueba-b-36681.firebaseapp.com',
    databaseURL: 'https://prueba-b-36681-default-rtdb.firebaseio.com',
    storageBucket: 'prueba-b-36681.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'prueba-b-36681',
    databaseURL: 'https://prueba-b-36681-default-rtdb.firebaseio.com',
    storageBucket: 'prueba-b-36681.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'prueba-b-36681',
    databaseURL: 'https://prueba-b-36681-default-rtdb.firebaseio.com',
    storageBucket: 'prueba-b-36681.appspot.com',
    iosBundleId: 'com.example.miAppFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID',
    projectId: 'prueba-b-36681',
    databaseURL: 'https://prueba-b-36681-default-rtdb.firebaseio.com',
    storageBucket: 'prueba-b-36681.appspot.com',
    iosBundleId: 'com.example.miAppFlutter',
  );
} 