// T5-B21: デザイントークン(ライト/ダーク)の受入テスト。
// 仕様の正本: docs/android_monetization/デザイン方針.md §3・§13(T5-B21)。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bean_base/config/app_edition.dart';
import 'package:bean_base/main_public.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/providers/public_theme_provider.dart';
import 'package:bean_base/theme/public/bb_colors.dart';
import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/theme/public/bb_typography.dart';

import '../helpers/fake_master_notifiers.dart';

List<Override> _dataOverrides() => [
      coffeeRecordsProvider.overrideWith((ref) async => []),
      beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [])),
      methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [])),
      grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [])),
      dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [])),
      filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [])),
    ];

void main() {
  group('受入(T5-B21)', () {
    test('ケース1: buildPublicThemeがライト/ダークともに例外なくThemeDataを返す', () {
      expect(buildPublicTheme(Brightness.light), isA<ThemeData>());
      expect(buildPublicTheme(Brightness.dark), isA<ThemeData>());
    });

    test('ケース2: ColorSchemeの主要ロールが設計書§3.1のhex値と一致する(ライト)', () {
      final theme = buildPublicTheme(Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF00695E));
      expect(theme.colorScheme.surface, const Color(0xFFF4F7F7));
      expect(theme.colorScheme.error, const Color(0xFFB3261E));
    });

    test('ケース2: ColorSchemeの主要ロールが設計書§3.1のhex値と一致する(ダーク)', () {
      final theme = buildPublicTheme(Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF79C8C0));
      expect(theme.colorScheme.surface, const Color(0xFF0E1315));
      expect(theme.colorScheme.error, const Color(0xFFFF9B92));
    });

    test('ケース3: ThemeData.extension<BbColors>()が非nullで設計書§3.2のhex値と一致する(ライト)', () {
      final theme = buildPublicTheme(Brightness.light);
      final bbColors = theme.extension<BbColors>();
      expect(bbColors, isNotNull);
      expect(bbColors!.live, const Color(0xFFE08A2E));
      expect(bbColors.liveText, const Color(0xFF8A4B00));
      expect(bbColors.adSlotBackground, const Color(0xFFE8EDEE));
    });

    test('ケース3: ThemeData.extension<BbColors>()が非nullで設計書§3.2のhex値と一致する(ダーク)', () {
      final theme = buildPublicTheme(Brightness.dark);
      final bbColors = theme.extension<BbColors>();
      expect(bbColors, isNotNull);
      expect(bbColors!.live, const Color(0xFFF0A24A));
      expect(bbColors.liveText, const Color(0xFFF5BE7E));
      expect(bbColors.adSlotBackground, const Color(0xFF12181A));
    });

    test('ケース3.5: BbTypography.unitの色はonSurfaceVariant、他numeral*はonSurface(§4.2/M3)', () {
      final lightTheme = buildPublicTheme(Brightness.light);
      final lightType = lightTheme.extension<BbTypography>();
      expect(lightType, isNotNull);
      expect(lightType!.unit.color, lightTheme.colorScheme.onSurfaceVariant);
      expect(lightType.numeralM.color, lightTheme.colorScheme.onSurface);
      expect(
        lightType.unit.color,
        isNot(equals(lightTheme.colorScheme.onSurface)),
      );

      final darkTheme = buildPublicTheme(Brightness.dark);
      final darkType = darkTheme.extension<BbTypography>();
      expect(darkType, isNotNull);
      expect(darkType!.unit.color, darkTheme.colorScheme.onSurfaceVariant);
    });

    test('ケース4: lib/theme/public/配下にmainColorProviderへの参照が無い', () {
      final dir = Directory('lib/theme/public');
      expect(dir.existsSync(), isTrue, reason: 'lib/theme/public/が存在しません');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('mainColorProvider'),
          isFalse,
          reason: '${file.path} に mainColorProvider への参照があります',
        );
      }
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ケース5: MyAppがThemeMode.lightで例外なく起動する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._dataOverrides(),
            appEditionProvider.overrideWithValue(kPublicEdition),
            publicThemeModeProvider.overrideWith((ref) => ThemeMode.light),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ケース5: MyAppがThemeMode.darkで例外なく起動する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._dataOverrides(),
            appEditionProvider.overrideWithValue(kPublicEdition),
            publicThemeModeProvider.overrideWith((ref) => ThemeMode.dark),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
