import '../../core/constants/app_enums.dart';

class FirmaModel {
  final String id;
  final String ad;
  final FirmaTuru tur;

  const FirmaModel({
    required this.id,
    required this.ad,
    required this.tur,
  });

  factory FirmaModel.fromJson(Map<String, dynamic> json) {
    return FirmaModel(
      id: json['id'] as String,
      ad: json['ad'] as String,
      tur: FirmaTuru.fromDb(json['tur'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'ad': ad,
        'tur': tur.dbValue,
      };
}
