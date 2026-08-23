import '../../core/constants/app_enums.dart';

class TutanakModel {
  final String id;
  final String? uttNo;
  final String projeId;
  final String? projeAdi;
  final String firmaId;
  final String? firmaAdi;
  final String raporlayanId;
  final String? raporlayanAdi;
  final DateTime tespitTarihi;
  final TehlikeSinifi tehlikeSinifi;
  final String aciklama;
  final String? tavsiyeOneri;
  final String? terminTarihi;
  final num? cezaTutari;
  final TutanakDurumu durum;
  final String? onaylayanId;
  final String? redRevizyonNotu;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TutanakModel({
    required this.id,
    this.uttNo,
    required this.projeId,
    this.projeAdi,
    required this.firmaId,
    this.firmaAdi,
    required this.raporlayanId,
    this.raporlayanAdi,
    required this.tespitTarihi,
    required this.tehlikeSinifi,
    required this.aciklama,
    this.tavsiyeOneri,
    this.terminTarihi,
    this.cezaTutari,
    required this.durum,
    this.onaylayanId,
    this.redRevizyonNotu,
    required this.createdAt,
    required this.updatedAt,
  });

  /// `get_tutanaklar()` RPC çıktısından (proje/firma/raporlayan adı dahil).
  factory TutanakModel.fromRpcJson(Map<String, dynamic> json) {
    return TutanakModel(
      id: json['id'] as String,
      uttNo: json['utt_no'] as String?,
      projeId: json['proje_id'] as String,
      projeAdi: json['proje_adi'] as String?,
      firmaId: json['firma_id'] as String,
      firmaAdi: json['firma_adi'] as String?,
      raporlayanId: json['raporlayan_id'] as String,
      raporlayanAdi: json['raporlayan_adi'] as String?,
      tespitTarihi: DateTime.parse(json['tespit_tarihi'] as String),
      tehlikeSinifi: TehlikeSinifi.fromDb(json['tehlike_sinifi'] as String),
      aciklama: json['aciklama'] as String,
      tavsiyeOneri: json['tavsiye_oneri'] as String?,
      terminTarihi: json['termin_tarihi'] as String?,
      cezaTutari: json['ceza_tutari'] as num?,
      durum: TutanakDurumu.fromDb(json['durum'] as String),
      onaylayanId: json['onaylayan_id'] as String?,
      redRevizyonNotu: json['red_revizyon_notu'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Doğrudan `tutanaklar` tablosundan okunduğunda (join'siz).
  factory TutanakModel.fromTableJson(Map<String, dynamic> json) {
    return TutanakModel(
      id: json['id'] as String,
      uttNo: json['utt_no'] as String?,
      projeId: json['proje_id'] as String,
      firmaId: json['firma_id'] as String,
      raporlayanId: json['raporlayan_id'] as String,
      tespitTarihi: DateTime.parse(json['tespit_tarihi'] as String),
      tehlikeSinifi: TehlikeSinifi.fromDb(json['tehlike_sinifi'] as String),
      aciklama: json['aciklama'] as String,
      tavsiyeOneri: json['tavsiye_oneri'] as String?,
      terminTarihi: json['termin_tarihi'] as String?,
      cezaTutari: json['ceza_tutari'] as num?,
      durum: TutanakDurumu.fromDb(json['durum'] as String),
      onaylayanId: json['onaylayan_id'] as String?,
      redRevizyonNotu: json['red_revizyon_notu'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get duzenlenebilir =>
      durum == TutanakDurumu.taslak || durum == TutanakDurumu.revizyonIstendi;
}
