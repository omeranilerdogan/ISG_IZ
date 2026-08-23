import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/bildirim_model.dart';
import '../../../providers/bildirim_providers.dart';
import '../../../providers/supabase_providers.dart';

/// Faz 3 — Bildirim Merkezi: oturum sahibine ait bildirimleri realtime listeler,
/// dokunulduğunda okundu işaretler ve varsa ilgili tutanağa yönlendirir.
class BildirimListeScreen extends ConsumerWidget {
  const BildirimListeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listeAsync = ref.watch(bildirimListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            tooltip: 'Tümünü okundu işaretle',
            icon: const Icon(Icons.done_all),
            onPressed: () {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) return;
              ref.read(bildirimRepositoryProvider).tumunuOkunduIsaretle(userId);
            },
          ),
        ],
      ),
      body: listeAsync.when(
        data: (liste) => liste.isEmpty
            ? const Center(child: Text('Bildirim bulunmuyor.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: liste.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _BildirimKarti(bildirim: liste[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _BildirimKarti extends ConsumerWidget {
  const _BildirimKarti({required this.bildirim});

  final BildirimModel bildirim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: bildirim.okundu ? null : Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: Icon(
          bildirim.okundu ? Icons.notifications_none : Icons.notifications_active,
        ),
        title: Text(bildirim.baslik),
        subtitle: Text([
          if (bildirim.icerik != null && bildirim.icerik!.isNotEmpty) bildirim.icerik!,
          DateFormat('dd.MM.yyyy HH:mm').format(bildirim.createdAt),
        ].join('\n')),
        isThreeLine: bildirim.icerik != null && bildirim.icerik!.isNotEmpty,
        onTap: () {
          if (!bildirim.okundu) {
            ref.read(bildirimRepositoryProvider).okunduIsaretle(bildirim.id);
          }
          if (bildirim.tutanakId != null) {
            context.push('/tutanak/${bildirim.tutanakId}');
          }
        },
      ),
    );
  }
}
