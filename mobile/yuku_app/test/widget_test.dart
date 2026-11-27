import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:yuku_app/screens/app_shell.dart';
import 'package:yuku_app/screens/auth_screen.dart';
import 'package:yuku_app/screens/creator_profile_screen.dart';
import 'package:yuku_app/screens/inbox_screen.dart';
import 'package:yuku_app/screens/stories_screen.dart';

void main() {
  testWidgets('MAVO home shell renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump();

    expect(find.text('MAVO'), findsOneWidget);
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
  });

  testWidgets('Inbox renders the live conversation screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: InboxScreen())));
    await tester.pump();

    expect(find.text('Pesan'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_square), findsOneWidget);
  });

  testWidgets('MAVO Stories screen renders live story controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StoriesScreen(initialStory: 'Discover'),
    ));
    await tester.pump();

    expect(find.text('MAVO Stories'), findsOneWidget);
    expect(find.text('Buat Story'), findsOneWidget);
  });

  testWidgets('Creator demo profile keeps follow disabled without account id', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: CreatorProfileScreen(creatorName: 'MAVO Community'),
    ));
    await tester.pump();

    expect(find.text('MAVO Community'), findsOneWidget);
    expect(find.text('Pengikut'), findsOneWidget);
    expect(find.text('Mengikuti'), findsOneWidget);
    expect(find.text('Profil demo'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('MAVO authentication screen shows sign in form', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(onAuthenticated: (_) {})));
    expect(find.text('Selamat datang kembali'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('MAVO authentication screen switches to registration', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(onAuthenticated: (_) {})));
    await tester.tap(find.text('Belum punya akun? Daftar sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Bergabung dengan MAVO'), findsOneWidget);
    expect(find.text('Nama lengkap'), findsOneWidget);
    expect(find.text('Buat Akun'), findsOneWidget);
  });
}
