import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/firma_model.dart';

class FirmaRepository {
  FirmaRepository(this._client);

  final SupabaseClient _client;

  Future<List<FirmaModel>> fetchAll() async {
    final rows = await _client.from(DbTables.firmalar).select().order('ad');
    return (rows as List).map((e) => FirmaModel.fromJson(e)).toList();
  }

  Stream<List<FirmaModel>> watchAll() {
    return _client
        .from(DbTables.firmalar)
        .stream(primaryKey: ['id'])
        .order('ad')
        .map((rows) => rows.map(FirmaModel.fromJson).toList());
  }

  Future<void> create(FirmaModel firma) {
    return _client.from(DbTables.firmalar).insert(firma.toInsertJson());
  }

  Future<void> update(String id, Map<String, dynamic> changes) {
    return _client.from(DbTables.firmalar).update(changes).eq('id', id);
  }
}
