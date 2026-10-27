import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Supabase Auth üzerinden oturum açma/kayıt/çıkış işlemleri (Bölüm 5.1, 5.2).
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Yeni saha personeli kaydı. Varsayılan rol/aktif durumu veritabanındaki
  /// `handle_new_user()` trigger'ı tarafından atanır (rol=personel, aktif=false).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String adSoyad,
    String? telefon,
    String? firmaId,
    String? projeId,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'ad_soyad': adSoyad,
        if (telefon != null && telefon.isNotEmpty) 'telefon': telefon,
        'firma_id': ?firmaId,
        'proje_id': ?projeId,
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Bağlantı, Supabase panelindeki Site URL yerine açıkça verilen adrese
  /// döner; bu adresin panelde "Redirect URLs" listesinde olması gerekir.
  Future<void> sendPasswordResetEmail(String email) {
    final kok = kIsWeb ? Uri.base.origin : AppUrls.web;
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '$kok/?${AppUrls.sifreYenilemeParametresi}=1',
    );
  }

  /// Şifre sıfırlama e-postasındaki `token_hash` değerini oturuma çevirir.
  /// PKCE kod değişiminin aksine isteğin yapıldığı cihazdan bağımsız çalışır.
  Future<void> verifyRecoveryToken(String tokenHash) {
    return _client.auth.verifyOTP(type: OtpType.recovery, tokenHash: tokenHash);
  }

  Future<void> updatePassword(String yeniSifre) {
    return _client.auth.updateUser(UserAttributes(password: yeniSifre));
  }
}
