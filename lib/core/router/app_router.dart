import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/kullanici_yetki_screen.dart';
import '../../features/admin/presentation/personel_yonetimi_screen.dart';
import '../../features/admin/presentation/proje_firma_yonetimi_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/bildirim/presentation/bildirim_liste_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/indirilenler/presentation/indirilen_dosyalar_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/raporlar/presentation/raporlar_screen.dart';
import '../../features/tutanak/presentation/taslak_kuyruk_screen.dart';
import '../../features/tutanak/presentation/tutanak_detay_screen.dart';
import '../../features/tutanak/presentation/tutanak_form_screen.dart';
import '../../features/tutanak/presentation/tutanak_liste_screen.dart';
import '../constants/app_enums.dart';
import '../../providers/profile_providers.dart';
import '../../providers/supabase_providers.dart';

/// go_router'ın auth/profil durumu değiştiğinde redirect mantığını yeniden
/// çalıştırması için Riverpod stream'lerini bir Listenable'a köprüler.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (previous, next) => notifyListeners());
    ref.listen(currentProfileProvider, (previous, next) => notifyListeners());
  }
}

/// Push bildirim dokunuşlarında (uygulama widget ağacı dışından) sayfa
/// geçişi yapabilmek için global bir navigator anahtarı — bkz.
/// core/notifications/push_notification_service.dart.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final userId = ref.read(currentUserIdProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (userId == null) {
        return loggingIn ? null : '/login';
      }

      final profile = ref.read(currentProfileProvider).valueOrNull;
      // Profil satırı henüz (realtime ile) gelmediyse yönlendirme yapma;
      // profil geldiğinde redirect otomatik tekrar tetiklenir (refreshListenable).
      if (profile == null) return null;

      if (!profile.aktif) {
        return state.matchedLocation == '/pending-approval' ? null : '/pending-approval';
      }

      if (loggingIn || state.matchedLocation == '/pending-approval') {
        return '/home';
      }

      final adminOnly = state.matchedLocation.startsWith('/admin');
      if (adminOnly && profile.rol != KullaniciRolu.admin) {
        return '/home';
      }

      const raporlarKisitli = {
        KullaniciRolu.personel,
        KullaniciRolu.firmaYetkilisi,
        KullaniciRolu.firmaSorumlusu,
      };
      if (state.matchedLocation == '/raporlar' && raporlarKisitli.contains(profile.rol)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/bildirimler',
        builder: (context, state) => const BildirimListeScreen(),
      ),
      GoRoute(
        path: '/raporlar',
        builder: (context, state) => const RaporlarScreen(),
      ),
      GoRoute(
        path: '/indirilenler',
        builder: (context, state) => const IndirilenDosyalarScreen(),
      ),
      GoRoute(path: '/tutanak', builder: (context, state) => const TutanakListeScreen()),
      GoRoute(path: '/tutanak/yeni', builder: (context, state) => const TutanakFormScreen()),
      GoRoute(
        path: '/tutanak/duzenle/:id',
        builder: (context, state) =>
            TutanakFormScreen(tutanakId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/tutanak/kuyruk',
        builder: (context, state) => const TaslakKuyrukScreen(),
      ),
      GoRoute(
        path: '/tutanak/:id',
        builder: (context, state) =>
            TutanakDetayScreen(tutanakId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/personel',
        builder: (context, state) => const PersonelYonetimiScreen(),
      ),
      GoRoute(
        path: '/admin/kullanici-yetki',
        builder: (context, state) => const KullaniciYetkiScreen(),
      ),
      GoRoute(
        path: '/admin/proje-firma',
        builder: (context, state) => const ProjeFirmaYonetimiScreen(),
      ),
    ],
  );
});
