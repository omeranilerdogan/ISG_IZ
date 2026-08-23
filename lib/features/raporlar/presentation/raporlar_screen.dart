import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/tutanak_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/tutanak_providers.dart';
import '../../../shared/widgets/tehlike_sinifi_badge.dart';
import '../../../shared/widgets/tutanak_durum_badge.dart';

/// Faz 4 — Raporlama/İstatistik: `get_tutanaklar()` zaten role göre
/// (admin: tümü, isg_uzmani/santiye_şefi: atandığı projeler, personel:
/// kendi tutanakları) filtrelenmiş ve `ceza_tutari` alanı görünürlüğe göre
/// redakte edilmiş listeyi döndürdüğü için, buradaki toplamlar ek bir RLS
/// kontrolüne gerek kalmadan zaten doğru kapsamdadır.
class RaporlarScreen extends ConsumerWidget {
  const RaporlarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final listeAsync = ref.watch(tutanakListProvider(const TutanakFiltre()));

    return Scaffold(
      appBar: AppBar(title: const Text('Raporlama')),
      body: listeAsync.when(
        data: (liste) => _RaporIcerik(
          liste: liste,
          cezaGoster: profile?.rol == KullaniciRolu.admin,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _RaporIcerik extends StatelessWidget {
  const _RaporIcerik({required this.liste, required this.cezaGoster});

  final List<TutanakModel> liste;
  final bool cezaGoster;

  @override
  Widget build(BuildContext context) {
    if (liste.isEmpty) {
      return const Center(child: Text('Gösterilecek tutanak bulunmuyor.'));
    }

    final durumSayilari = <TutanakDurumu, int>{};
    final sinifSayilari = <TehlikeSinifi, int>{};
    final projeSayilari = <String, int>{};
    num cezaToplami = 0;

    for (final t in liste) {
      durumSayilari.update(t.durum, (v) => v + 1, ifAbsent: () => 1);
      sinifSayilari.update(t.tehlikeSinifi, (v) => v + 1, ifAbsent: () => 1);
      final projeAdi = t.projeAdi ?? '(Bilinmiyor)';
      projeSayilari.update(projeAdi, (v) => v + 1, ifAbsent: () => 1);
      if (t.cezaTutari != null) cezaToplami += t.cezaTutari!;
    }

    final durumGirdileri = TutanakDurumu.values
        .where((d) => (durumSayilari[d] ?? 0) > 0)
        .map((d) => _DagilimGirdisi(d.etiket, durumSayilari[d]!, TutanakDurumBadge.renk(d)))
        .toList();

    final sinifGirdileri = TehlikeSinifi.values
        .where((s) => (sinifSayilari[s] ?? 0) > 0)
        .map((s) => _DagilimGirdisi(
              '$s Sınıfı',
              sinifSayilari[s]!,
              TehlikeSinifiBadge.renk(s),
            ))
        .toList();

    final projeGirdileri = projeSayilari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final projeGirdileriTop = projeGirdileri
        .take(8)
        .map((e) => _DagilimGirdisi(e.key, e.value, AppTheme.primary))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatKarti(
              icon: Icons.fact_check_outlined,
              baslik: 'Toplam Tutanak',
              deger: '${liste.length}',
            ),
            if (cezaGoster) ...[
              const SizedBox(width: 12),
              _StatKarti(
                icon: Icons.payments_outlined,
                baslik: 'Toplam Ceza Tutarı',
                deger: '${cezaToplami.toStringAsFixed(0)} TL',
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _DagilimBolumu(baslik: 'Durum Dağılımı', girdiler: durumGirdileri),
        const SizedBox(height: 24),
        _DagilimBolumu(baslik: 'Tehlike Sınıfı Dağılımı', girdiler: sinifGirdileri),
        const SizedBox(height: 24),
        _DagilimBolumu(baslik: 'Projeye Göre Dağılım', girdiler: projeGirdileriTop),
      ],
    );
  }
}

class _StatKarti extends StatelessWidget {
  const _StatKarti({required this.icon, required this.baslik, required this.deger});

  final IconData icon;
  final String baslik;
  final String deger;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(height: 10),
              Text(
                deger,
                style: Theme.of(context).textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(baslik, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DagilimGirdisi {
  const _DagilimGirdisi(this.etiket, this.sayi, this.renk);

  final String etiket;
  final int sayi;
  final Color renk;
}

class _DagilimBolumu extends StatelessWidget {
  const _DagilimBolumu({required this.baslik, required this.girdiler});

  final String baslik;
  final List<_DagilimGirdisi> girdiler;

  @override
  Widget build(BuildContext context) {
    if (girdiler.isEmpty) return const SizedBox.shrink();

    final maxSayi = girdiler.map((g) => g.sayi).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(baslik, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final g in girdiler)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        g.etiket,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: g.sayi / maxSayi,
                          minHeight: 14,
                          backgroundColor: g.renk.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(g.renk),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${g.sayi}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
