import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/export/disa_aktarilan_dosya_servisi.dart';
import '../../../data/models/indirilen_dosya.dart';
import '../../../providers/indirilen_dosya_providers.dart';

/// Faz 6 — PDF/Excel dışa aktarımlarının cihazda saklandığı listeyi gösterir;
/// dokunulduğunda dosya doğrudan (native varsayılan uygulamasıyla) açılır.
class IndirilenDosyalarScreen extends ConsumerWidget {
  const IndirilenDosyalarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listeAsync = ref.watch(indirilenDosyalarProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('İndirilen Dosyalar')),
      body: listeAsync.when(
        data: (liste) => liste.isEmpty
            ? const Center(child: Text('Henüz indirilen dosya yok.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: liste.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _DosyaKarti(dosya: liste[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _DosyaKarti extends ConsumerWidget {
  const _DosyaKarti({required this.dosya});

  final IndirilenDosya dosya;

  Future<void> _ac(BuildContext context) async {
    if (kIsWeb || dosya.dosyaYolu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu dosya tarayıcınızın indirilenler klasörüne kaydedildi.'),
        ),
      );
      return;
    }
    if (!File(dosya.dosyaYolu!).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya bulunamadı, tekrar dışa aktarın.')),
      );
      return;
    }
    await dosyayiAcVeyaPaylas(dosya.dosyaYolu!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfMi = dosya.tur == 'pdf';
    return Card(
      child: ListTile(
        leading: Icon(
          pdfMi ? Icons.picture_as_pdf_outlined : Icons.table_view_outlined,
          color: pdfMi ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        ),
        title: Text(dosya.ad, overflow: TextOverflow.ellipsis),
        subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(dosya.olusturmaZamani)),
        trailing: IconButton(
          tooltip: 'Kayıttan kaldır',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref.read(indirilenDosyaDeposuProvider).sil(dosya.id);
            ref.invalidate(indirilenDosyalarProvider);
          },
        ),
        onTap: () => _ac(context),
      ),
    );
  }
}
