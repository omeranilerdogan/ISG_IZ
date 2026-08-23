import 'package:flutter/material.dart';

/// Standart Material [Switch] bazı ortamlarda (özellikle web) dokunmalara
/// güvenilir yanıt vermediğinden, aynı görünümde ama basit bir
/// `GestureDetector` + `AnimatedContainer` üzerine kurulu, tüm alanı
/// (yalnızca thumb'ı değil) tıklanabilir yapan özel bir anahtar bileşeni.
class AcikKapaliAnahtar extends StatelessWidget {
  const AcikKapaliAnahtar({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final devreDisi = onChanged == null;
    final acikRenk = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: devreDisi ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: devreDisi ? Colors.grey.shade300 : (value ? acikRenk : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
