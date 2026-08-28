class FirmaModel {
  final String id;
  final String ad;
  final String? projeId;

  const FirmaModel({
    required this.id,
    required this.ad,
    this.projeId,
  });

  factory FirmaModel.fromJson(Map<String, dynamic> json) {
    return FirmaModel(
      id: json['id'] as String,
      ad: json['ad'] as String,
      projeId: json['proje_id'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'ad': ad,
        'proje_id': projeId,
      };
}
