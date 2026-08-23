import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Uygulama belgeleri dizininde basit JSON tabanlı anahtar-değer depolama.
/// Faz 5 — offline taslak kuyruğu ve proje/firma önbelleği bunun üzerine kurulu.
class YerelDepo {
  YerelDepo._();

  static Future<Directory> _dizin() async {
    final belgeler = await getApplicationDocumentsDirectory();
    final dizin = Directory('${belgeler.path}/yerel_depo');
    if (!await dizin.exists()) await dizin.create(recursive: true);
    return dizin;
  }

  static Future<File> _dosya(String anahtar) async {
    final dizin = await _dizin();
    return File('${dizin.path}/$anahtar.json');
  }

  static Future<void> yaz(String anahtar, Object? veri) async {
    final dosya = await _dosya(anahtar);
    await dosya.writeAsString(jsonEncode(veri));
  }

  static Future<dynamic> oku(String anahtar) async {
    final dosya = await _dosya(anahtar);
    if (!await dosya.exists()) return null;
    try {
      return jsonDecode(await dosya.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Dosya/dizin adında yol ayırıcı gibi davranıp var olmayan bir alt
  /// dizine yazma denemesine yol açabilecek karakterleri temizler
  /// (örn. UTT No "26/3" gibi bir "/" içerebiliyor).
  static String dosyaAdiTemizle(String ad) {
    return ad.replaceAll(RegExp(r'[/\\:*?"<>|]'), '-');
  }

  /// Fotoğraf gibi ikili verileri kalıcı bir dosyaya yazar ve tam yolunu döner.
  /// `altDizinAdi` kasıtlı olarak iç içe segmentler içerebilir (örn.
  /// `'kuyruk/$id'`) — yalnızca dosyanın kendi adı (`dosyaAdi`) temizlenir.
  static Future<String> ikiliYaz(String altDizinAdi, String dosyaAdi, List<int> bytes) async {
    final belgeler = await getApplicationDocumentsDirectory();
    final dizin = Directory('${belgeler.path}/$altDizinAdi');
    if (!await dizin.exists()) await dizin.create(recursive: true);
    final dosya = File('${dizin.path}/${dosyaAdiTemizle(dosyaAdi)}');
    await dosya.writeAsBytes(bytes);
    return dosya.path;
  }

  static Future<void> dosyaSil(String yol) async {
    final dosya = File(yol);
    if (await dosya.exists()) await dosya.delete();
  }

  static Future<void> dizinSil(String altDizinAdi) async {
    final belgeler = await getApplicationDocumentsDirectory();
    final dizin = Directory('${belgeler.path}/$altDizinAdi');
    if (await dizin.exists()) await dizin.delete(recursive: true);
  }
}
