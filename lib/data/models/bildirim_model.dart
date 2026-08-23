class BildirimModel {
  final String id;
  final String aliciId;
  final String? tutanakId;
  final String baslik;
  final String? icerik;
  final bool okundu;
  final DateTime createdAt;

  const BildirimModel({
    required this.id,
    required this.aliciId,
    this.tutanakId,
    required this.baslik,
    this.icerik,
    required this.okundu,
    required this.createdAt,
  });

  factory BildirimModel.fromJson(Map<String, dynamic> json) {
    return BildirimModel(
      id: json['id'] as String,
      aliciId: json['alici_id'] as String,
      tutanakId: json['tutanak_id'] as String?,
      baslik: json['baslik'] as String,
      icerik: json['icerik'] as String?,
      okundu: json['okundu'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
