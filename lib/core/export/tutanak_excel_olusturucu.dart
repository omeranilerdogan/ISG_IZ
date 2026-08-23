import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';

import '../../data/models/tutanak_model.dart';

const _basliklar = [
  'UTT No',
  'Proje',
  'Firma',
  'Raporlayan',
  'Tespit Tarihi',
  'Tehlike Sınıfı',
  'Uygunsuzluğun Tarifi',
  'Tavsiye ve Öneriler',
  'Termin Tarihi',
  'Ceza Tutarı (TL)',
  'Durum',
];

/// Faz 6 — filtrelenmiş tutanak listesini bir .xlsx dosyasına döker.
List<int> tutanakListesiExcelOlustur(List<TutanakModel> liste) {
  final workbook = xls.Excel.createExcel();
  final sayfaAdi = 'Tutanaklar';
  final sayfa = workbook[sayfaAdi];
  workbook.setDefaultSheet(sayfaAdi);
  for (final ad in workbook.sheets.keys.toList()) {
    if (ad != sayfaAdi) workbook.delete(ad);
  }

  sayfa.appendRow(_basliklar.map((b) => xls.TextCellValue(b)).toList());

  final tarihFormat = DateFormat('dd.MM.yyyy');
  for (final t in liste) {
    sayfa.appendRow([
      xls.TextCellValue(t.uttNo ?? ''),
      xls.TextCellValue(t.projeAdi ?? ''),
      xls.TextCellValue(t.firmaAdi ?? ''),
      xls.TextCellValue(t.raporlayanAdi ?? ''),
      xls.TextCellValue(tarihFormat.format(t.tespitTarihi)),
      xls.TextCellValue(t.tehlikeSinifi.name),
      xls.TextCellValue(t.aciklama),
      xls.TextCellValue(t.tavsiyeOneri ?? ''),
      xls.TextCellValue(t.terminTarihi ?? ''),
      t.cezaTutari != null
          ? xls.DoubleCellValue(t.cezaTutari!.toDouble())
          : xls.TextCellValue(''),
      xls.TextCellValue(t.durum.etiket),
    ]);
  }

  return workbook.save() ?? <int>[];
}
