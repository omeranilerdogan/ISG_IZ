import 'package:supabase_flutter/supabase_flutter.dart';

String mapAuthError(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-posta adresiniz henüz doğrulanmamış.';
    }
    if (msg.contains('user already registered')) {
      return 'Bu e-posta adresi ile zaten bir hesap var.';
    }
    if (msg.contains('password should be at least')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    return error.message;
  }
  return 'Beklenmeyen bir hata oluştu: $error';
}
