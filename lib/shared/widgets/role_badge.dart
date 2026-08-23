import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.rol});

  final KullaniciRolu rol;

  /// Kullanıcı Yetki ızgarasında da aynı renk paletinin kullanılabilmesi için public.
  static Color renk(KullaniciRolu rol) {
    switch (rol) {
      case KullaniciRolu.admin:
        return const Color(0xFF1F3A5F);
      case KullaniciRolu.isgUzmani:
        return const Color(0xFF0F766E);
      case KullaniciRolu.santiyeSefi:
        return const Color(0xFF9A3412);
      case KullaniciRolu.personel:
        return const Color(0xFF52525B);
    }
  }

  Color get _color => renk(rol);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rol.etiket,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
