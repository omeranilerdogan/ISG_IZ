import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/osgb_model.dart';

class OsgbRepository {
  OsgbRepository(this._client);

  final SupabaseClient _client;

  Future<List<OsgbModel>> fetchAll() async {
    final rows = await _client.from(DbTables.osgblar).select().order('ad');
    return (rows as List).map((e) => OsgbModel.fromJson(e)).toList();
  }

  Stream<List<OsgbModel>> watchAll() {
    return _client
        .from(DbTables.osgblar)
        .stream(primaryKey: ['id'])
        .order('ad')
        .map((rows) => rows.map(OsgbModel.fromJson).toList());
  }

  Future<void> create(OsgbModel osgb) {
    return _client.from(DbTables.osgblar).insert(osgb.toInsertJson());
  }

  Future<void> update(String id, Map<String, dynamic> changes) {
    return _client.from(DbTables.osgblar).update(changes).eq('id', id);
  }

  Future<void> delete(String id) {
    return _client.from(DbTables.osgblar).delete().eq('id', id);
  }
}
