// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyBjx-4rPklg6MgDjKEfyRXmWMjzUhRanHc',
    appId: '1:527415309529:web:7ecf2a44100fefdd34bac8',
    messagingSenderId: '527415309529',
    projectId: 'byuirideshare',
    authDomain: 'byuirideshare.firebaseapp.com',
    storageBucket: 'byuirideshare.firebasestorage.app',
    measurementId: 'G-HNGZLVJRVS',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-tJ6PwtYBQbEKhVxIDQ8g2cIWvxAx5L4',
    appId: '1:527415309529:android:96908e26b8b7111034bac8',
    messagingSenderId: '527415309529',
    projectId: 'byuirideshare',
    storageBucket: 'byuirideshare.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0bbVfb0mKRTcIf1oSotu0T-UWXo9zWHw',
    appId: '1:527415309529:ios:e564e648b5912cc034bac8',
    messagingSenderId: '527415309529',
    projectId: 'byuirideshare',
    storageBucket: 'byuirideshare.firebasestorage.app',
    iosBundleId: 'com.example.byuiRideshare',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA0bbVfb0mKRTcIf1oSotu0T-UWXo9zWHw',
    appId: '1:527415309529:ios:e564e648b5912cc034bac8',
    messagingSenderId: '527415309529',
    projectId: 'byuirideshare',
    storageBucket: 'byuirideshare.firebasestorage.app',
    iosBundleId: 'com.example.byuiRideshare',
  );
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBjx-4rPklg6MgDjKEfyRXmWMjzUhRanHc',
    appId: '1:527415309529:web:d711e896396a183f34bac8',
    messagingSenderId: '527415309529',
    projectId: 'byuirideshare',
    authDomain: 'byuirideshare.firebaseapp.com',
    storageBucket: 'byuirideshare.firebasestorage.app',
    measurementId: 'G-PTW5KD97RM',
  );
}


