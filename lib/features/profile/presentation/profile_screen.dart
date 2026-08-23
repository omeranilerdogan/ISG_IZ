import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/profile_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/role_badge.dart';

/// Bölüm 5.8 — Profil / Ayarlar: ad soyad, telefon, şifre değiştirme,
/// bildirim tercihleri, uygulama dili.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();
  bool _saving = false;
  String? _initializedForId;

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  Future<void> _kaydet(ProfileModel profile) async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateOwnProfile(
            profile.copyWith(
              adSoyad: _adSoyadController.text.trim(),
              telefon: _telefonController.text.trim(),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sifreDegistirDialogAc() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: 'Yeni Şifre',
            controller: controller,
            obscureText: true,
            validator: (v) => (v == null || v.length < 6) ? 'En az 6 karakter olmalı.' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref
                    .read(supabaseClientProvider)
                    .auth
                    .updateUser(UserAttributes(password: controller.text));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Şifre güncellendi.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                }
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_initializedForId != profile.id) {
      _adSoyadController.text = profile.adSoyad;
      _telefonController.text = profile.telefon ?? '';
      _initializedForId = profile.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil / Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Text(
                    profile.adSoyad.isNotEmpty ? profile.adSoyad[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 10),
                RoleBadge(rol: profile.rol),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(label: 'Ad Soyad', controller: _adSoyadController),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Telefon',
            controller: _telefonController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Kaydet',
            loading: _saving,
            onPressed: () => _kaydet(profile),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sifreDegistirDialogAc,
            icon: const Icon(Icons.lock_reset),
            label: const Text('Şifre Değiştir'),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            value: true,
            onChanged: null,
            title: const Text('Push Bildirimleri'),
            subtitle: const Text('Firebase Cloud Messaging entegrasyonu Faz 5\'te eklenecek.'),
          ),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Uygulama Dili'),
            trailing: Text('Türkçe'),
          ),
        ],
      ),
    );
  }
}
