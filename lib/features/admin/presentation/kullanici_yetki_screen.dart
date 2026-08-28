import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/profile_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/role_badge.dart';

/// Admin Paneli / Kullanıcı Yetki: solda kullanıcılar, sağda roller —
/// bir kullanıcı seçilip bir role dokunularak rol ataması yapılır.
class KullaniciYetkiScreen extends ConsumerStatefulWidget {
  const KullaniciYetkiScreen({super.key});

  @override
  ConsumerState<KullaniciYetkiScreen> createState() => _KullaniciYetkiScreenState();
}

class _KullaniciYetkiScreenState extends ConsumerState<KullaniciYetkiScreen> {
  String? _seciliKullaniciId;
  bool _guncelleniyor = false;

  Future<void> _rolAta(ProfileModel kullanici, KullaniciRolu rol) async {
    if (rol == kullanici.rol) return;
    setState(() => _guncelleniyor = true);
    try {
      await ref.read(profileRepositoryProvider).setRol(kullanici.id, rol.dbValue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${kullanici.adSoyad} → ${rol.etiket} olarak atandı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol güncellenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _guncelleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profillerAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yetki')),
      body: profillerAsync.when(
        data: (profiller) {
          final eslesenler = profiller.where((p) => p.id == _seciliKullaniciId);
          final secili = eslesenler.isEmpty ? null : eslesenler.first;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  secili == null
                      ? 'Bir kullanıcı seçin, ardından atamak istediğiniz role dokunun.'
                      : '${secili.adSoyad} seçili — atamak istediğiniz role dokunun.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Panel(
                        baslik: 'Kullanıcılar',
                        child: profiller.isEmpty
                            ? const Center(child: Text('Kayıt bulunamadı.'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(10),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: profiller.length,
                                itemBuilder: (context, index) {
                                  final p = profiller[index];
                                  return _KullaniciKarti(
                                    profil: p,
                                    secili: p.id == _seciliKullaniciId,
                                    onTap: () => setState(() => _seciliKullaniciId = p.id),
                                  );
                                },
                              ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _Panel(
                        baslik: 'Yetkiler',
                        child: GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: KullaniciRolu.values.length,
                          itemBuilder: (context, index) {
                            final rol = KullaniciRolu.values[index];
                            return _RolKarti(
                              rol: rol,
                              secili: secili?.rol == rol,
                              devreDisi: secili == null || _guncelleniyor,
                              onTap: () => _rolAta(secili!, rol),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.baslik, required this.child});

  final String baslik;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Text(baslik, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _KullaniciKarti extends StatelessWidget {
  const _KullaniciKarti({required this.profil, required this.secili, required this.onTap});

  final ProfileModel profil;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secili ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secili ? AppTheme.primary : Colors.grey.shade300,
              width: secili ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: RoleBadge.renk(profil.rol).withValues(alpha: 0.15),
                child: Text(
                  profil.adSoyad.isEmpty ? '?' : profil.adSoyad[0].toUpperCase(),
                  style: TextStyle(
                    color: RoleBadge.renk(profil.rol),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profil.adSoyad.isEmpty ? '(İsimsiz)' : profil.adSoyad,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              RoleBadge(rol: profil.rol),
              if (!profil.aktif) ...[
                const SizedBox(height: 4),
                Text(
                  'Onay bekliyor',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RolKarti extends StatelessWidget {
  const _RolKarti({
    required this.rol,
    required this.secili,
    required this.devreDisi,
    required this.onTap,
  });

  final KullaniciRolu rol;
  final bool secili;
  final bool devreDisi;
  final VoidCallback onTap;

  IconData get _ikon {
    switch (rol) {
      case KullaniciRolu.admin:
        return Icons.admin_panel_settings_outlined;
      case KullaniciRolu.isgUzmani:
        return Icons.health_and_safety_outlined;
      case KullaniciRolu.santiyeSefi:
        return Icons.engineering_outlined;
      case KullaniciRolu.personel:
        return Icons.person_outline;
      case KullaniciRolu.firmaYetkilisi:
        return Icons.business_outlined;
      case KullaniciRolu.firmaSorumlusu:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final renk = RoleBadge.renk(rol);
    return Material(
      color: secili ? renk.withValues(alpha: 0.12) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: devreDisi ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: secili ? renk : Colors.grey.shade300, width: secili ? 2 : 1),
          ),
          child: Opacity(
            opacity: devreDisi ? 0.5 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_ikon, color: renk, size: 26),
                const SizedBox(height: 8),
                Text(
                  rol.etiket,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: renk),
                ),
                if (secili) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.check_circle, color: renk, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
