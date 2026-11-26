import 'package:flutter_test/flutter_test.dart';
import 'package:yuku_app/main.dart';

void main() {
  testWidgets('YUKU home shell renders', (tester) async {
    await tester.pumpWidget(const YukuApp());
    expect(find.text('YUKU'), findsOneWidget);
    expect(find.text('Friend'), findsOneWidget);
    expect(find.text('Experience'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
  });
}
