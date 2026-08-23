class TutanakFotografModel {
  final String id;
  final String tutanakId;
  final String storagePath;
  final int siraNo;

  const TutanakFotografModel({
    required this.id,
    required this.tutanakId,
    required this.storagePath,
    required this.siraNo,
  });

  factory TutanakFotografModel.fromJson(Map<String, dynamic> json) {
    return TutanakFotografModel(
      id: json['id'] as String,
      tutanakId: json['tutanak_id'] as String,
      storagePath: json['storage_path'] as String,
      siraNo: json['sira_no'] as int? ?? 0,
    );
  }
}
