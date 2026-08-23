import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/indirilen_dosya.dart';
import '../data/repositories/indirilen_dosya_deposu.dart';

final indirilenDosyaDeposuProvider = Provider<IndirilenDosyaDeposu>((ref) {
  return IndirilenDosyaDeposu();
});

final indirilenDosyalarProvider = FutureProvider.autoDispose<List<IndirilenDosya>>((ref) {
  return ref.watch(indirilenDosyaDeposuProvider).tumunuGetir();
});
