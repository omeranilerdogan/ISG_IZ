import 'package:file_saver/file_saver.dart' show MimeType;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/export/disa_aktarilan_dosya_servisi.dart';
import '../../../core/export/tutanak_excel_olusturucu.dart';
import '../../../data/models/tutanak_model.dart';
import '../../../providers/taslak_kuyruk_providers.dart';
import '../../../providers/tutanak_providers.dart';
import '../../../shared/widgets/tehlike_sinifi_badge.dart';
import '../../../shared/widgets/tutanak_durum_badge.dart';

/// Bölüm 5.5 — Tutanak Listesi: role göre filtrelenmiş tutanakları durum,
/// tarihe göre filtreleme imkânıyla gösterir (görünürlük get_tutanaklar() /
/// RLS tarafından sağlanır).
class TutanakListeScreen extends ConsumerStatefulWidget {
  const TutanakListeScreen({super.key});

  @override
  ConsumerState<TutanakListeScreen> createState() => _TutanakListeScreenState();
}

class _TutanakListeScreenState extends ConsumerState<TutanakListeScreen> {
  TutanakDurumu? _durumFiltre;
  bool _disaAktariliyor = false;

  Future<void> _excelDisaAktar(List<TutanakModel> liste) async {
    if (liste.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarılacak tutanak bulunmuyor.')),
      );
      return;
    }
    setState(() => _disaAktariliyor = true);
    try {
      final bytes = tutanakListesiExcelOlustur(liste);
      final yol = await disaAktarilanDosyayiKaydetVeAc(
        ref: ref,
        ad: 'tutanaklar_${DateTime.now().millisecondsSinceEpoch}',
        bytes: bytes,
        uzanti: 'xlsx',
        tur: 'excel',
        mimeType: MimeType.microsoftExcel,
      );
      if (!mounted) return;
      if (kIsWeb || yol == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel dosyası indirildi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel oluşturulamadı: $e')));
    } finally {
      if (mounted) setState(() => _disaAktariliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(
      tutanakListProvider(TutanakFiltre(durum: _durumFiltre)),
    );
    final bekleyenTaslakSayisi = ref.watch(bekleyenTaslakSayisiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutanaklar'),
        actions: [
          IconButton(
            tooltip: 'Excel\'e aktar',
            icon: _disaAktariliyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.table_view_outlined),
            onPressed: _disaAktariliyor
                ? null
                : () => _excelDisaAktar(listAsync.valueOrNull ?? const []),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tutanak/yeni'),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Tutanak'),
      ),
      body: Column(
        children: [
          if (bekleyenTaslakSayisi > 0)
            Material(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.cloud_off_outlined,
                  color: Colors.orange,
                ),
                title: Text('$bekleyenTaslakSayisi taslak gönderim bekliyor'),
                subtitle: const Text(
                  'Bağlantı yokken kaydedilen tutanaklar burada.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tutanak/kuyruk'),
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _DurumChip(
                  label: 'Tümü',
                  selected: _durumFiltre == null,
                  onTap: () => setState(() => _durumFiltre = null),
                ),
                for (final d in TutanakDurumu.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _DurumChip(
                      label: d.etiket,
                      selected: _durumFiltre == d,
                      onTap: () => setState(() => _durumFiltre = d),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: listAsync.when(
              data: (liste) => liste.isEmpty
                  ? const Center(child: Text('Kayıtlı tutanak bulunamadı.'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(
                        tutanakListProvider(TutanakFiltre(durum: _durumFiltre)),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: liste.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _TutanakKarti(tutanak: liste[index]),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Bir hata oluştu: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurumChip extends StatelessWidget {
  const _DurumChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _TutanakKarti extends StatelessWidget {
  const _TutanakKarti({required this.tutanak});

  final TutanakModel tutanak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () {
          if (tutanak.durum == TutanakDurumu.taslak) {
            context.push('/tutanak/duzenle/${tutanak.id}');
          } else {
            context.push('/tutanak/${tutanak.id}');
          }
        },
        leading: TehlikeSinifiBadge(sinif: tutanak.tehlikeSinifi),
        title: Text(tutanak.uttNo ?? '(Taslak)'),
        subtitle: Text(
          [
            if (tutanak.projeAdi != null) tutanak.projeAdi!,
            DateFormat('dd.MM.yyyy').format(tutanak.tespitTarihi),
            if (tutanak.raporlayanAdi != null) tutanak.raporlayanAdi!,
          ].join(' · '),
        ),
        trailing: TutanakDurumBadge(durum: tutanak.durum),
      ),
    );
  }
}
