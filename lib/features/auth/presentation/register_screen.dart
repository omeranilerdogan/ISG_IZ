import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../data/models/firma_model.dart';
import '../../../data/models/proje_model.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/primary_button.dart';

final _kayitFirmalariProvider = FutureProvider.autoDispose<List<FirmaModel>>((ref) {
  return ref.watch(firmaRepositoryProvider).fetchAll();
});

final _kayitProjeleriProvider = FutureProvider.autoDispose<List<ProjeModel>>((ref) {
  return ref.watch(projeRepositoryProvider).fetchAll(sadeceAktif: true);
});

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordTekrarController = TextEditingController();

  String? _seciliFirmaId;
  String? _seciliProjeId;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _passwordController.dispose();
    _passwordTekrarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            adSoyad: _adSoyadController.text.trim(),
            telefon: _telefonController.text.trim(),
            firmaId: _seciliFirmaId,
            projeId: _seciliProjeId,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Kaydınız Alındı'),
          content: const Text(
            'Hesabınız oluşturuldu. İSG Yöneticisi onayından sonra giriş yapabileceksiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Yeni hesap aktif=false olduğundan router otomatik /pending-approval'a yönlendirir;
      // oturum açılmadıysa (e-posta doğrulama açıksa) girişe geri dön.
      context.go('/login');
    } catch (e) {
      setState(() => _errorMessage = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firmalarAsync = ref.watch(_kayitFirmalariProvider);
    final projelerAsync = ref.watch(_kayitProjeleriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Yeni Saha Personeli Kaydı',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kayıt sonrası hesabınız İSG Yöneticisi onayına düşer.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ErrorBanner(message: _errorMessage!),
                  AppTextField(
                    label: 'Ad Soyad',
                    controller: _adSoyadController,
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Ad soyad zorunludur.' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'E-posta',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'E-posta zorunludur.';
                      if (!v.contains('@')) return 'Geçerli bir e-posta girin.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Telefon',
                    controller: _telefonController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),
                  firmalarAsync.when(
                    data: (firmalar) => DropdownButtonFormField<String>(
                      initialValue: _seciliFirmaId,
                      decoration: const InputDecoration(labelText: 'Bağlı olduğu Firma'),
                      items: firmalar
                          .map((f) => DropdownMenuItem(value: f.id, child: Text(f.ad)))
                          .toList(),
                      onChanged: (v) => setState(() => _seciliFirmaId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Firmalar yüklenemedi: $e'),
                  ),
                  const SizedBox(height: 16),
                  projelerAsync.when(
                    data: (projeler) => DropdownButtonFormField<String>(
                      initialValue: _seciliProjeId,
                      decoration: const InputDecoration(labelText: 'Proje'),
                      items: projeler
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad)))
                          .toList(),
                      onChanged: (v) => setState(() => _seciliProjeId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Projeler yüklenemedi: $e'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Şifre',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Şifre zorunludur.';
                      if (v.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Şifre Tekrar',
                    controller: _passwordTekrarController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Şifreler eşleşmiyor.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Kayıt Ol', onPressed: _submit, loading: _loading),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaten hesabınız var mı?'),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Giriş Yap'),
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
