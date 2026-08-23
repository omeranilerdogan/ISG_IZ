import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:isg_uygunsuzluk_tespit/main.dart';

void main() {
  testWidgets('.env yapılandırılmamışken uygulama uyarı ekranı gösterir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IsgUygunsuzlukApp()));
    await tester.pumpAndSettle();

    expect(find.text('Supabase Yapılandırması Eksik'), findsOneWidget);
  });
}
