import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/proje_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/acik_kapali_anahtar.dart';
import '../../../shared/widgets/role_badge.dart';

/// Bölüm 5.7 — Admin Paneli / Personel Yönetimi:
/// kullanıcı listesi, kayıt onaylama, rol atama/değiştirme, proje ataması,
/// hesap aktif/pasif etme.
class PersonelYonetimiScreen extends ConsumerStatefulWidget {
  const PersonelYonetimiScreen({super.key});

  @override
  ConsumerState<PersonelYonetimiScreen> createState() =>
      _PersonelYonetimiScreenState();
}

class _PersonelYonetimiScreenState
    extends ConsumerState<PersonelYonetimiScreen> {
  bool _sadeceBekleyenler = false;

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personel Yönetimi')),
      body: profilesAsync.when(
        data: (profiles) {
          final gosterilecek = _sadeceBekleyenler
              ? profiles.where((p) => !p.aktif).toList()
              : profiles;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Yalnızca onay bekleyenler'),
                    selected: _sadeceBekleyenler,
                    onSelected: (v) => setState(() => _sadeceBekleyenler = v),
                  ),
                ),
              ),
              Expanded(
                child: gosterilecek.isEmpty
                    ? const Center(child: Text('Kayıt bulunamadı.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: gosterilecek.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _PersonelCard(profile: gosterilecek[index]),
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

class _PersonelCard extends ConsumerStatefulWidget {
  const _PersonelCard({required this.profile});

  final ProfileModel profile;

  @override
  ConsumerState<_PersonelCard> createState() => _PersonelCardState();
}

class _PersonelCardState extends ConsumerState<_PersonelCard> {
  bool _aktifGuncelleniyor = false;

  ProfileModel get profile => widget.profile;

  void _hataGoster(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Güncellenemedi: $e')));
  }

  Future<void> _aktifDegistir(bool v) async {
    setState(() => _aktifGuncelleniyor = true);
    try {
      await ref.read(profileRepositoryProvider).setAktif(profile.id, v);
    } catch (e) {
      _hataGoster(e);
    } finally {
      if (mounted) setState(() => _aktifGuncelleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firmalarAsync = ref.watch(_firmalarListProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile.adSoyad.isEmpty ? '(İsimsiz)' : profile.adSoyad,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                RoleBadge(rol: profile.rol),
              ],
            ),
            if (profile.telefon != null && profile.telefon!.isNotEmpty)
              Text(
                profile.telefon!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<KullaniciRolu>(
                  value: profile.rol,
                  underline: const SizedBox.shrink(),
                  items: KullaniciRolu.values
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r, child: Text(r.etiket)),
                      )
                      .toList(),
                  onChanged: (r) {
                    if (r == null) return;
                    ref
                        .read(profileRepositoryProvider)
                        .setRol(profile.id, r.dbValue)
                        .catchError(_hataGoster);
                  },
                ),
                firmalarAsync.when(
                  data: (firmalar) => DropdownButton<String?>(
                    value: profile.firmaId,
                    hint: const Text('Firma seç'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— Firma yok —'),
                      ),
                      ...firmalar.map(
                        (f) => DropdownMenuItem(value: f.id, child: Text(f.ad)),
                      ),
                    ],
                    onChanged: (v) => ref
                        .read(profileRepositoryProvider)
                        .setFirma(profile.id, v)
                        .catchError(_hataGoster),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                if (profile.rol == KullaniciRolu.isgUzmani ||
                    profile.rol == KullaniciRolu.santiyeSefi)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.apartment_outlined, size: 18),
                    label: const Text('Proje Ataması'),
                    onPressed: () => _projeAtamaDialogAc(context, ref, profile),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(profile.aktif ? 'Aktif' : 'Onay bekliyor'),
                    if (_aktifGuncelleniyor)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      AcikKapaliAnahtar(
                        value: profile.aktif,
                        onChanged: _aktifDegistir,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _projeAtamaDialogAc(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) async {
    final projeler = await ref.read(projeRepositoryProvider).fetchAll();
    final atanmis =
        (await ref
                .read(profileRepositoryProvider)
                .fetchAtananProjeIdleri(profile.id))
            .toSet();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _ProjeAtamaDialog(
        profile: profile,
        projeler: projeler,
        baslangicAtanmis: atanmis,
      ),
    );
  }
}

final _firmalarListProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(firmaRepositoryProvider).fetchAll();
});

class _ProjeAtamaDialog extends ConsumerStatefulWidget {
  const _ProjeAtamaDialog({
    required this.profile,
    required this.projeler,
    required this.baslangicAtanmis,
  });

  final ProfileModel profile;
  final List<ProjeModel> projeler;
  final Set<String> baslangicAtanmis;

  @override
  ConsumerState<_ProjeAtamaDialog> createState() => _ProjeAtamaDialogState();
}

class _ProjeAtamaDialogState extends ConsumerState<_ProjeAtamaDialog> {
  final Set<String> _secili = {};

  @override
  void initState() {
    super.initState();
    _secili.addAll(widget.baslangicAtanmis);
  }

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.profile.adSoyad} — Proje Ataması'),
      content: SizedBox(
        width: 360,
        child: widget.projeler.isEmpty
            ? const Text('Tanımlı proje bulunamadı.')
            : ListView(
                shrinkWrap: true,
                children: widget.projeler
                    .map(
                      (p) => CheckboxListTile(
                        title: Text(p.ad),
                        value: _secili.contains(p.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _secili.add(p.id);
                          } else {
                            _secili.remove(p.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _saving ? null : _kaydet,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }

  Future<void> _kaydet() async {
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    final eklenecek = _secili.difference(widget.baslangicAtanmis);
    final kaldirilacak = widget.baslangicAtanmis.difference(_secili);

    for (final projeId in eklenecek) {
      await repo.projeAta(widget.profile.id, projeId);
    }
    for (final projeId in kaldirilacak) {
      await repo.projeAtamasiKaldir(widget.profile.id, projeId);
    }

    if (mounted) Navigator.of(context).pop();
  }
}
