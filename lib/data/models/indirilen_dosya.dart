/// PDF/Excel dışa aktarımlarının cihazda tutulan kaydı — "İndirilen
/// Dosyalar" ekranında listelenir, dokununca doğrudan açılır.
class IndirilenDosya {
  final String id;
  final String ad;

  /// 'pdf' | 'excel'
  final String tur;

  /// Native platformlarda dosyanın kalıcı depodaki tam yolu; web'de null
  /// (web'de tarayıcı kendi indirilenler mekanizmasını kullanır).
  final String? dosyaYolu;

  final String? tutanakId;
  final DateTime olusturmaZamani;

  const IndirilenDosya({
    required this.id,
    required this.ad,
    required this.tur,
    this.dosyaYolu,
    this.tutanakId,
    required this.olusturmaZamani,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'tur': tur,
        'dosya_yolu': dosyaYolu,
        'tutanak_id': tutanakId,
        'olusturma_zamani': olusturmaZamani.toIso8601String(),
      };

  factory IndirilenDosya.fromJson(Map<String, dynamic> json) {
    return IndirilenDosya(
      id: json['id'] as String,
      ad: json['ad'] as String,
      tur: json['tur'] as String,
      dosyaYolu: json['dosya_yolu'] as String?,
      tutanakId: json['tutanak_id'] as String?,
      olusturmaZamani: DateTime.parse(json['olusturma_zamani'] as String),
    );
  }
}
