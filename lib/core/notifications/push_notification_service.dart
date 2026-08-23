import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/supabase_providers.dart';
import '../router/app_router.dart';

const _kanalId = 'tutanak_bildirimleri';
const _kanalAdi = 'Tutanak Bildirimleri';

/// Uygulama arka plandayken/kapalıyken gelen FCM mesajlarını işler.
/// Üst düzey (top-level) fonksiyon olmalıdır — Flutter'ın ayrı bir
/// izolatta çalıştırdığı arka plan callback'idir; bildirimin sistem
/// tepsisinde gösterilmesi FCM tarafından otomatik yapılır, burada ek
/// bir işlem gerekmez.
@pragma('vm:entry-point')
Future<void> firebaseMessagingArkaPlanIsleyici(RemoteMessage message) async {}

/// Faz 5 — Firebase Cloud Messaging kurulumu, izin isteği, token kaydı ve
/// bildirime dokunulduğunda ilgili tutanağa yönlendirme.
class PushNotificationService {
  PushNotificationService._();

  static final _yerelBildirimler = FlutterLocalNotificationsPlugin();

  /// `Firebase.initializeApp()`'ten sonra, `main()` içinde bir kez çağrılır.
  static Future<void> baslat() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingArkaPlanIsleyici);

    await _yerelBildirimler.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) => _tutanagaGit(response.payload),
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _yerelBildirimler
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(_kanalId, _kanalAdi, importance: Importance.high),
          );
    }

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMesaj);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _tutanagaGit(message.data['tutanak_id'] as String?),
    );

    final baslangicMesaji = await FirebaseMessaging.instance.getInitialMessage();
    if (baslangicMesaji != null) {
      _tutanagaGit(baslangicMesaji.data['tutanak_id'] as String?);
    }
  }

  static void _onForegroundMesaj(RemoteMessage message) {
    final bildirim = message.notification;
    if (bildirim == null) return;

    _yerelBildirimler.show(
      id: bildirim.hashCode,
      title: bildirim.title,
      body: bildirim.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_kanalId, _kanalAdi, importance: Importance.high),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['tutanak_id'] as String?,
    );
  }

  static void _tutanagaGit(String? tutanakId) {
    if (tutanakId == null || tutanakId.isEmpty) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    GoRouter.of(context).push('/tutanak/$tutanakId');
  }

  /// Oturum açıldığında FCM token'ını alıp `push_tokens` tablosuna
  /// kaydeder ve token yenilendiğinde de aynı işlemi tekrarlar.
  static Future<void> tokenKaydet(WidgetRef ref) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _tokenGonder(ref, token);
      FirebaseMessaging.instance.onTokenRefresh.listen((t) => _tokenGonder(ref, t));
    } catch (_) {
      // İzin verilmemiş veya desteklenmeyen bir ortamda token alınamayabilir;
      // push kaydı olmadan uygulama normal şekilde çalışmaya devam eder.
    }
  }

  static Future<void> _tokenGonder(WidgetRef ref, String token) {
    final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
    return ref.read(pushTokenRepositoryProvider).tokenTalepEt(token, platform);
  }

  /// Çıkış yapılmadan önce bu cihazın token'ını kullanıcının hesabından
  /// kaldırır (paylaşılan cihazlarda önceki kullanıcının bildirim almaya
  /// devam etmemesi için).
  static Future<void> tokenSil(WidgetRef ref) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await ref.read(pushTokenRepositoryProvider).tokenSil(token);
    } catch (_) {
      // Çıkış akışını token silme hatası yüzünden engelleme.
    }
  }
}
