import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../data/models/firma_model.dart';
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

/// Bölüm 5.7 — Admin Paneli / Proje-Firma Tanımları.
class ProjeFirmaYonetimiScreen extends StatelessWidget {
  const ProjeFirmaYonetimiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Proje / Firma Tanımları'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Projeler'), Tab(text: 'Firmalar')],
          ),
        ),
        body: const TabBarView(
          children: [_ProjelerTab(), _FirmalarTab()],
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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ProjeKarti(proje: projeler[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

Future<void> _projeFormAc(BuildContext context, WidgetRef ref, {ProjeModel? mevcut}) async {
  final adController = TextEditingController(text: mevcut?.ad ?? '');
  final yukleniciController = TextEditingController(text: mevcut?.yukleniciAdi ?? '');
  final adresController = TextEditingController(text: mevcut?.adres ?? '');
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(mevcut == null ? 'Yeni Proje' : 'Projeyi Düzenle'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Proje Adı',
                controller: adController,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Proje adı zorunludur.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Yüklenici Firma', controller: yukleniciController),
              const SizedBox(height: 12),
              AppTextField(label: 'Adres', controller: adresController),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            if (mevcut == null) {
              await ref.read(projeRepositoryProvider).create(
                    ProjeModel(
                      id: '',
                      ad: adController.text.trim(),
                      yukleniciAdi: yukleniciController.text.trim(),
                      adres: adresController.text.trim(),
                      aktif: true,
                    ),
                  );
            } else {
              await ref.read(projeRepositoryProvider).update(mevcut.id, {
                'ad': adController.text.trim(),
                'yuklenici_adi': yukleniciController.text.trim(),
                'adres': adresController.text.trim(),
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

class _ProjeKarti extends ConsumerStatefulWidget {
  const _ProjeKarti({required this.proje});

  final ProjeModel proje;

  @override
  ConsumerState<_ProjeKarti> createState() => _ProjeKartiState();
}

class _ProjeKartiState extends ConsumerState<_ProjeKarti> {
  bool _aktifGuncelleniyor = false;

  Future<void> _aktifDegistir(bool v) async {
    setState(() => _aktifGuncelleniyor = true);
    try {
      await ref.read(projeRepositoryProvider).update(widget.proje.id, {'aktif': v});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncellenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _aktifGuncelleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.proje;
    return Card(
      child: ListTile(
        title: Text(p.ad),
        subtitle: Text([
          if (p.yukleniciAdi != null && p.yukleniciAdi!.isNotEmpty) 'Yüklenici: ${p.yukleniciAdi}',
          if (p.adres != null && p.adres!.isNotEmpty) p.adres!,
        ].join(' · ')),
        trailing: _aktifGuncelleniyor
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : AcikKapaliAnahtar(value: p.aktif, onChanged: _aktifDegistir),
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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final f = firmalar[index];
                  return Card(
                    child: ListTile(
                      title: Text(f.ad),
                      subtitle: Text(f.tur.etiket),
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

  Future<void> _firmaFormAc(BuildContext context, WidgetRef ref, {FirmaModel? mevcut}) async {
    final adController = TextEditingController(text: mevcut?.ad ?? '');
    var seciliTur = mevcut?.tur ?? FirmaTuru.taseron;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(mevcut == null ? 'Yeni Firma' : 'Firmayı Düzenle'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'Firma Adı',
                    controller: adController,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Firma adı zorunludur.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FirmaTuru>(
                    initialValue: seciliTur,
                    decoration: const InputDecoration(labelText: 'Firma Türü'),
                    items: FirmaTuru.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.etiket)))
                        .toList(),
                    onChanged: (v) => setState(() => seciliTur = v ?? seciliTur),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (mevcut == null) {
                  await ref.read(firmaRepositoryProvider).create(
                        FirmaModel(id: '', ad: adController.text.trim(), tur: seciliTur),
                      );
                } else {
                  await ref.read(firmaRepositoryProvider).update(mevcut.id, {
                    'ad': adController.text.trim(),
                    'tur': seciliTur.dbValue,
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
}
