import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_enums.dart';
import '../models/tutanak_fotograf_model.dart';
import '../models/tutanak_model.dart';

class TutanakRepository {
  TutanakRepository(this._client);

  final SupabaseClient _client;

  String _tarihStr(DateTime d) => d.toIso8601String().split('T').first;

  /// Rol bazlı görünürlük ve ceza_tutari redaksiyonu `get_tutanaklar()` RPC'si
  /// içinde uygulanır (Bölüm 10.2) — doğrudan tablo sorgusu kullanılmaz.
  Future<List<TutanakModel>> fetchList({String? projeId, TutanakDurumu? durum}) async {
    final rows = await _client.rpc(DbFunctions.getTutanaklar, params: {
      'p_proje_id': projeId,
      'p_durum': durum?.dbValue,
    });
    return (rows as List)
        .map((e) => TutanakModel.fromRpcJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TutanakModel>> fetchOwnList() async {
    final userId = _client.auth.currentUser?.id;
    final all = await fetchList();
    return all.where((t) => t.raporlayanId == userId).toList();
  }

  Future<TutanakModel?> fetchById(String id) async {
    final rows = await _client.rpc(DbFunctions.getTutanaklar, params: {'p_id': id});
    final list = rows as List;
    if (list.isEmpty) return null;
    return TutanakModel.fromRpcJson(list.first as Map<String, dynamic>);
  }

  Future<String> createTutanak({
    required String projeId,
    required String firmaId,
    required DateTime tespitTarihi,
    required TehlikeSinifi tehlikeSinifi,
    required String aciklama,
    String? tavsiyeOneri,
    String? terminTarihi,
    required TutanakDurumu durum,
  }) async {
    final raporlayanId = _client.auth.currentUser!.id;
    final row = await _client
        .from(DbTables.tutanaklar)
        .insert({
          'proje_id': projeId,
          'firma_id': firmaId,
          'raporlayan_id': raporlayanId,
          'tespit_tarihi': _tarihStr(tespitTarihi),
          'tehlike_sinifi': tehlikeSinifi.name,
          'aciklama': aciklama,
          'tavsiye_oneri': tavsiyeOneri,
          'termin_tarihi': terminTarihi,
          'durum': durum.dbValue,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateTutanak(
    String id, {
    required String projeId,
    required String firmaId,
    required DateTime tespitTarihi,
    required TehlikeSinifi tehlikeSinifi,
    required String aciklama,
    String? tavsiyeOneri,
    String? terminTarihi,
    required TutanakDurumu durum,
  }) {
    return _client.from(DbTables.tutanaklar).update({
      'proje_id': projeId,
      'firma_id': firmaId,
      'tespit_tarihi': _tarihStr(tespitTarihi),
      'tehlike_sinifi': tehlikeSinifi.name,
      'aciklama': aciklama,
      'tavsiye_oneri': tavsiyeOneri,
      'termin_tarihi': terminTarihi,
      'durum': durum.dbValue,
    }).eq('id', id);
  }

  Future<List<TutanakFotografModel>> fetchFotograflar(String tutanakId) async {
    final rows = await _client
        .from(DbTables.tutanakFotograflari)
        .select()
        .eq('tutanak_id', tutanakId)
        .order('sira_no');
    return (rows as List).map((e) => TutanakFotografModel.fromJson(e)).toList();
  }

  /// Bucket yapısı: tutanak-fotograflari/{proje_id}/{tutanak_id}/{sira}.jpg (Bölüm 11).
  Future<TutanakFotografModel> uploadFotograf({
    required String projeId,
    required String tutanakId,
    required int siraNo,
    required Uint8List bytes,
  }) async {
    // Dosya adı benzersiz üretilir (RLS yalnızca proje_id/tutanak_id klasör
    // bileşenlerini kontrol eder); sira_no kolonu görüntülenme sırasını tutar.
    final dosyaAdi = '${DateTime.now().microsecondsSinceEpoch}_$siraNo.jpg';
    final path = '$projeId/$tutanakId/$dosyaAdi';
    await _client.storage.from(StorageBuckets.tutanakFotograflari).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    final row = await _client
        .from(DbTables.tutanakFotograflari)
        .insert({
          'tutanak_id': tutanakId,
          'storage_path': path,
          'sira_no': siraNo,
          'yuklenen_id': _client.auth.currentUser!.id,
        })
        .select()
        .single();
    return TutanakFotografModel.fromJson(row);
  }

  Future<void> deleteFotograf(TutanakFotografModel foto) async {
    await _client.storage.from(StorageBuckets.tutanakFotograflari).remove([foto.storagePath]);
    await _client.from(DbTables.tutanakFotograflari).delete().eq('id', foto.id);
  }

  Future<String> getSignedUrl(String storagePath, {int expiresInSaniye = 3600}) {
    return _client.storage
        .from(StorageBuckets.tutanakFotograflari)
        .createSignedUrl(storagePath, expiresInSaniye);
  }

  /// PDF'e gömmek için fotoğrafın ham baytlarını indirir (imzalı URL/HTTP
  /// dolaşımı gerekmez — Faz 6 PDF dışa aktarma).
  Future<Uint8List> downloadFotograf(String storagePath) {
    return _client.storage.from(StorageBuckets.tutanakFotograflari).download(storagePath);
  }

  /// Onayla/Reddet/Revizyon İste/Kapat (Bölüm 7) — `tutanak_durum_degistir()` RPC'si
  /// yetki ve durum geçişi kontrolünü sunucu tarafında yapar.
  Future<void> durumDegistir({
    required String tutanakId,
    required TutanakDurumu yeniDurum,
    String? not,
  }) {
    return _client.rpc(DbFunctions.tutanakDurumDegistir, params: {
      'p_tutanak_id': tutanakId,
      'p_yeni_durum': yeniDurum.dbValue,
      'p_not': not,
    });
  }

  /// Yalnızca Admin — `set_ceza_tutari()` RPC'si (Bölüm 10.2).
  Future<void> cezaTutariGir(String tutanakId, num tutar) {
    return _client.rpc(DbFunctions.setCezaTutari, params: {
      'p_tutanak_id': tutanakId,
      'p_tutar': tutar,
    });
  }
}
