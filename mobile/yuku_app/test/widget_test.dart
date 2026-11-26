import 'package:flutter_test/flutter_test.dart';
import 'package:yuku_app/main.dart';

void main() {
  testWidgets('MAVO home shell renders', (tester) async {
    await tester.pumpWidget(const YukuApp());
    expect(find.text('MAVO'), findsOneWidget);
    expect(find.text('FRIEND'), findsOneWidget);
    expect(find.text('EXPERIENCE'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
  });
}
