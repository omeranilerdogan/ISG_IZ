import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env` dosyasından Supabase bağlantı bilgilerini okur.
/// Kurulum için proje köküne `.env.example` dosyasını `.env` olarak kopyalayıp
/// kendi Supabase proje bilgilerinizi girin.
class Env {
  Env._();

  static String get supabaseUrl => dotenv.get('SUPABASE_URL');

  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      dotenv.isInitialized &&
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_PROJECT_REF') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR_ANON_KEY';
}
