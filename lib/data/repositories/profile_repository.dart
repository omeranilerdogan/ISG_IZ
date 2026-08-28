import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel?> fetchById(String id) async {
    final row = await _client
        .from(DbTables.profiles)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ProfileModel.fromJson(row);
  }

  /// Oturum sahibinin profilini realtime izler; admin onayı (aktif) veya
  /// rol değişikliği yapıldığında arayüz anında güncellenir.
  Stream<ProfileModel?> watchById(String id) {
    return _client
        .from(DbTables.profiles)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isEmpty ? null : ProfileModel.fromJson(rows.first));
  }

  Future<void> updateOwnProfile(ProfileModel profile) {
    return _client
        .from(DbTables.profiles)
        .update(profile.toUpdateJson())
        .eq('id', profile.id);
  }

  // --- Admin işlemleri (Bölüm 5.7 Personel Yönetimi) ---

  Future<List<ProfileModel>> fetchAll() async {
    final rows = await _client
        .from(DbTables.profiles)
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Stream<List<ProfileModel>> watchAll() {
    return _client
        .from(DbTables.profiles)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(ProfileModel.fromJson).toList());
  }

  /// `.select()` eklenmesinin nedeni: RLS politikası satırı reddettiğinde
  /// PostgREST `.update()` tek başına hata fırlatmaz, sessizce 0 satır
  /// günceller. `.select()` ile dönen liste boşsa bunu açık bir hataya
  /// çeviriyoruz; aksi halde arayüzde (örn. Switch) "tıklanıyor ama hiçbir
  /// şey olmuyor" görünümü oluşur.
  Future<void> setAktif(String userId, bool aktif) async {
    final rows = await _client
        .from(DbTables.profiles)
        .update({'aktif': aktif})
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  Future<void> setRol(String userId, String rolDbValue) async {
    final rows = await _client
        .from(DbTables.profiles)
        .update({'rol': rolDbValue})
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  Future<void> setFirma(String userId, String? firmaId) async {
    final rows = await _client
        .from(DbTables.profiles)
        .update({'firma_id': firmaId})
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  Future<void> setOsgb(String userId, String? osgbId) async {
    final rows = await _client
        .from(DbTables.profiles)
        .update({'osgb_id': osgbId})
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  /// Saha Personeli'nin UTTS açabileceği tek proje — RLS bu değerle
  /// `firma_id` eşleşmesini zorunlu kılar (bkz. `is_personel_kapsam_uygun`).
  Future<void> setVarsayilanProje(String userId, String? projeId) async {
    final rows = await _client
        .from(DbTables.profiles)
        .update({'varsayilan_proje_id': projeId})
        .eq('id', userId)
        .select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  Future<List<String>> fetchAtananProjeIdleri(String userId) async {
    final rows = await _client
        .from(DbTables.kullaniciProjeAtamalari)
        .select('proje_id')
        .eq('kullanici_id', userId);
    return (rows as List).map((e) => e['proje_id'] as String).toList();
  }

  Future<void> projeAta(String userId, String projeId) {
    return _client.from(DbTables.kullaniciProjeAtamalari).upsert({
      'kullanici_id': userId,
      'proje_id': projeId,
    }, onConflict: 'kullanici_id,proje_id');
  }

  Future<void> projeAtamasiKaldir(String userId, String projeId) {
    return _client
        .from(DbTables.kullaniciProjeAtamalari)
        .delete()
        .eq('kullanici_id', userId)
        .eq('proje_id', projeId);
  }
}
