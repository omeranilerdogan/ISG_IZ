import '../../core/constants/app_enums.dart';

class ProfileModel {
  final String id;
  final String adSoyad;
  final String? telefon;
  final KullaniciRolu rol;
  final String? firmaId;
  final String? varsayilanProjeId;
  final bool aktif;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.adSoyad,
    this.telefon,
    required this.rol,
    this.firmaId,
    this.varsayilanProjeId,
    required this.aktif,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      adSoyad: json['ad_soyad'] as String? ?? '',
      telefon: json['telefon'] as String?,
      rol: KullaniciRolu.fromDb(json['rol'] as String),
      firmaId: json['firma_id'] as String?,
      varsayilanProjeId: json['varsayilan_proje_id'] as String?,
      aktif: json['aktif'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'ad_soyad': adSoyad,
        'telefon': telefon,
      };

  bool get onayBekliyor => !aktif;

  ProfileModel copyWith({
    String? adSoyad,
    String? telefon,
    KullaniciRolu? rol,
    String? firmaId,
    String? varsayilanProjeId,
    bool? aktif,
  }) {
    return ProfileModel(
      id: id,
      adSoyad: adSoyad ?? this.adSoyad,
      telefon: telefon ?? this.telefon,
      rol: rol ?? this.rol,
      firmaId: firmaId ?? this.firmaId,
      varsayilanProjeId: varsayilanProjeId ?? this.varsayilanProjeId,
      aktif: aktif ?? this.aktif,
      createdAt: createdAt,
    );
  }
}
