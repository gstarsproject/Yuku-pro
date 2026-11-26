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
}
