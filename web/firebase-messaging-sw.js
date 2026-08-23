// Web'de sekme arka plandayken/kapalıyken FCM push bildirimlerini
// gösterebilmek için gereken service worker (bkz. lib/firebase_options.dart
// içindeki web yapılandırmasıyla aynı proje).
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyACSslAgoOfonBAn22oa4HP_i25VVazQJE',
  authDomain: 'isg-uygunsuzluk-tespit.firebaseapp.com',
  projectId: 'isg-uygunsuzluk-tespit',
  storageBucket: 'isg-uygunsuzluk-tespit.firebasestorage.app',
  messagingSenderId: '776025820167',
  appId: '1:776025820167:web:4311c83b1a34770251eea2',
});

firebase.messaging();
