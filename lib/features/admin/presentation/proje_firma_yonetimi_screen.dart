import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/firma_model.dart';
import '../../../data/models/osgb_model.dart';
import '../../../data/models/proje_model.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/acik_kapali_anahtar.dart';
import '../../../shared/widgets/app_text_field.dart';

final _tumProjelerProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(projeRepositoryProvider).watchAll();
});

final _tumFirmalarProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(firmaRepositoryProvider).watchAll();
});

final _tumOsgblarProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(osgbRepositoryProvider).watchAll();
});

/// Bölüm 5.7 — Admin Paneli / Proje-Firma Tanımları.
class ProjeFirmaYonetimiScreen extends StatelessWidget {
  const ProjeFirmaYonetimiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Proje / Firma Tanımları'),
          bottom: const TabBar(
            labelColor: Colors.white,
            tabs: [
              Tab(text: 'Projeler'),
              Tab(text: 'Firmalar'),
              Tab(text: 'OSGB'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ProjelerTab(), _FirmalarTab(), _OsgbTab()],
        ),
      ),
    );
  }
}

class _ProjelerTab extends ConsumerWidget {
  const _ProjelerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projelerAsync = ref.watch(_tumProjelerProvider);
    final osgblarAsync = ref.watch(_tumOsgblarProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _projeFormAc(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Proje'),
      ),
      body: projelerAsync.when(
        data: (projeler) => projeler.isEmpty
            ? const Center(child: Text('Henüz proje tanımlanmamış.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: projeler.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => _ProjeKarti(
                  proje: projeler[index],
                  osgbAdi: _osgbAdiBul(
                    osgblarAsync.valueOrNull,
                    projeler[index].osgbId,
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

String? _osgbAdiBul(List<OsgbModel>? osgblar, String? osgbId) {
  if (osgblar == null || osgbId == null) return null;
  for (final o in osgblar) {
    if (o.id == osgbId) return o.ad;
  }
  return null;
}

Future<bool> _silmeOnayiAl(
  BuildContext context,
  String baslik,
  String mesaj,
) async {
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(baslik),
      content: Text(mesaj),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}

void _silmeHatasiGoster(BuildContext context, Object e) {
  final mesaj = e is PostgrestException && e.code == '23503'
      ? 'Silinemedi: bu kayda bağlı proje/firma/tutanak veya personel kayıtları var. '
            'Önce bu bağlantıları kaldırın.'
      : 'Silinemedi: $e';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
}

Future<void> _projeFormAc(
  BuildContext context,
  WidgetRef ref, {
  ProjeModel? mevcut,
}) async {
  final adController = TextEditingController(text: mevcut?.ad ?? '');
  final yukleniciController = TextEditingController(
    text: mevcut?.yukleniciAdi ?? '',
  );
  final adresController = TextEditingController(text: mevcut?.adres ?? '');
  var seciliOsgbId = mevcut?.osgbId;
  final formKey = GlobalKey<FormState>();
  final osgblar = await ref.read(osgbRepositoryProvider).fetchAll();

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(mevcut == null ? 'Yeni Proje' : 'Projeyi Düzenle'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width * 0.9)
                .clamp(0, 380)
                .toDouble(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Proje Adı',
                  controller: adController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Proje adı zorunludur.'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Yüklenici Firma',
                  controller: yukleniciController,
                ),
                const SizedBox(height: 12),
                AppTextField(label: 'Adres', controller: adresController),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: seciliOsgbId,
                  decoration: const InputDecoration(labelText: 'OSGB'),
                  isExpanded: true,
                  menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— OSGB yok —'),
                    ),
                    ...osgblar.map(
                      (o) => DropdownMenuItem(value: o.id, child: Text(o.ad)),
                    ),
                  ],
                  onChanged: (v) => setState(() => seciliOsgbId = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (mevcut == null) {
                await ref
                    .read(projeRepositoryProvider)
                    .create(
                      ProjeModel(
                        id: '',
                        ad: adController.text.trim(),
                        yukleniciAdi: yukleniciController.text.trim(),
                        adres: adresController.text.trim(),
                        aktif: true,
                        osgbId: seciliOsgbId,
                      ),
                    );
              } else {
                await ref.read(projeRepositoryProvider).update(mevcut.id, {
                  'ad': adController.text.trim(),
                  'yuklenici_adi': yukleniciController.text.trim(),
                  'adres': adresController.text.trim(),
                  'osgb_id': seciliOsgbId,
                });
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ),
  );
}

class _ProjeKarti extends ConsumerStatefulWidget {
  const _ProjeKarti({required this.proje, this.osgbAdi});

  final ProjeModel proje;
  final String? osgbAdi;

  @override
  ConsumerState<_ProjeKarti> createState() => _ProjeKartiState();
}

class _ProjeKartiState extends ConsumerState<_ProjeKarti> {
  bool _aktifGuncelleniyor = false;

  Future<void> _aktifDegistir(bool v) async {
    setState(() => _aktifGuncelleniyor = true);
    try {
      await ref.read(projeRepositoryProvider).update(widget.proje.id, {
        'aktif': v,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Güncellenemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _aktifGuncelleniyor = false);
    }
  }

  Future<void> _sil() async {
    final onay = await _silmeOnayiAl(
      context,
      'Projeyi Sil',
      '"${widget.proje.ad}" projesini silmek istediğinize emin misiniz?',
    );
    if (!onay) return;
    try {
      await ref.read(projeRepositoryProvider).delete(widget.proje.id);
    } catch (e) {
      if (mounted) _silmeHatasiGoster(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proje;
    return Card(
      child: ListTile(
        title: Text(p.ad),
        subtitle: Text(
          [
            if (p.yukleniciAdi != null && p.yukleniciAdi!.isNotEmpty)
              'Yüklenici: ${p.yukleniciAdi}',
            if (p.adres != null && p.adres!.isNotEmpty) p.adres!,
            if (widget.osgbAdi != null) 'OSGB: ${widget.osgbAdi}',
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _aktifGuncelleniyor
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AcikKapaliAnahtar(value: p.aktif, onChanged: _aktifDegistir),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Sil',
              onPressed: _sil,
            ),
          ],
        ),
        onTap: () => _projeFormAc(context, ref, mevcut: p),
      ),
    );
  }
}

class _FirmalarTab extends ConsumerWidget {
  const _FirmalarTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firmalarAsync = ref.watch(_tumFirmalarProvider);
    final projelerAsync = ref.watch(_tumProjelerProvider);
    final osgblarAsync = ref.watch(_tumOsgblarProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _firmaFormAc(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Firma'),
      ),
      body: firmalarAsync.when(
        data: (firmalar) => firmalar.isEmpty
            ? const Center(child: Text('Henüz firma tanımlanmamış.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: firmalar.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final f = firmalar[index];
                  final proje = _projeBul(projelerAsync.valueOrNull, f.projeId);
                  final osgbAdi = proje == null
                      ? null
                      : _osgbAdiBul(osgblarAsync.valueOrNull, proje.osgbId);
                  final altBaslikParcalari = <String>[
                    if (proje != null) 'İnşaat: ${proje.ad}',
                    if (osgbAdi != null) 'OSGB: $osgbAdi',
                  ];
                  return Card(
                    child: ListTile(
                      title: Text(f.ad),
                      subtitle: Text(
                        altBaslikParcalari.isEmpty
                            ? '—'
                            : altBaslikParcalari.join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Sil',
                        onPressed: () async {
                          final onay = await _silmeOnayiAl(
                            context,
                            'Firmayı Sil',
                            '"${f.ad}" firmasını silmek istediğinize emin misiniz?',
                          );
                          if (!onay) return;
                          try {
                            await ref
                                .read(firmaRepositoryProvider)
                                .delete(f.id);
                          } catch (e) {
                            if (context.mounted) _silmeHatasiGoster(context, e);
                          }
                        },
                      ),
                      onTap: () => _firmaFormAc(context, ref, mevcut: f),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }

  static ProjeModel? _projeBul(List<ProjeModel>? projeler, String? projeId) {
    if (projeler == null || projeId == null) return null;
    for (final p in projeler) {
      if (p.id == projeId) return p;
    }
    return null;
  }

  Future<void> _firmaFormAc(
    BuildContext context,
    WidgetRef ref, {
    FirmaModel? mevcut,
  }) async {
    final adController = TextEditingController(text: mevcut?.ad ?? '');
    var seciliProjeId = mevcut?.projeId;
    final formKey = GlobalKey<FormState>();
    final projeler = await ref.read(projeRepositoryProvider).fetchAll();
    final osgblar = await ref.read(osgbRepositoryProvider).fetchAll();

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final seciliProje = _projeBul(projeler, seciliProjeId);
          final seciliOsgbAdi = seciliProje == null
              ? null
              : _osgbAdiBul(osgblar, seciliProje.osgbId);
          return AlertDialog(
            title: Text(mevcut == null ? 'Yeni Firma' : 'Firmayı Düzenle'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: (MediaQuery.sizeOf(context).width * 0.9)
                    .clamp(0, 360)
                    .toDouble(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Firma Adı',
                      controller: adController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Firma adı zorunludur.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: seciliProjeId,
                      decoration: const InputDecoration(
                        labelText: 'İnşaat (Proje)',
                      ),
                      isExpanded: true,
                      menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— Seçilmedi —'),
                        ),
                        ...projeler.map(
                          (p) =>
                              DropdownMenuItem(value: p.id, child: Text(p.ad)),
                        ),
                      ],
                      onChanged: (v) => setState(() => seciliProjeId = v),
                    ),
                    if (seciliProjeId != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'OSGB: ${seciliOsgbAdi ?? '— Bu inşaata OSGB atanmamış —'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (mevcut == null) {
                    await ref
                        .read(firmaRepositoryProvider)
                        .create(
                          FirmaModel(
                            id: '',
                            ad: adController.text.trim(),
                            projeId: seciliProjeId,
                          ),
                        );
                  } else {
                    await ref.read(firmaRepositoryProvider).update(mevcut.id, {
                      'ad': adController.text.trim(),
                      'proje_id': seciliProjeId,
                    });
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OsgbTab extends ConsumerWidget {
  const _OsgbTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final osgblarAsync = ref.watch(_tumOsgblarProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _osgbFormAc(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni OSGB'),
      ),
      body: osgblarAsync.when(
        data: (osgblar) => osgblar.isEmpty
            ? const Center(child: Text('Henüz OSGB tanımlanmamış.'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: osgblar.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final o = osgblar[index];
                  return Card(
                    child: ListTile(
                      title: Text(o.ad),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Sil',
                        onPressed: () async {
                          final onay = await _silmeOnayiAl(
                            context,
                            'OSGB Sil',
                            '"${o.ad}" OSGB\'sini silmek istediğinize emin misiniz?',
                          );
                          if (!onay) return;
                          try {
                            await ref.read(osgbRepositoryProvider).delete(o.id);
                          } catch (e) {
                            if (context.mounted) _silmeHatasiGoster(context, e);
                          }
                        },
                      ),
                      onTap: () => _osgbFormAc(context, ref, mevcut: o),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }

  Future<void> _osgbFormAc(
    BuildContext context,
    WidgetRef ref, {
    OsgbModel? mevcut,
  }) async {
    final adController = TextEditingController(text: mevcut?.ad ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mevcut == null ? 'Yeni OSGB' : 'OSGB Düzenle'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: (MediaQuery.sizeOf(context).width * 0.9)
                .clamp(0, 360)
                .toDouble(),
            child: AppTextField(
              label: 'OSGB Adı',
              controller: adController,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'OSGB adı zorunludur.'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (mevcut == null) {
                await ref
                    .read(osgbRepositoryProvider)
                    .create(OsgbModel(id: '', ad: adController.text.trim()));
              } else {
                await ref.read(osgbRepositoryProvider).update(mevcut.id, {
                  'ad': adController.text.trim(),
                });
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
