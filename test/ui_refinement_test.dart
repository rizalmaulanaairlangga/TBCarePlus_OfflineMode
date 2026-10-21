import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tbcare_plus/core/settings/app_settings.dart';
import 'package:tbcare_plus/core/widgets/app_bottom_nav.dart';
import 'package:tbcare_plus/features/about/pages/about_page.dart';
import 'package:tbcare_plus/features/assessment/pages/full_assessment_page.dart';
import 'package:tbcare_plus/features/history/pages/history_detail_page.dart';

void main() {
  test('font-size preference is restored from local storage', () async {
    final storage = await Directory.systemTemp.createTemp(
      'tbcare-font-scale-test',
    );
    Hive.init(storage.path);
    final box = await Hive.openBox('meta');

    try {
      await box.put('app_font_scale', 'large');
      await AppSettings.instance.init();
      expect(AppSettings.instance.fontScaleOption, FontScaleOption.large);
    } finally {
      await Hive.close();
      await storage.delete(recursive: true);
    }
  });

  test('changing font size notifies the app and saves the selection', () async {
    final storage = await Directory.systemTemp.createTemp(
      'tbcare-font-scale-update-test',
    );
    Hive.init(storage.path);
    final box = await Hive.openBox('meta');
    var notificationCount = 0;
    void onSettingsChanged() => notificationCount++;
    AppSettings.instance.addListener(onSettingsChanged);

    try {
      await AppSettings.instance.setFontScale(FontScaleOption.extraLarge);
      expect(notificationCount, 1);
      expect(box.get('app_font_scale'), 'extraLarge');
    } finally {
      AppSettings.instance.removeListener(onSettingsChanged);
      await AppSettings.instance.setFontScale(FontScaleOption.medium);
      await Hive.close();
      await storage.delete(recursive: true);
    }
  });

  testWidgets('full assessment navigation scrolls with its questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: FullAssessmentPage()));
    await tester.pumpAndSettle();

    final backButton = find.text('Kembali');
    final nextButton = find.text('Lanjut');
    expect(
      find.ancestor(
        of: backButton,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: nextButton,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    expect(tester.getRect(nextButton).bottom, lessThanOrEqualTo(390));

    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('2/'), findsOneWidget);
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('1/'), findsOneWidget);

    tester.view.physicalSize = const Size(780, 1688);
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: backButton,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: nextButton,
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('landscape symptom cards expand without overflowing their rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longDescription =
        'A prolonged symptom description that wraps across several lines '
        'and must remain visible when the card is expanded.';
    final items = List.generate(4, (index) {
      final categoryId = index + 1;
      return {
        'primaryTbTypeName': 'Category $categoryId',
        'primaryTbTypeId': categoryId,
        'totalScore': 72,
        'riskLevelCode': 'HIGH',
        'riskLevelTitle': 'High Risk',
        'selectedSymptoms': [
          {
            'symptomCode': 'G01',
            'symptomName': 'Symptom $categoryId one',
            'symptomDescription': longDescription,
            'tbTypeId': categoryId,
            'cfValue': 1,
          },
          {
            'symptomCode': 'G02',
            'symptomName': 'Symptom $categoryId two',
            'symptomDescription': longDescription,
            'tbTypeId': categoryId,
            'cfValue': 1,
          },
          {
            'symptomCode': 'G03',
            'symptomName': 'Symptom $categoryId three',
            'symptomDescription': longDescription,
            'tbTypeId': categoryId,
            'cfValue': 1,
          },
        ],
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(844, 390),
            textScaler: TextScaler.linear(1.3),
          ),
          child: HistoryDetailPage(
            item: {
              'color': Colors.green,
              'date': '2026-10-21',
              'type': 'Full assessment',
              'icon': Icons.medical_services,
              'percentage': '72%',
              'tbType': 'Tuberculosis',
              'riskLevel': 'High Risk',
              'riskLevelCode': 'HIGH',
            },
            detail: {'items': items},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var categoryId = 1; categoryId <= 4; categoryId++) {
      final title = find.text('Symptom $categoryId one');
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.text(longDescription), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.text(longDescription), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('landscape navigation icons and labels follow text scaling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<(double, double, double, double)> renderAtScale(double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(844, 390),
              textScaler: TextScaler.linear(scale),
            ),
            child: const Scaffold(
              body: Row(
                children: [
                  AppNavRail(currentIndex: 0, onTap: _ignoreNavigation),
                  Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final railSize = tester.getSize(find.byType(AppNavRail));
      final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      final homeLabelSize = tester.getSize(find.text('Beranda'));
      final historyLabelSize = tester.getSize(find.text('Riwayat'));
      final profileLabelSize = tester.getSize(find.text('Profil'));
      final logo = tester.widget<Image>(find.byType(Image));
      expect(historyLabelSize.height, closeTo(homeLabelSize.height, 0.1));
      expect(profileLabelSize.height, closeTo(homeLabelSize.height, 0.1));
      expect(tester.takeException(), isNull);
      return (
        railSize.width,
        homeIcon.size!,
        homeLabelSize.height,
        logo.width!,
      );
    }

    final sizes = <(double, double, double, double)>[];
    for (final scale in [0.85, 1.0, 1.15, 1.3]) {
      sizes.add(await renderAtScale(scale));
    }
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i].$1, greaterThan(sizes[i - 1].$1));
      expect(sizes[i].$2, greaterThan(sizes[i - 1].$2));
      expect(sizes[i].$3, greaterThan(sizes[i - 1].$3));
      expect(sizes[i].$4, greaterThan(sizes[i - 1].$4));
    }
  });

  testWidgets(
    'developer cards show profile names instead of a generic LinkedIn label',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutPage()));
      await tester.pumpAndSettle();

      expect(find.text('Rizal Maulana Airlangga'), findsOneWidget);
      expect(find.text('Irwin Ahmad Wiryawan'), findsOneWidget);
      expect(find.text('Nabeel Syahzada Wijawa Prakasa'), findsOneWidget);
      expect(find.text('LinkedIn'), findsNothing);
    },
  );
}

void _ignoreNavigation(int _) {}
