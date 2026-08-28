class OsgbModel {
  final String id;
  final String ad;

  const OsgbModel({
    required this.id,
    required this.ad,
  });

  factory OsgbModel.fromJson(Map<String, dynamic> json) {
    return OsgbModel(
      id: json['id'] as String,
      ad: json['ad'] as String,
    );
  }

  Map<String, dynamic> toInsertJson() => {'ad': ad};
}
