import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

class PushTokenRepository {
  PushTokenRepository(this._client);

  final SupabaseClient _client;

  /// `claim_push_token` RPC'si aynı cihaz (token) başka bir kullanıcıya
  /// bağlıysa o kaydı silip mevcut kullanıcıya devreder — paylaşılan
  /// cihaz senaryosunda eski kullanıcının bildirim almaya devam etmesini
  /// engeller (bkz. 20260823000009_push_token_rpc.sql).
  Future<void> tokenTalepEt(String token, String platformDbValue) {
    return _client.rpc(
      DbFunctions.claimPushToken,
      params: {'p_token': token, 'p_platform': platformDbValue},
    );
  }

  Future<void> tokenSil(String token) {
    return _client.from(DbTables.pushTokens).delete().eq('token', token);
  }
}
