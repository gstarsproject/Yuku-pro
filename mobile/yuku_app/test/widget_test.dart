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
  testWidgets('Home story opens the MAVO story viewer', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.text('DISCOVER'), findsOneWidget);
    expect(find.text('Bagikan cerita'), findsOneWidget);
  });

  testWidgets('Creator profile follow button updates preview state', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    await tester.tap(find.byTooltip('Lihat profil kreator'));
    await tester.pumpAndSettle();

    expect(find.text('MAVO Community'), findsOneWidget);
    expect(find.text('1280'), findsOneWidget);

    await tester.tap(find.text('Ikuti'));
    await tester.pump();

    expect(find.text('Mengikuti'), findsNWidgets(2));
    expect(find.text('1281'), findsOneWidget);
  });

}
