import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/offline/taslak_senkronizasyon_servisi.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/repositories/auth_repository.dart';
import 'firebase_options.dart';
import 'providers/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (Env.isConfigured) {
    await SupabaseConfig.initialize();
    await _sifreSifirlamaBaglantisiniDogrula();
  }

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushNotificationService.baslat();
  } catch (_) {
    // Firebase yapılandırılmamış/desteklenmeyen bir platformda başlatma
    // başarısız olsa bile uygulama push bildirim olmadan çalışmaya devam eder.
  }

  runApp(const ProviderScope(child: IsgUygunsuzlukApp()));
}

/// Web'de şifre sıfırlama bağlantısıyla açıldıysa bağlantıdaki `token_hash`
/// değerini oturuma çevirir. Doğrulama başarısız olursa oturum açılmaz ve
/// yeni şifre ekranı "Bağlantı Doğrulanamadı" mesajını gösterir.
Future<void> _sifreSifirlamaBaglantisiniDogrula() async {
  if (!kIsWeb) return;
  final params = Uri.base.queryParameters;
  final tokenHash = params[AppUrls.tokenHashParametresi];
  if (tokenHash == null || params['type'] != 'recovery') return;
  try {
    await AuthRepository(SupabaseConfig.client).verifyRecoveryToken(tokenHash);
  } catch (_) {}
}

class IsgUygunsuzlukApp extends ConsumerWidget {
  const IsgUygunsuzlukApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) {
      return MaterialApp(
        title: 'PSFK- UTP',
        theme: AppTheme.light,
        home: const _SupabaseYapilandirmaEksikScreen(),
      );
    }

    ref.watch(taslakSenkronizasyonServisiProvider);

    ref.listen<String?>(currentUserIdProvider, (previous, next) {
      if (previous == null && next != null) {
        PushNotificationService.tokenKaydet(ref);
        ref.read(taslakSenkronizasyonServisiProvider).senkronizeEt();
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PSFK- UTP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _SupabaseYapilandirmaEksikScreen extends StatelessWidget {
  const _SupabaseYapilandirmaEksikScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_suggest_outlined, size: 56, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Supabase Yapılandırması Eksik',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Proje kökündeki ".env.example" dosyasını ".env" olarak kopyalayıp '
                'SUPABASE_URL ve SUPABASE_ANON_KEY değerlerini kendi Supabase '
                'projenizin bilgileriyle doldurun, ardından uygulamayı yeniden başlatın.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
