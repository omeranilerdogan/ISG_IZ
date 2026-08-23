// Firebase Console'da oluşturulan Android/iOS/Web uygulama kayıtlarından elde
// edilen yapılandırma değerleridir (bkz. README Bölüm "Firebase Kurulumu").
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platform için tanımlı değil: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyACSslAgoOfonBAn22oa4HP_i25VVazQJE',
    appId: '1:776025820167:web:4311c83b1a34770251eea2',
    messagingSenderId: '776025820167',
    projectId: 'isg-uygunsuzluk-tespit',
    authDomain: 'isg-uygunsuzluk-tespit.firebaseapp.com',
    storageBucket: 'isg-uygunsuzluk-tespit.firebasestorage.app',
    measurementId: 'G-24NWTVGBHG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfQTaDhBzTcIwg3YP1G6fuZ-XzRIbx5-0',
    appId: '1:776025820167:android:d3ed7d164eac22ea51eea2',
    messagingSenderId: '776025820167',
    projectId: 'isg-uygunsuzluk-tespit',
    storageBucket: 'isg-uygunsuzluk-tespit.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAvIb4FPCkzNBkF4jBDvizk_9clIFr3eOk',
    appId: '1:776025820167:ios:273c7e3f1331f54851eea2',
    messagingSenderId: '776025820167',
    projectId: 'isg-uygunsuzluk-tespit',
    storageBucket: 'isg-uygunsuzluk-tespit.firebasestorage.app',
    iosBundleId: 'com.isgtutanak.isgUygunsuzlukTespit',
  );
}
