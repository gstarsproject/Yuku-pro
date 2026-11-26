import 'package:flutter_test/flutter_test.dart';
import 'package:yuku_app/main.dart';

void main() {
  testWidgets('MAVO home shell renders', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    expect(find.text('MAVO'), findsOneWidget);
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
  });

  testWidgets('Inbox opens a conversation preview', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(find.text('Pesan'), findsOneWidget);
    expect(find.text('Nadia Putri'), findsOneWidget);

    await tester.tap(find.text('Nadia Putri'));
    await tester.pumpAndSettle();

    expect(find.text('Mode pratinjau — pesan hanya tersimpan di layar ini.'), findsOneWidget);
    expect(find.text('Hai! Senang bisa terhubung di MAVO 😊'), findsOneWidget);
  });
}
