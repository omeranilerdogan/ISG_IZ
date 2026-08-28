import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/proje_model.dart';

class ProjeRepository {
  ProjeRepository(this._client);

  final SupabaseClient _client;

  Future<List<ProjeModel>> fetchAll({bool sadeceAktif = false}) async {
    var query = _client.from(DbTables.projeler).select();
    if (sadeceAktif) {
      query = query.eq('aktif', true);
    }
    final rows = await query.order('ad');
    return (rows as List).map((e) => ProjeModel.fromJson(e)).toList();
  }

  Stream<List<ProjeModel>> watchAll() {
    return _client
        .from(DbTables.projeler)
        .stream(primaryKey: ['id'])
        .order('ad')
        .map((rows) => rows.map(ProjeModel.fromJson).toList());
  }

  Future<void> create(ProjeModel proje) {
    return _client.from(DbTables.projeler).insert(proje.toInsertJson());
  }

  /// `.select()` eklenmesinin nedeni: RLS politikası satırı reddettiğinde
  /// `.update()` tek başına hata fırlatmaz, sessizce 0 satır günceller —
  /// bkz. profile_repository.dart'taki aynı düzeltme.
  Future<void> update(String id, Map<String, dynamic> changes) async {
    final rows =
        await _client.from(DbTables.projeler).update(changes).eq('id', id).select();
    if (rows.isEmpty) {
      throw StateError('Güncelleme reddedildi: bu işlem için yetkiniz yok.');
    }
  }

  Future<void> delete(String id) {
    return _client.from(DbTables.projeler).delete().eq('id', id);
  }
}
