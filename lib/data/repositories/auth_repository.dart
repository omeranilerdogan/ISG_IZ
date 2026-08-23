import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> sendPasswordResetEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}
