import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';

class TutanakDurumBadge extends StatelessWidget {
  const TutanakDurumBadge({super.key, required this.durum});

  final TutanakDurumu durum;

  /// Rapor/istatistik ekranlarında da aynı renk paletinin kullanılabilmesi için public.
  static Color renk(TutanakDurumu durum) {
    switch (durum) {
      case TutanakDurumu.taslak:
        return const Color(0xFF71717A);
      case TutanakDurumu.gonderildi:
        return const Color(0xFF2563EB);
      case TutanakDurumu.incelemede:
        return const Color(0xFF9333EA);
      case TutanakDurumu.revizyonIstendi:
        return const Color(0xFFCA8A04);
      case TutanakDurumu.onaylandi:
        return const Color(0xFF16A34A);
      case TutanakDurumu.reddedildi:
        return const Color(0xFFDC2626);
      case TutanakDurumu.kapatildi:
        return const Color(0xFF0F766E);
    }
  }

  Color get _color => renk(durum);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        durum.etiket,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
