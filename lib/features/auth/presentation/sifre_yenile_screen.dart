import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/primary_button.dart';

/// Şifre sıfırlama e-postasındaki bağlantıdan gelen kullanıcının yeni
/// şifresini belirlediği ekran.
class SifreYenileScreen extends ConsumerStatefulWidget {
  const SifreYenileScreen({super.key});

  @override
  ConsumerState<SifreYenileScreen> createState() => _SifreYenileScreenState();
}

class _SifreYenileScreenState extends ConsumerState<SifreYenileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sifreController = TextEditingController();
  final _sifreTekrarController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _sifreController.dispose();
    _sifreTekrarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_sifreController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifreniz güncellendi.')),
      );
      ref.read(sifreYenilemeModuProvider.notifier).tamamlandi();
      context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _giriseDon() {
    ref.read(sifreYenilemeModuProvider.notifier).tamamlandi();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final oturumVar = ref.watch(currentUserIdProvider) != null;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: oturumVar ? _form(context) : _gecersizBaglanti(context),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset, size: 56, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            'Yeni Şifre Belirle',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ErrorBanner(message: _errorMessage!),
          AppTextField(
            label: 'Yeni Şifre',
            controller: _sifreController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter olmalı.' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Yeni Şifre (Tekrar)',
            controller: _sifreTekrarController,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            validator: (v) => v != _sifreController.text ? 'Şifreler eşleşmiyor.' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Şifreyi Güncelle', onPressed: _submit, loading: _loading),
        ],
      ),
    );
  }

  /// Bağlantının kodu oturuma çevrilemediyse (süresi dolmuş ya da daha önce
  /// kullanılmış) kullanıcıya bunu açıklar.
  Widget _gecersizBaglanti(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.link_off, size: 56, color: AppTheme.accent),
        const SizedBox(height: 16),
        Text(
          'Bağlantı Doğrulanamadı',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Şifre sıfırlama bağlantısının süresi dolmuş ya da daha önce kullanılmış '
          'olabilir. Giriş ekranından "Şifremi Unuttum" ile yeni bir bağlantı isteyin '
          've e-postadaki en son bağlantıyı kullanın.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _giriseDon,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Giriş Ekranına Dön'),
        ),
      ],
    );
  }
}
