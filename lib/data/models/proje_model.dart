class ProjeModel {
  final String id;
  final String ad;
  final String? yukleniciAdi;
  final String? adres;
  final bool aktif;
  final String? osgbId;

  const ProjeModel({
    required this.id,
    required this.ad,
    this.yukleniciAdi,
    this.adres,
    required this.aktif,
    this.osgbId,
  });

  factory ProjeModel.fromJson(Map<String, dynamic> json) {
    return ProjeModel(
      id: json['id'] as String,
      ad: json['ad'] as String,
      yukleniciAdi: json['yuklenici_adi'] as String?,
      adres: json['adres'] as String?,
      aktif: json['aktif'] as bool? ?? true,
      osgbId: json['osgb_id'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'ad': ad,
        'yuklenici_adi': yukleniciAdi,
        'adres': adres,
        'aktif': aktif,
        'osgb_id': osgbId,
      };
}
