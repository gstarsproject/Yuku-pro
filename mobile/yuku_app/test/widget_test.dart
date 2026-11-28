import 'package:flutter_test/flutter_test.dart';
import 'package:yuku_app/main.dart';

void main() {
  testWidgets('MAVO marketplace home shows the three core pillars', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    expect(find.text('MAVO'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('Layanan pilihan'), findsOneWidget);
  });

  testWidgets('Primary navigation opens all five marketplace sections', (tester) async {
    await tester.pumpWidget(const YukuApp());
    await tester.pump();

    await tester.tap(find.text('Explore'));
    await tester.pump();
    expect(find.text('Temukan kreator, layanan, dan pengalaman.'), findsOneWidget);

    await tester.tap(find.text('Bookings'));
    await tester.pump();
    expect(find.text('Masuk untuk melihat booking'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pump();
    expect(find.text('Pesan'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Profil'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(find.text('Jelajahi kategori'), findsOneWidget);
  });
}
