import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/tutanak_fotograf_model.dart';
import '../../data/models/tutanak_model.dart';
import '../../data/repositories/tutanak_repository.dart';
import '../../shared/widgets/tehlike_sinifi_badge.dart';
import '../../shared/widgets/tutanak_durum_badge.dart';

/// Faz 6 — tek bir tutanağı resmi bir rapor formatında PDF'e döker.
/// Türkçe karakterler (ğ, ş, ı, ö, ü, ç) standart PDF taban fontlarında
/// (WinAnsi kodlaması) eksik olduğundan Google Fonts'tan Noto Sans gömülür.
Future<List<int>> tutanakPdfOlustur({
  required TutanakModel tutanak,
  required List<TutanakFotografModel> fotograflar,
  required TutanakRepository repo,
}) async {
  final normalFont = await PdfGoogleFonts.notoSansRegular();
  final kalinFont = await PdfGoogleFonts.notoSansBold();

  final fotografResimleri = <pw.MemoryImage>[];
  for (final f in fotograflar) {
    try {
      final bytes = await repo.downloadFotograf(f.storagePath);
      fotografResimleri.add(pw.MemoryImage(bytes));
    } catch (_) {
      // Bir fotoğraf indirilemezse PDF'in geri kalanını engellemeden atla.
    }
  }

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: normalFont, bold: kalinFont),
  );

  final durumRengi = PdfColor.fromInt(TutanakDurumBadge.renk(tutanak.durum).toARGB32());
  final durumRengiAcik = _acikTon(durumRengi);
  final tarihFormat = DateFormat('dd.MM.yyyy');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'İSG Uygunsuzluk Tespit Tutanağı',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1),
        ],
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              tutanak.uttNo ?? '(Taslak)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                color: durumRengiAcik,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: durumRengi),
              ),
              child: pw.Text(
                tutanak.durum.etiket,
                style: pw.TextStyle(color: durumRengi, fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        _alan('Proje', tutanak.projeAdi ?? '-'),
        _alan('İlgili Firma', tutanak.firmaAdi ?? '-'),
        _alan('Tespit Tarihi', tarihFormat.format(tutanak.tespitTarihi)),
        _alan('Raporlayan', tutanak.raporlayanAdi ?? '-'),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Tehlike Sınıfı',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Container(
                    width: 16,
                    height: 16,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColor.fromInt(
                        TehlikeSinifiBadge.renk(tutanak.tehlikeSinifi).toARGB32(),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(tutanak.tehlikeSinifi.name, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        _alan('Uygunsuzluğun Tarifi', tutanak.aciklama),
        _alan(
          'Tavsiye ve Öneriler',
          (tutanak.tavsiyeOneri?.isNotEmpty ?? false) ? tutanak.tavsiyeOneri! : '-',
        ),
        _alan('Termin Tarihi', tutanak.terminTarihi ?? '-'),
        if (tutanak.cezaTutari != null) _alan('Cezai Yaptırım Bedeli', '${tutanak.cezaTutari} TL'),
        if ((tutanak.redRevizyonNotu ?? '').isNotEmpty)
          _alan('Red / Revizyon Notu', tutanak.redRevizyonNotu!),
        _alan('Oluşturma Tarihi', tarihFormat.format(tutanak.createdAt)),
        if (fotografResimleri.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Fotoğraflar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fotografResimleri
                .map(
                  (img) => pw.Container(
                    width: 150,
                    height: 150,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  return pdf.save();
}

/// Bir rengin, ekrandaki `withValues(alpha: 0.12)` rozet arka planına
/// benzeyen, beyaza doğru açılmış (tint) halini üretir.
PdfColor _acikTon(PdfColor renk, {double oran = 0.88}) {
  return PdfColor(
    renk.red + (1 - renk.red) * oran,
    renk.green + (1 - renk.green) * oran,
    renk.blue + (1 - renk.blue) * oran,
  );
}

pw.Widget _alan(String etiket, String deger) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          etiket,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(deger, style: const pw.TextStyle(fontSize: 12)),
      ],
    ),
  );
}
