import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/bildirim_model.dart';

class BildirimRepository {
  BildirimRepository(this._client);

  final SupabaseClient _client;

  /// Oturum sahibine ait bildirimleri realtime izler (Faz 3 — bildirim merkezi).
  Stream<List<BildirimModel>> watchAll(String aliciId) {
    return _client
        .from(DbTables.bildirimler)
        .stream(primaryKey: ['id'])
        .eq('alici_id', aliciId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(BildirimModel.fromJson).toList());
  }

  Future<void> okunduIsaretle(String id) async {
    final rows = await _client
        .from(DbTables.bildirimler)
        .update({'okundu': true})
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      throw StateError('Bildirim güncellenemedi: yetkiniz yok veya kayıt bulunamadı.');
    }
  }

  Future<void> tumunuOkunduIsaretle(String aliciId) {
    return _client
        .from(DbTables.bildirimler)
        .update({'okundu': true})
        .eq('alici_id', aliciId)
        .eq('okundu', false);
  }
}
