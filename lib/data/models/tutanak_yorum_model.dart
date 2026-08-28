class TutanakYorumFotografModel {
  final String id;
  final String storagePath;
  final int siraNo;

  const TutanakYorumFotografModel({
    required this.id,
    required this.storagePath,
    required this.siraNo,
  });

  factory TutanakYorumFotografModel.fromJson(Map<String, dynamic> json) {
    return TutanakYorumFotografModel(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      siraNo: json['sira_no'] as int? ?? 0,
    );
  }
}

class TutanakYorumModel {
  final String id;
  final String tutanakId;
  final String? yazanId;
  final String? yazanAdi;
  final String notMetni;
  final DateTime createdAt;
  final List<TutanakYorumFotografModel> fotograflar;

  const TutanakYorumModel({
    required this.id,
    required this.tutanakId,
    this.yazanId,
    this.yazanAdi,
    required this.notMetni,
    required this.createdAt,
    this.fotograflar = const [],
  });

  factory TutanakYorumModel.fromJson(Map<String, dynamic> json) {
    final yazan = json['profiles'] as Map<String, dynamic>?;
    final fotoRows = json['tutanak_yorum_fotograflari'] as List<dynamic>? ?? const [];
    return TutanakYorumModel(
      id: json['id'] as String,
      tutanakId: json['tutanak_id'] as String,
      yazanId: json['yazan_id'] as String?,
      yazanAdi: yazan?['ad_soyad'] as String?,
      notMetni: json['not_metni'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      fotograflar: fotoRows
          .map((e) => TutanakYorumFotografModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
