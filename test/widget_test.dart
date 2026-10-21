import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbcare_plus/main.dart';
import 'package:tbcare_plus/core/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('App loads home and transitions from splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Advance timers through splash entrance, pulse, hold, and exit transitions
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('Orientation change renders navigation appropriately', (WidgetTester tester) async {
    // 1. Portrait phone: 390x844
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // In portrait, AppBottomNav is displayed and AppNavRail is NOT visible
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);

    // 2. Rotate to landscape phone: 844x390
    tester.view.physicalSize = const Size(844 * 2.0, 390 * 2.0);
    await tester.pumpAndSettle();

    // In landscape phone, AppNavRail is displayed on the left and AppBottomNav is hidden
    expect(find.byType(AppNavRail), findsOneWidget);
    expect(find.descendant(of: find.byType(AppNavRail), matching: find.byIcon(Icons.home_rounded)), findsOneWidget);
    expect(find.descendant(of: find.byType(AppNavRail), matching: find.byIcon(Icons.history_rounded)), findsOneWidget);
    expect(find.descendant(of: find.byType(AppNavRail), matching: find.byIcon(Icons.person_rounded)), findsOneWidget);

    // 3. Rotate back to portrait
    tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppNavRail), findsNothing);
  });

  testWidgets('Settings & About page headers are compact in landscape mode', (WidgetTester tester) async {
    // Landscape phone: 844x390
    tester.view.physicalSize = const Size(844 * 2.0, 390 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    // Splash settle
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Navigate to profile
    final profileNav = find.descendant(of: find.byType(AppNavRail), matching: find.byIcon(Icons.person_rounded));
    await tester.tap(profileNav);
    await tester.pumpAndSettle();

    // Check Settings and About Application cards exist and have equal heights in landscape
    final settingsCard = find.text('Pengaturan');
    final aboutCard = find.text('Tentang Aplikasi Ini');
    expect(settingsCard, findsOneWidget);
    expect(aboutCard, findsOneWidget);

    final settingsRender = tester.getRect(find.ancestor(of: settingsCard, matching: find.byType(GestureDetector)).first);
    final aboutRender = tester.getRect(find.ancestor(of: aboutCard, matching: find.byType(GestureDetector)).first);
    expect(settingsRender.size.height, closeTo(aboutRender.size.height, 1.0));

    // Tap Settings card
    await tester.tap(settingsCard);
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsWidgets);
    // Back to profile
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Tap About card
    await tester.tap(aboutCard);
    await tester.pumpAndSettle();
    expect(find.text('Tentang Aplikasi Ini'), findsWidgets);
  });

  testWidgets('Full assessment header is compact in landscape and questions are accessible', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(844 * 2.0, 390 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Tap "Lanjutkan ke Pemeriksaan Lengkap"
    final fullBtn = find.text('Lanjutkan ke Pemeriksaan Lengkap');
    await tester.ensureVisible(fullBtn);
    await tester.tap(fullBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan Kesehatan Lengkap'), findsOneWidget);
    expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
  });
}
