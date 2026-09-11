import 'package:flutter_test/flutter_test.dart';
import 'package:isg_uygunsuzluk_tespit/data/models/firma_model.dart';
import 'package:isg_uygunsuzluk_tespit/features/tutanak/presentation/tutanak_form_screen.dart';

void main() {
  final aksoy = const FirmaModel(id: 'f-aksoy', ad: 'Aksoy', projeId: 'p-nli');
  final baskaFirma =
      const FirmaModel(id: 'f-baska', ad: 'Başka Firma', projeId: 'p-diger');
  final globalFirma = const FirmaModel(id: 'f-global', ad: 'Global Firma');
  final tumFirmalar = [aksoy, baskaFirma, globalFirma];

  test('seçili projeye ait olmayan firmaları eler', () {
    final sonuc = firmalarProjeyeGoreFiltrele(tumFirmalar, 'p-nli');
    expect(sonuc.map((f) => f.id), containsAll(['f-aksoy', 'f-global']));
    expect(sonuc.map((f) => f.id), isNot(contains('f-baska')));
  });

  test('proje_id atanmamış (global) firmalar her projede görünür', () {
    final sonuc = firmalarProjeyeGoreFiltrele(tumFirmalar, 'p-diger');
    expect(sonuc.map((f) => f.id), containsAll(['f-baska', 'f-global']));
    expect(sonuc.map((f) => f.id), isNot(contains('f-aksoy')));
  });

  test('proje seçilmemişse tüm firmalar döner', () {
    final sonuc = firmalarProjeyeGoreFiltrele(tumFirmalar, null);
    expect(sonuc, tumFirmalar);
  });

  test('mevcut seçili firma, yeni projeye ait olmasa bile listede kalır (düzenleme modu)', () {
    final sonuc = firmalarProjeyeGoreFiltrele(
      tumFirmalar,
      'p-diger',
      mevcutSeciliFirmaId: 'f-aksoy',
    );
    expect(sonuc.map((f) => f.id), contains('f-aksoy'));
  });
}
