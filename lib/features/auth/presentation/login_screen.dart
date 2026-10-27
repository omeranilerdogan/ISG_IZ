import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _beniHatirla = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = _baglantiHatasi();
  }

  /// E-postadaki bağlantı geçersizse Supabase kullanıcıyı adrese hata
  /// parametreleri ekleyerek geri gönderir; bunu kullanıcıya açıklar.
  String? _baglantiHatasi() {
    if (!kIsWeb) return null;
    final params = Uri.base.queryParameters;
    final kod = params['error_code'];
    if (kod == null && params['error'] == null) return null;
    if (kod == 'otp_expired') {
      return 'E-postadaki bağlantının süresi dolmuş ya da daha önce kullanılmış. '
          'Lütfen "Şifremi Unuttum" ile yeni bir bağlantı isteyin ve yalnızca '
          'en son gelen e-postadaki bağlantıyı kullanın.';
    }
    return 'E-postadaki bağlantı doğrulanamadı. Lütfen yeni bir bağlantı isteyin.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Yönlendirme işlemi go_router redirect mantığı (app_router.dart) tarafından yapılır.
    } catch (e) {
      setState(() => _errorMessage = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sifremiUnuttum() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce e-posta adresinizi girin.')),
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama bağlantısı e-postanıza gönderildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/logo.png', width: 112, height: 112),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'İSG Uygunsuzluk Tespit Tutanağı',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null) ErrorBanner(message: _errorMessage!),
                  AppTextField(
                    label: 'E-posta',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'E-posta zorunludur.';
                      if (!v.contains('@')) return 'Geçerli bir e-posta girin.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Şifre',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre zorunludur.';
                      return null;
                    },
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _beniHatirla,
                        onChanged: (v) => setState(() => _beniHatirla = v ?? true),
                      ),
                      const Text('Beni Hatırla'),
                      const Spacer(),
                      TextButton(
                        onPressed: _sifremiUnuttum,
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Giriş Yap', onPressed: _submit, loading: _loading),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Hesabınız yok mu?'),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
