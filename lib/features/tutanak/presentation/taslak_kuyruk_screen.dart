import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/offline/taslak_senkronizasyon_servisi.dart';
import '../../../data/models/taslak_kuyruk_ogesi.dart';
import '../../../providers/taslak_kuyruk_providers.dart';
import '../../../shared/widgets/tehlike_sinifi_badge.dart';

/// Faz 5 — bağlantı yokken oluşturulup cihazda bekleyen tutanak
/// taslaklarının listesi; bağlantı gelince otomatik gönderilir, burada
/// manuel olarak da tekrar denenebilir veya kuyruktan silinebilir.
class TaslakKuyrukScreen extends ConsumerWidget {
  const TaslakKuyrukScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listeAsync = ref.watch(taslakKuyrukListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderim Bekleyen Taslaklar'),
        actions: [
          IconButton(
            tooltip: 'Şimdi gönder',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await ref.read(taslakSenkronizasyonServisiProvider).senkronizeEt();
              ref.invalidate(taslakKuyrukListProvider);
            },
          ),
        ],
      ),
      body: listeAsync.when(
        data: (liste) => liste.isEmpty
            ? const Center(child: Text('Bekleyen taslak yok.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: liste.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _TaslakKarti(oge: liste[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _TaslakKarti extends ConsumerWidget {
  const _TaslakKarti({required this.oge});

  final TaslakKuyrukOgesi oge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TehlikeSinifiBadge(sinif: oge.tehlikeSinifi),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    oge.projeAdi,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Kuyruktan sil',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(taslakKuyrukDeposuProvider).sil(oge.id);
                    ref.invalidate(taslakKuyrukListProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${oge.firmaAdi} · ${DateFormat('dd.MM.yyyy HH:mm').format(oge.olusturmaZamani)}'),
            const SizedBox(height: 8),
            Text(oge.aciklama, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.photo_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${oge.fotografYollari.length} fotoğraf'),
              ],
            ),
            if (oge.sonHata != null) ...[
              const SizedBox(height: 8),
              Text(
                oge.sonHata!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
