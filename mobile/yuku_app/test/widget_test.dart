import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuku_app/screens/auth_screen.dart';
import 'package:yuku_app/screens/stories_screen.dart';
import 'package:yuku_app/screens/story_composer_screen.dart';

void main() {
  testWidgets('MAVO sign-in screen renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthenticated: () {}),
    ));

    expect(find.text('Selamat datang di MAVO'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('MAVO registration form can be opened', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthenticated: () {}),
    ));

    await tester.tap(find.text('Belum punya akun? Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Akun'), findsOneWidget);
    expect(find.text('Nama tampilan'), findsOneWidget);
    expect(find.text('Password minimal 10 karakter.'), findsOneWidget);
  });

  testWidgets('Story composer offers photo and video selection', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StoryComposerScreen()));

    expect(find.text('Buat Story'), findsOneWidget);
    expect(find.text('Pilih foto atau video'), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bagikan Story'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bagikan Story'), findsOneWidget);
    expect(find.text('Story akan otomatis hilang setelah 24 jam.'), findsOneWidget);
  });

  testWidgets('Story viewer displays text-only story', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoriesScreen(stories: [
        {
          'id': 'story-1',
          'content': 'Halo dari MAVO!',
          'authorName': 'MAVO Creator',
          'createdAt': DateTime.now().toIso8601String(),
          'media': <Map<String, dynamic>>[],
        },
      ]),
    ));

    expect(find.text('MAVO Creator'), findsOneWidget);
    expect(find.text('Halo dari MAVO!'), findsOneWidget);
  });
}
