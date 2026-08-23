import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/indirilen_dosya.dart';
import '../../providers/indirilen_dosya_providers.dart';
import '../offline/yerel_depo.dart';

const indirilenlerAltDizini = 'indirilenler';

/// PDF/Excel dışa aktarımını native platformlarda kalıcı bir "İndirilenler"
/// klasöründe saklar, "İndirilen Dosyalar" ekranına kaydeder ve doğrudan
/// açar. Cihazda dosyayı açacak bir uygulama yoksa (örn. tabloyu açacak bir
/// Excel/Sheets uygulaması kurulu değilse) sistem paylaşım sayfasına düşer,
/// böylece kullanıcı dosyayı başka bir uygulamaya/cihaza gönderebilir. Web'de
/// tarayıcının kendi indirme mekanizması kullanılır (dosya cihazda kalıcı
/// saklanamaz, bu yüzden native'deki gibi tekrar açılamaz).
///
/// Dönüş değeri: dosyanın native'de yazıldığı kalıcı yol (web'de null).
Future<String?> disaAktarilanDosyayiKaydetVeAc({
  required WidgetRef ref,
  required String ad,
  required List<int> bytes,
  required String uzanti,
  required String tur,
  required MimeType mimeType,
  String? tutanakId,
}) async {
  final temizAd = YerelDepo.dosyaAdiTemizle(ad);
  final dosyaAdi = '$temizAd.$uzanti';
  String? yol;

  if (!kIsWeb) {
    yol = await YerelDepo.ikiliYaz(indirilenlerAltDizini, dosyaAdi, bytes);
  } else {
    await FileSaver.instance.saveFile(
      name: temizAd,
      bytes: Uint8List.fromList(bytes),
      fileExtension: uzanti,
      mimeType: mimeType,
    );
  }

  await ref.read(indirilenDosyaDeposuProvider).ekle(
        IndirilenDosya(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          ad: dosyaAdi,
          tur: tur,
          dosyaYolu: yol,
          tutanakId: tutanakId,
          olusturmaZamani: DateTime.now(),
        ),
      );
  ref.invalidate(indirilenDosyalarProvider);

  if (!kIsWeb && yol != null) {
    await dosyayiAcVeyaPaylas(yol);
  }

  return yol;
}

/// Dosyayı doğrudan açmayı dener; cihazda açabilecek bir uygulama yoksa
/// (`ResultType.noAppToOpen`) veya açma başarısız olursa sistem paylaşım
/// sayfasına düşer.
Future<void> dosyayiAcVeyaPaylas(String yol) async {
  final sonuc = await OpenFilex.open(yol);
  if (sonuc.type == ResultType.done) return;

  try {
    await SharePlus.instance.share(ShareParams(files: [XFile(yol)]));
  } catch (_) {
    // Paylaşım da başarısız olursa dosya yine de "İndirilen Dosyalar"
    // ekranında durur; kullanıcı oradan tekrar deneyebilir.
  }
}
