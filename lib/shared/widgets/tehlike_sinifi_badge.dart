import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';

class TehlikeSinifiBadge extends StatelessWidget {
  const TehlikeSinifiBadge({super.key, required this.sinif});

  final TehlikeSinifi sinif;

  /// Rapor/istatistik ekranlarında da aynı renk paletinin kullanılabilmesi için public.
  static Color renk(TehlikeSinifi sinif) {
    switch (sinif) {
      case TehlikeSinifi.A:
        return const Color(0xFFDC2626);
      case TehlikeSinifi.B:
        return const Color(0xFFCA8A04);
      case TehlikeSinifi.C:
        return const Color(0xFF16A34A);
    }
  }

  Color get _color => renk(sinif);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _color,
      child: Text(
        sinif.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
