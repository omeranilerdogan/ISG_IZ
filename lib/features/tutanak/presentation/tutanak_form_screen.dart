import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/offline/yerel_depo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/firma_model.dart';
import '../../../data/models/proje_model.dart';
import '../../../data/models/taslak_kuyruk_ogesi.dart';
import '../../../data/models/tutanak_fotograf_model.dart';
import '../../../providers/profile_providers.dart';
import '../../../providers/supabase_providers.dart';
import '../../../providers/taslak_kuyruk_providers.dart';
import '../../../providers/tutanak_providers.dart';
import '../../../shared/widgets/error_banner.dart';

class _YeniFoto {
  _YeniFoto(this.bytes);
  final Uint8List bytes;
}

String _projeAdiBul(List<ProjeModel> liste, String id) {
  for (final p in liste) {
    if (p.id == id) return p.ad;
  }
  return id;
}

String _firmaAdiBul(List<FirmaModel> liste, String id) {
  for (final f in liste) {
    if (f.id == id) return f.ad;
  }
  return id;
}

/// Firma listesini seçili projeye göre filtreler: bir projeye bağlanmış
/// (proje_id dolu) firmalar yalnızca o projede görünür; proje_id boş olan
/// firmalar (tüm inşaatlarda ortak kullanılan) her projede listelenir.
/// [mevcutSeciliFirmaId] verilirse (düzenleme modunda), o firma proje
/// eşleşmese bile listeden düşmez — aksi halde dropdown geçersiz bir
/// değere sahip olur.
List<FirmaModel> firmalarProjeyeGoreFiltrele(
  List<FirmaModel> firmalar,
  String? projeId, {
  String? mevcutSeciliFirmaId,
}) {
  if (projeId == null) return firmalar;
  return firmalar
      .where(
        (f) =>
            f.projeId == null ||
            f.projeId == projeId ||
            f.id == mevcutSeciliFirmaId,
      )
      .toList();
}

const _projelerOnbellekAnahtari = 'projeler_onbellek';
const _firmalarOnbellekAnahtari = 'firmalar_onbellek';

/// Bağlantı yokken proje/firma listesini son başarılı çekimden gelen
/// önbellekle döner; aksi halde canlı veriyi çekip önbelleği tazeler
/// (Faz 5 — offline taslak formu bu listeler olmadan kullanılamaz).
final _formProjelerProvider = FutureProvider.autoDispose<List<ProjeModel>>((
  ref,
) async {
  final List<ProjeModel> liste;
  try {
    liste = await ref
        .watch(projeRepositoryProvider)
        .fetchAll(sadeceAktif: true);
  } catch (e) {
    final onbellek = await YerelDepo.oku(_projelerOnbellekAnahtari);
    if (onbellek == null) rethrow;
    return (onbellek as List)
        .map((j) => ProjeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
  // Önbelleğe yazma (örn. path_provider hatası) başarısız olsa bile ağdan
  // gelen geçerli veriyi geçersiz kılmamalı — bu yüzden ayrı bir try/catch.
  try {
    await YerelDepo.yaz(
      _projelerOnbellekAnahtari,
      liste
          .map(
            (p) => {
              'id': p.id,
              'ad': p.ad,
              'yuklenici_adi': p.yukleniciAdi,
              'adres': p.adres,
              'aktif': p.aktif,
            },
          )
          .toList(),
    );
  } catch (_) {}
  return liste;
});

final _formFirmalarProvider = FutureProvider.autoDispose<List<FirmaModel>>((
  ref,
) async {
  final List<FirmaModel> liste;
  try {
    liste = await ref.watch(firmaRepositoryProvider).fetchAll();
  } catch (e) {
    final onbellek = await YerelDepo.oku(_firmalarOnbellekAnahtari);
    if (onbellek == null) rethrow;
    return (onbellek as List)
        .map((j) => FirmaModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
  try {
    await YerelDepo.yaz(
      _firmalarOnbellekAnahtari,
      liste
          .map((f) => {'id': f.id, 'ad': f.ad, 'proje_id': f.projeId})
          .toList(),
    );
  } catch (_) {}
  return liste;
});

/// Bölüm 5.4 — Tutanak Oluşturma Formu (1. Genel Bilgiler, 2. Uygunsuzluk Tarifi
/// ve Fotoğraflar, 3. Tavsiye/Termin, 4. Özet ve Gönder). `tutanakId` verilirse
/// mevcut bir taslak/revizyon_istendi kaydı düzenlenir.
class TutanakFormScreen extends ConsumerStatefulWidget {
  const TutanakFormScreen({super.key, this.tutanakId});

  final String? tutanakId;

  @override
  ConsumerState<TutanakFormScreen> createState() => _TutanakFormScreenState();
}

class _TutanakFormScreenState extends ConsumerState<TutanakFormScreen> {
  int _adim = 0;
  bool _ilkYuklemeYapiliyor = true;
  bool _kaydediliyor = false;
  bool _gonderiliyor = false;
  String? _hataMesaji;

  String? _tutanakId;
  String? _seciliProjeId;
  String? _seciliFirmaId;
  DateTime _tespitTarihi = DateTime.now();
  TehlikeSinifi? _tehlikeSinifi;
  final _aciklamaController = TextEditingController();
  final _tavsiyeController = TextEditingController();
  String? _terminTarihi;

  final List<TutanakFotografModel> _mevcutFotograflar = [];
  final Map<String, String> _mevcutFotografUrl = {};
  final Set<String> _silinecekFotografIdleri = {};
  final List<_YeniFoto> _yeniFotograflar = [];

  bool get _duzenlemeModu => widget.tutanakId != null;

  @override
  void initState() {
    super.initState();
    if (_duzenlemeModu) {
      _tutanakId = widget.tutanakId;
      _mevcutVeriyiYukle(widget.tutanakId!);
    } else {
      _ilkYuklemeYapiliyor = false;
    }
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _tavsiyeController.dispose();
    super.dispose();
  }

  Future<void> _mevcutVeriyiYukle(String id) async {
    final repo = ref.read(tutanakRepositoryProvider);
    final tutanak = await repo.fetchById(id);
    final fotograflar = await repo.fetchFotograflar(id);
    if (tutanak == null) {
      if (mounted) setState(() => _ilkYuklemeYapiliyor = false);
      return;
    }
    for (final f in fotograflar) {
      _mevcutFotografUrl[f.id] = await repo.getSignedUrl(f.storagePath);
    }
    if (!mounted) return;
    setState(() {
      _seciliProjeId = tutanak.projeId;
      _seciliFirmaId = tutanak.firmaId;
      _tespitTarihi = tutanak.tespitTarihi;
      _tehlikeSinifi = tutanak.tehlikeSinifi;
      _aciklamaController.text = tutanak.aciklama;
      _tavsiyeController.text = tutanak.tavsiyeOneri ?? '';
      _terminTarihi = tutanak.terminTarihi;
      _mevcutFotograflar.addAll(fotograflar);
      _ilkYuklemeYapiliyor = false;
    });
  }

  int get _toplamFotografSayisi =>
      _mevcutFotograflar
          .where((f) => !_silinecekFotografIdleri.contains(f.id))
          .length +
      _yeniFotograflar.length;

  Future<void> _fotografEkleGaleri() async {
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 90);
      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() => _yeniFotograflar.add(_YeniFoto(bytes)));
      }
    } catch (e) {
      _hataGoster('Fotoğraf seçilemedi: $e');
    }
  }

  Future<void> _fotografEkleKamera() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _yeniFotograflar.add(_YeniFoto(bytes)));
    } catch (e) {
      _hataGoster('Kameradan fotoğraf alınamadı: $e');
    }
  }

  void _hataGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  bool _genelBilgilerGecerli() =>
      _seciliProjeId != null && _seciliFirmaId != null;

  bool _tarifGecerli() =>
      _tehlikeSinifi != null && _aciklamaController.text.trim().isNotEmpty;

  Future<void> _kaydet({required bool gonder}) async {
    setState(() => _hataMesaji = null);

    if (!_genelBilgilerGecerli() || !_tarifGecerli()) {
      setState(() {
        _hataMesaji =
            'Proje, firma, tehlike sınıfı ve uygunsuzluk tarifi zorunludur.';
        _adim = !_genelBilgilerGecerli() ? 0 : 1;
      });
      return;
    }
    if (gonder && (_terminTarihi == null || _terminTarihi!.trim().isEmpty)) {
      setState(() {
        _hataMesaji = 'Göndermek için termin tarihi/bilgisi zorunludur.';
        _adim = 2;
      });
      return;
    }
    if (gonder && _toplamFotografSayisi < 1) {
      setState(() {
        _hataMesaji = 'Göndermek için en az 1 fotoğraf eklenmelidir.';
        _adim = 1;
      });
      return;
    }

    setState(() {
      if (gonder) {
        _gonderiliyor = true;
      } else {
        _kaydediliyor = true;
      }
    });

    try {
      final durum = gonder ? TutanakDurumu.gonderildi : TutanakDurumu.taslak;

      // Yeni kayıt (düzenleme değil) oluştururken bağlantı yoksa, sunucuya
      // hiç gitmeden doğrudan yerel kuyruğa ekle — bağlantı gelince
      // TaslakSenkronizasyonServisi otomatik gönderir (Faz 5).
      if (_tutanakId == null) {
        final baglanti = await Connectivity().checkConnectivity();
        if (baglanti.contains(ConnectivityResult.none)) {
          await _kuyrugaEkle(durum: durum);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bağlantı yok — tutanak kuyruğa eklendi, bağlantı gelince otomatik gönderilecek.',
              ),
            ),
          );
          context.pop();
          return;
        }
      }

      final repo = ref.read(tutanakRepositoryProvider);

      if (_tutanakId == null) {
        _tutanakId = await repo.createTutanak(
          projeId: _seciliProjeId!,
          firmaId: _seciliFirmaId!,
          tespitTarihi: _tespitTarihi,
          tehlikeSinifi: _tehlikeSinifi!,
          aciklama: _aciklamaController.text.trim(),
          tavsiyeOneri: _tavsiyeController.text.trim(),
          terminTarihi: _terminTarihi,
          durum: durum,
        );
      } else {
        await repo.updateTutanak(
          _tutanakId!,
          projeId: _seciliProjeId!,
          firmaId: _seciliFirmaId!,
          tespitTarihi: _tespitTarihi,
          tehlikeSinifi: _tehlikeSinifi!,
          aciklama: _aciklamaController.text.trim(),
          tavsiyeOneri: _tavsiyeController.text.trim(),
          terminTarihi: _terminTarihi,
          durum: durum,
        );
      }

      for (final id in _silinecekFotografIdleri) {
        final foto = _mevcutFotograflar.firstWhere((f) => f.id == id);
        await repo.deleteFotograf(foto);
      }

      var siraNo = _mevcutFotograflar
          .where((f) => !_silinecekFotografIdleri.contains(f.id))
          .length;
      for (final yeni in _yeniFotograflar) {
        final sikistirilmis = await FlutterImageCompress.compressWithList(
          yeni.bytes,
          minWidth: 1600,
          minHeight: 1600,
          quality: 75,
        );
        await repo.uploadFotograf(
          projeId: _seciliProjeId!,
          tutanakId: _tutanakId!,
          siraNo: siraNo++,
          bytes: sikistirilmis,
        );
      }

      ref.invalidate(tutanakListProvider);
      if (_tutanakId != null) {
        ref.invalidate(tutanakDetayProvider(_tutanakId!));
        ref.invalidate(tutanakFotograflarProvider(_tutanakId!));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gonder ? 'Tutanak gönderildi.' : 'Taslak kaydedildi.'),
        ),
      );
      context.pop();
    } catch (e) {
      setState(() => _hataMesaji = 'Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _kaydediliyor = _gonderiliyor = false);
    }
  }

  Future<void> _kuyrugaEkle({required TutanakDurumu durum}) async {
    final projeler =
        ref.read(_formProjelerProvider).valueOrNull ?? const <ProjeModel>[];
    final firmalar =
        ref.read(_formFirmalarProvider).valueOrNull ?? const <FirmaModel>[];

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final sikistirilmisFotograflar = <List<int>>[];
    for (final yeni in _yeniFotograflar) {
      sikistirilmisFotograflar.add(
        await FlutterImageCompress.compressWithList(
          yeni.bytes,
          minWidth: 1600,
          minHeight: 1600,
          quality: 75,
        ),
      );
    }

    final depo = ref.read(taslakKuyrukDeposuProvider);
    final fotografYollari = await depo.fotograflariKaydet(
      id,
      sikistirilmisFotograflar,
    );

    final tavsiye = _tavsiyeController.text.trim();

    await depo.ekle(
      TaslakKuyrukOgesi(
        id: id,
        projeId: _seciliProjeId!,
        projeAdi: _projeAdiBul(projeler, _seciliProjeId!),
        firmaId: _seciliFirmaId!,
        firmaAdi: _firmaAdiBul(firmalar, _seciliFirmaId!),
        tespitTarihi: _tespitTarihi,
        tehlikeSinifi: _tehlikeSinifi!,
        aciklama: _aciklamaController.text.trim(),
        tavsiyeOneri: tavsiye.isEmpty ? null : tavsiye,
        terminTarihi: _terminTarihi,
        durum: durum,
        fotografYollari: fotografYollari,
        olusturmaZamani: DateTime.now(),
      ),
    );
    ref.invalidate(taslakKuyrukListProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_ilkYuklemeYapiliyor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profil = ref.watch(currentProfileProvider).valueOrNull;
    // Saha Personeli yalnızca kendi firma+projesine UTTS açabilir (RLS bunu
    // zorunlu kılar) — yeni kayıtta bu alanlar profilden sabitlenip kilitlenir.
    final kilitli = !_duzenlemeModu && profil?.rol == KullaniciRolu.personel;
    if (kilitli) {
      _seciliProjeId ??= profil?.varsayilanProjeId;
      _seciliFirmaId ??= profil?.firmaId;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu ? 'Tutanağı Düzenle' : 'Yeni Tutanak'),
      ),
      body: Stepper(
        currentStep: _adim,
        onStepTapped: (i) => setState(() => _adim = i),
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text('Genel Bilgiler'),
            isActive: _adim == 0,
            state: _genelBilgilerGecerli()
                ? StepState.complete
                : StepState.indexed,
            content: _GenelBilgilerAdimi(
              seciliProjeId: _seciliProjeId,
              seciliFirmaId: _seciliFirmaId,
              tespitTarihi: _tespitTarihi,
              kilitli: kilitli,
              onProjeChanged: (v) => setState(() => _seciliProjeId = v),
              onFirmaChanged: (v) => setState(() => _seciliFirmaId = v),
              onTarihChanged: (v) => setState(() => _tespitTarihi = v),
            ),
          ),
          Step(
            title: const Text('Uygunsuzluk Tarifi ve Fotoğraflar'),
            isActive: _adim == 1,
            state: _tarifGecerli() ? StepState.complete : StepState.indexed,
            content: _TarifVeFotograflarAdimi(
              tehlikeSinifi: _tehlikeSinifi,
              aciklamaController: _aciklamaController,
              mevcutFotograflar: _mevcutFotograflar,
              mevcutFotografUrl: _mevcutFotografUrl,
              silinecekFotografIdleri: _silinecekFotografIdleri,
              yeniFotograflar: _yeniFotograflar,
              onTehlikeChanged: (v) => setState(() => _tehlikeSinifi = v),
              onAciklamaChanged: () => setState(() {}),
              onFotografSilExisting: (id) =>
                  setState(() => _silinecekFotografIdleri.add(id)),
              onFotografGeriAlExisting: (id) =>
                  setState(() => _silinecekFotografIdleri.remove(id)),
              onFotografSilYeni: (foto) =>
                  setState(() => _yeniFotograflar.remove(foto)),
              onGaleriSec: _fotografEkleGaleri,
              onKameraSec: _fotografEkleKamera,
            ),
          ),
          Step(
            title: const Text('Tavsiye / Termin'),
            isActive: _adim == 2,
            state: StepState.indexed,
            content: _TavsiyeTerminAdimi(
              tavsiyeController: _tavsiyeController,
              terminTarihi: _terminTarihi,
              onTerminChanged: (v) => setState(() => _terminTarihi = v),
            ),
          ),
          Step(
            title: const Text('Özet ve Gönder'),
            isActive: _adim == 3,
            state: StepState.indexed,
            content: _OzetAdimi(
              seciliProjeId: _seciliProjeId,
              seciliFirmaId: _seciliFirmaId,
              tespitTarihi: _tespitTarihi,
              tehlikeSinifi: _tehlikeSinifi,
              aciklama: _aciklamaController.text,
              tavsiyeOneri: _tavsiyeController.text,
              terminTarihi: _terminTarihi,
              fotografSayisi: _toplamFotografSayisi,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hataMesaji != null) ErrorBanner(message: _hataMesaji!),
              Row(
                children: [
                  if (_adim > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _adim -= 1),
                        child: const Text('Geri'),
                      ),
                    ),
                  if (_adim > 0) const SizedBox(width: 12),
                  if (_adim < 3)
                    Expanded(
                      child: FilledButton(
                        onPressed: () => setState(() => _adim += 1),
                        child: const Text('İleri'),
                      ),
                    ),
                ],
              ),
              if (_adim == 3) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _kaydediliyor || _gonderiliyor
                            ? null
                            : () => _kaydet(gonder: false),
                        child: _kaydediliyor
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Taslak Kaydet'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _kaydediliyor || _gonderiliyor
                            ? null
                            : () => _kaydet(gonder: true),
                        child: _gonderiliyor
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Gönder'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GenelBilgilerAdimi extends ConsumerWidget {
  const _GenelBilgilerAdimi({
    required this.seciliProjeId,
    required this.seciliFirmaId,
    required this.tespitTarihi,
    this.kilitli = false,
    required this.onProjeChanged,
    required this.onFirmaChanged,
    required this.onTarihChanged,
  });

  final String? seciliProjeId;
  final String? seciliFirmaId;
  final DateTime tespitTarihi;
  final bool kilitli;
  final ValueChanged<String?> onProjeChanged;
  final ValueChanged<String?> onFirmaChanged;
  final ValueChanged<DateTime> onTarihChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projelerAsync = ref.watch(_formProjelerProvider);
    final firmalarAsync = ref.watch(_formFirmalarProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        projelerAsync.when(
          data: (projeler) => DropdownButtonFormField<String>(
            initialValue: seciliProjeId,
            decoration: const InputDecoration(labelText: 'Proje Adı'),
            isExpanded: true,
            menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
            items: projeler
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.ad)))
                .toList(),
            onChanged: kilitli
                ? null
                : (v) {
                    // Proje değişince, o projeye ait olmayan firma seçimi
                    // geçersiz kalır (bkz. firmalarProjeyeGoreFiltrele) —
                    // seçim sıfırlanmazsa dropdown geçersiz bir değerde kalır.
                    onProjeChanged(v);
                    onFirmaChanged(null);
                  },
          ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Projeler yüklenemedi: $e'),
        ),
        const SizedBox(height: 16),
        firmalarAsync.when(
          data: (firmalar) {
            final firmalarFiltreli = firmalarProjeyeGoreFiltrele(
              firmalar,
              seciliProjeId,
              mevcutSeciliFirmaId: seciliFirmaId,
            );
            return DropdownButtonFormField<String>(
              initialValue: seciliFirmaId,
              decoration: const InputDecoration(labelText: 'İlgili Firma'),
              isExpanded: true,
              menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
              items: firmalarFiltreli
                  .map((f) => DropdownMenuItem(value: f.id, child: Text(f.ad)))
                  .toList(),
              onChanged: kilitli ? null : onFirmaChanged,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Firmalar yüklenemedi: $e'),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final secilen = await showDatePicker(
              context: context,
              initialDate: tespitTarihi,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (secilen != null) onTarihChanged(secilen);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Tarih',
              suffixIcon: Icon(Icons.event),
            ),
            child: Text(DateFormat('dd.MM.yyyy').format(tespitTarihi)),
          ),
        ),
      ],
    );
  }
}

class _TarifVeFotograflarAdimi extends StatelessWidget {
  const _TarifVeFotograflarAdimi({
    required this.tehlikeSinifi,
    required this.aciklamaController,
    required this.mevcutFotograflar,
    required this.mevcutFotografUrl,
    required this.silinecekFotografIdleri,
    required this.yeniFotograflar,
    required this.onTehlikeChanged,
    required this.onAciklamaChanged,
    required this.onFotografSilExisting,
    required this.onFotografGeriAlExisting,
    required this.onFotografSilYeni,
    required this.onGaleriSec,
    required this.onKameraSec,
  });

  final TehlikeSinifi? tehlikeSinifi;
  final TextEditingController aciklamaController;
  final List<TutanakFotografModel> mevcutFotograflar;
  final Map<String, String> mevcutFotografUrl;
  final Set<String> silinecekFotografIdleri;
  final List<_YeniFoto> yeniFotograflar;
  final ValueChanged<TehlikeSinifi> onTehlikeChanged;
  final VoidCallback onAciklamaChanged;
  final ValueChanged<String> onFotografSilExisting;
  final ValueChanged<String> onFotografGeriAlExisting;
  final ValueChanged<_YeniFoto> onFotografSilYeni;
  final VoidCallback onGaleriSec;
  final VoidCallback onKameraSec;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tehlike Sınıfı',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TehlikeSinifi>(
          segments: const [
            ButtonSegment(value: TehlikeSinifi.A, label: Text('A')),
            ButtonSegment(value: TehlikeSinifi.B, label: Text('B')),
            ButtonSegment(value: TehlikeSinifi.C, label: Text('C')),
          ],
          selected: {?tehlikeSinifi},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onTehlikeChanged(s.first);
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: aciklamaController,
          maxLines: 5,
          onChanged: (_) => onAciklamaChanged(),
          decoration: const InputDecoration(
            labelText: 'Uygunsuzluğun Tarifi',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Fotoğraflar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final f in mevcutFotograflar)
              if (!silinecekFotografIdleri.contains(f.id))
                _FotoThumb(
                  child: mevcutFotografUrl[f.id] != null
                      ? Image.network(
                          mevcutFotografUrl[f.id]!,
                          fit: BoxFit.cover,
                        )
                      : const ColoredBox(color: Colors.black12),
                  onSil: () => onFotografSilExisting(f.id),
                ),
            for (final f in yeniFotograflar)
              _FotoThumb(
                child: Image.memory(f.bytes, fit: BoxFit.cover),
                onSil: () => onFotografSilYeni(f),
              ),
            _FotoEkleButonu(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
              onTap: onGaleriSec,
            ),
            _FotoEkleButonu(
              icon: Icons.camera_alt_outlined,
              label: 'Kamera',
              onTap: onKameraSec,
            ),
          ],
        ),
      ],
    );
  }
}

class _FotoThumb extends StatelessWidget {
  const _FotoThumb({required this.child, required this.onSil});

  final Widget child;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(child: child),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onSil,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoEkleButonu extends StatelessWidget {
  const _FotoEkleButonu({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _TavsiyeTerminAdimi extends StatelessWidget {
  const _TavsiyeTerminAdimi({
    required this.tavsiyeController,
    required this.terminTarihi,
    required this.onTerminChanged,
  });

  final TextEditingController tavsiyeController;
  final String? terminTarihi;
  final ValueChanged<String?> onTerminChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: tavsiyeController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Tavsiye ve Öneriler (opsiyonel)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Termin Tarihi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Hemen'),
              selected: terminTarihi == 'Hemen',
              onSelected: (_) => onTerminChanged('Hemen'),
            ),
            ChoiceChip(
              label: const Text('Sürekli'),
              selected: terminTarihi == 'Sürekli',
              onSelected: (_) => onTerminChanged('Sürekli'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final secilen = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (secilen != null) {
              onTerminChanged(DateFormat('dd.MM.yyyy').format(secilen));
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Ya da tarih seç',
              suffixIcon: Icon(Icons.event),
            ),
            child: Text(terminTarihi ?? '—'),
          ),
        ),
      ],
    );
  }
}

class _OzetAdimi extends StatelessWidget {
  const _OzetAdimi({
    required this.seciliProjeId,
    required this.seciliFirmaId,
    required this.tespitTarihi,
    required this.tehlikeSinifi,
    required this.aciklama,
    required this.tavsiyeOneri,
    required this.terminTarihi,
    required this.fotografSayisi,
  });

  final String? seciliProjeId;
  final String? seciliFirmaId;
  final DateTime tespitTarihi;
  final TehlikeSinifi? tehlikeSinifi;
  final String aciklama;
  final String tavsiyeOneri;
  final String? terminTarihi;
  final int fotografSayisi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ozetSatiri('Tarih', DateFormat('dd.MM.yyyy').format(tespitTarihi)),
        _ozetSatiri('Tehlike Sınıfı', tehlikeSinifi?.name ?? '—'),
        _ozetSatiri('Uygunsuzluğun Tarifi', aciklama.isEmpty ? '—' : aciklama),
        _ozetSatiri(
          'Tavsiye ve Öneriler',
          tavsiyeOneri.isEmpty ? '—' : tavsiyeOneri,
        ),
        _ozetSatiri('Termin', terminTarihi ?? '—'),
        _ozetSatiri('Fotoğraf Sayısı', '$fotografSayisi'),
        const SizedBox(height: 8),
        Text(
          'Göndermek için proje, firma, tehlike sınıfı, tarif, termin ve en az 1 fotoğraf zorunludur.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _ozetSatiri(String label, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Text(deger),
        ],
      ),
    );
  }
}
