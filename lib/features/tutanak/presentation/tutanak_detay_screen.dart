import 'package:file_saver/file_saver.dart' show MimeType;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/export/disa_aktarilan_dosya_servisi.dart';
import '../../../core/export/tutanak_pdf_olusturucu.dart';
import '../../../data/models/tutanak_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../providers/tutanak_providers.dart';
import '../../../shared/widgets/tehlike_sinifi_badge.dart';
import '../../../shared/widgets/tutanak_durum_badge.dart';

/// Bölüm 5.5 — Tutanak Detay Ekranı: tüm alanlar salt okunur; ceza tutarı
/// satırı yalnızca yetkili rollerde (server zaten redakte ediyor) görünür;
/// yetkili roller için Onayla/Reddet/Revizyon İste aksiyonları bulunur (Bölüm 7).
class TutanakDetayScreen extends ConsumerWidget {
  const TutanakDetayScreen({super.key, required this.tutanakId});

  final String tutanakId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutanakAsync = ref.watch(tutanakDetayProvider(tutanakId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutanak Detayı'),
        actions: [
          if (tutanakAsync.valueOrNull != null)
            IconButton(
              tooltip: 'PDF olarak dışa aktar',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _pdfDisaAktar(context, ref, tutanakAsync.value!),
            ),
        ],
      ),
      body: tutanakAsync.when(
        data: (tutanak) {
          if (tutanak == null) {
            return const Center(child: Text('Tutanak bulunamadı.'));
          }
          return _DetayIcerik(tutanak: tutanak);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

Future<void> _pdfDisaAktar(BuildContext context, WidgetRef ref, TutanakModel tutanak) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('PDF hazırlanıyor...')),
        ],
      ),
    ),
  );

  try {
    final repo = ref.read(tutanakRepositoryProvider);
    final fotograflar = await repo.fetchFotograflar(tutanak.id);
    final bytes = await tutanakPdfOlustur(tutanak: tutanak, fotograflar: fotograflar, repo: repo);

    final yol = await disaAktarilanDosyayiKaydetVeAc(
      ref: ref,
      ad: 'tutanak_${tutanak.uttNo ?? tutanak.id}',
      bytes: bytes,
      uzanti: 'pdf',
      tur: 'pdf',
      mimeType: MimeType.pdf,
      tutanakId: tutanak.id,
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (kIsWeb || yol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF indirildi.')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF oluşturulamadı: $e')),
    );
  }
}

class _DetayIcerik extends ConsumerWidget {
  const _DetayIcerik({required this.tutanak});

  final TutanakModel tutanak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(currentRoleProvider);
    final userId = ref.watch(currentUserIdProvider);
    final fotograflarAsync = ref.watch(tutanakFotografUrlleriProvider(tutanak.id));

    final incelemeYetkisi = rol == KullaniciRolu.admin || rol == KullaniciRolu.isgUzmani;
    final duzenleyebilir =
        tutanak.duzenlenebilir && tutanak.raporlayanId == userId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tutanak.uttNo ?? '(Taslak)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TutanakDurumBadge(durum: tutanak.durum),
          ],
        ),
        const SizedBox(height: 16),
        _alan('Proje', tutanak.projeAdi ?? '-'),
        _alan('İlgili Firma', tutanak.firmaAdi ?? '-'),
        _alan('Tarih', DateFormat('dd.MM.yyyy').format(tutanak.tespitTarihi)),
        _alan('Raporlayan', tutanak.raporlayanAdi ?? '-'),
        Row(
          children: [
            const SizedBox(
              width: 140,
              child: Text('Tehlike Sınıfı', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            TehlikeSinifiBadge(sinif: tutanak.tehlikeSinifi),
          ],
        ),
        const SizedBox(height: 12),
        _alan('Uygunsuzluğun Tarifi', tutanak.aciklama),
        _alan('Tavsiye ve Öneriler', tutanak.tavsiyeOneri?.isNotEmpty == true ? tutanak.tavsiyeOneri! : '-'),
        _alan('Termin Tarihi', tutanak.terminTarihi ?? '-'),
        if (tutanak.cezaTutari != null)
          _alan('Cezai Yaptırım Bedeli', '${tutanak.cezaTutari} TL'),
        if (tutanak.redRevizyonNotu != null && tutanak.redRevizyonNotu!.isNotEmpty)
          _alan('Red / Revizyon Notu', tutanak.redRevizyonNotu!),
        const SizedBox(height: 8),
        const Text('Fotoğraflar', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        fotograflarAsync.when(
          data: (fotograflar) => fotograflar.isEmpty
              ? const Text('Fotoğraf eklenmemiş.')
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final f in fotograflar)
                      GestureDetector(
                        onTap: () => _fotografiTamEkranAc(context, f.url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            f.url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Fotoğraflar yüklenemedi: $e'),
        ),
        const SizedBox(height: 24),
        if (duzenleyebilir)
          OutlinedButton.icon(
            onPressed: () => context.push('/tutanak/duzenle/${tutanak.id}'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Düzenle'),
          ),
        if (incelemeYetkisi) ...[
          const SizedBox(height: 12),
          _IncelemeAksiyonlari(tutanak: tutanak),
        ],
        if (rol == KullaniciRolu.admin) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _cezaTutariDialogAc(context, ref, tutanak),
            icon: const Icon(Icons.payments_outlined),
            label: Text(tutanak.cezaTutari == null ? 'Ceza Tutarı Gir' : 'Ceza Tutarını Düzenle'),
          ),
        ],
      ],
    );
  }

  Widget _alan(String label, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(deger),
        ],
      ),
    );
  }

  void _fotografiTamEkranAc(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          body: Center(
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      ),
    );
  }

  Future<void> _cezaTutariDialogAc(BuildContext context, WidgetRef ref, TutanakModel tutanak) async {
    final controller = TextEditingController(text: tutanak.cezaTutari?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cezai Yaptırım Bedeli'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tutar (TL)'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Tutar zorunludur.';
              if (num.tryParse(v.replaceAll(',', '.')) == null) return 'Geçerli bir sayı girin.';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final tutar = num.parse(controller.text.replaceAll(',', '.'));
              await ref.read(tutanakRepositoryProvider).cezaTutariGir(tutanak.id, tutar);
              ref.invalidate(tutanakDetayProvider(tutanak.id));
              ref.invalidate(tutanakListProvider(const TutanakFiltre()));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _IncelemeAksiyonlari extends ConsumerStatefulWidget {
  const _IncelemeAksiyonlari({required this.tutanak});

  final TutanakModel tutanak;

  @override
  ConsumerState<_IncelemeAksiyonlari> createState() => _IncelemeAksiyonlariState();
}

class _IncelemeAksiyonlariState extends ConsumerState<_IncelemeAksiyonlari> {
  bool _isleniyor = false;

  Future<void> _durumDegistir(TutanakDurumu yeniDurum, {String? not}) async {
    setState(() => _isleniyor = true);
    try {
      await ref.read(tutanakRepositoryProvider).durumDegistir(
            tutanakId: widget.tutanak.id,
            yeniDurum: yeniDurum,
            not: not,
          );
      ref.invalidate(tutanakDetayProvider(widget.tutanak.id));
      ref.invalidate(tutanakListProvider(const TutanakFiltre()));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Durum güncellendi: ${yeniDurum.etiket}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isleniyor = false);
    }
  }

  Future<void> _notluDurumDegistir(TutanakDurumu yeniDurum, String baslik) async {
    final controller = TextEditingController();
    final not = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(baslik),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Gerekçe / Not'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (not == null) return;
    await _durumDegistir(yeniDurum, not: not.isEmpty ? null : not);
  }

  @override
  Widget build(BuildContext context) {
    final durum = widget.tutanak.durum;
    final buttons = <Widget>[];

    if (durum == TutanakDurumu.gonderildi) {
      buttons.add(OutlinedButton.icon(
        onPressed: _isleniyor ? null : () => _durumDegistir(TutanakDurumu.incelemede),
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('İncelemeye Al'),
      ));
    }

    if (durum == TutanakDurumu.gonderildi || durum == TutanakDurumu.incelemede) {
      buttons.addAll([
        FilledButton.icon(
          onPressed: _isleniyor ? null : () => _durumDegistir(TutanakDurumu.onaylandi),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Onayla'),
        ),
        OutlinedButton.icon(
          onPressed: _isleniyor
              ? null
              : () => _notluDurumDegistir(TutanakDurumu.revizyonIstendi, 'Revizyon İste'),
          icon: const Icon(Icons.replay_outlined),
          label: const Text('Revizyon İste'),
        ),
        OutlinedButton.icon(
          onPressed: _isleniyor
              ? null
              : () => _notluDurumDegistir(TutanakDurumu.reddedildi, 'Reddet'),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: const Text('Reddet', style: TextStyle(color: Colors.red)),
        ),
      ]);
    }

    if (durum == TutanakDurumu.onaylandi) {
      buttons.add(FilledButton.icon(
        onPressed: _isleniyor ? null : () => _durumDegistir(TutanakDurumu.kapatildi),
        icon: const Icon(Icons.task_alt_outlined),
        label: const Text('Kapat (Düzeltici Faaliyet Tamamlandı)'),
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 10, runSpacing: 10, children: buttons);
  }
}
