// firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBPIdfKok0XMSVF-wroXJVIHcygHAmuX_U',
      appId: '172572296736-vik7db92ssoneodk0fafecrb7j1tn24f.apps.googleusercontent.com',
      messagingSenderId: '172572296736',
      projectId: 'bika-1b471',
      storageBucket: 'bika-1b471.appspot.com', // Replace if different
      authDomain: 'bika-1b471.firebaseapp.com', // Optional: Replace if your project uses this
      measurementId: '', // Leave blank or add if using Google Analytics
    );
  }
}
