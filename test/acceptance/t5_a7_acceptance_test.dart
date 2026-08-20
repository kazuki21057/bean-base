// 受け入れテスト: T5-A7
// 完了条件(docs/改修マスタープラン.md 342行目より):
// 「`integration_test` スモークスイート。起動→記録(抽出→評価)→保存→一覧反映→
//   インサイト表示→設定 の一筆書き+5マスタ全部の一覧→詳細→編集
//   エミュレータ上で全パス。`verify.ps1`とは別コマンドで実行できる」
//
// integration_test/smoke_test.dart 自体はエミュレータが無いと実行できないため
// (docs/acceptance_harness_design.md §5.4)、本テストは`flutter test`だけで機械判定
// できる範囲——スイートの存在・依存の配線・verify.ps1から独立して実行できること・
// シナリオ本文が完了条件の各要素(起動/記録/保存/一覧反映/インサイト表示/設定/
// 5マスタの一覧→詳細→編集)を実際に踏んでいること——を静的に検証する。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('受け入れ(T5-A7)', () {
    late String smokeTestSource;

    setUpAll(() {
      final file = File('integration_test/smoke_test.dart');
      expect(file.existsSync(), isTrue, reason: 'integration_test/smoke_test.dart が存在しません');
      smokeTestSource = file.readAsStringSync();
    });

    test('ケース1: integration_test/smoke_test.dart が存在する', () {
      expect(smokeTestSource, isNotEmpty);
    });

    test('ケース2: pubspec.yaml に integration_test(sdk: flutter)が dev_dependencies として追加されている', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final devDepsIndex = pubspec.indexOf('dev_dependencies:');
      expect(devDepsIndex, greaterThanOrEqualTo(0), reason: 'dev_dependencies: セクションが見つかりません');
      final afterDevDeps = pubspec.substring(devDepsIndex);
      expect(
        afterDevDeps.contains('integration_test:'),
        isTrue,
        reason: 'dev_dependencies に integration_test: がありません',
      );
      // integration_test: の直後の非空行が `sdk: flutter` であること。
      final lines = afterDevDeps.split('\n');
      final idx = lines.indexWhere((l) => l.trim() == 'integration_test:');
      expect(idx, greaterThanOrEqualTo(0));
      final nextNonEmpty = lines.skip(idx + 1).firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
      expect(nextNonEmpty.trim(), 'sdk: flutter');
    });

    test('ケース3: tools/verify.ps1 は integration_test を実行しない(verify.ps1とは別コマンドで実行できる)', () {
      final verifyPs1 = File('tools/verify.ps1');
      expect(verifyPs1.existsSync(), isTrue, reason: 'tools/verify.ps1 が存在しません');
      final content = verifyPs1.readAsStringSync();
      expect(
        content.contains('integration_test'),
        isFalse,
        reason: 'tools/verify.ps1 が integration_test に言及しています。'
            'T5-A7完了条件は「verify.ps1とは別コマンドで実行できる」ことのため、'
            'verify.ps1側から自動起動してはいけません',
      );
    });

    test('ケース4: シナリオが「起動(lib/main.dartのpersonal版)」を踏んでいる', () {
      expect(smokeTestSource.contains("import 'package:bean_base/main.dart' as app;"), isTrue);
      expect(smokeTestSource.contains('app.main();'), isTrue);
    });

    test('ケース5: シナリオが「記録: 抽出(豆選択→抽出パラメータ入力)→評価」を踏んでいる', () {
      // 030(抽出レシピ)のメソッド選択・豆量入力
      expect(smokeTestSource.contains('brew_recipe_method_dropdown'), isTrue);
      expect(smokeTestSource.contains('brew_recipe_bean_weight_field'), isTrue);
      // 031(評価)の豆選択・湯温入力・登録
      expect(smokeTestSource.contains('eval_bean_dropdown'), isTrue);
      expect(smokeTestSource.contains('eval_temperature_field'), isTrue);
      expect(smokeTestSource.contains("find.text('評価を登録する')"), isTrue);
    });

    test('ケース6: シナリオが「保存後、一覧画面に反映されていることを確認」を踏んでいる', () {
      expect(smokeTestSource.contains('afterLogCount'), isTrue);
      expect(smokeTestSource.contains('greaterThan(baselineLogCount)'), isTrue);
    });

    test('ケース7: シナリオが「インサイト表示画面が開けることを確認」を踏んでいる', () {
      expect(smokeTestSource.contains('StatisticsScreen'), isTrue);
    });

    test('ケース8: シナリオが「設定画面が開けることを確認」を踏んでいる', () {
      expect(smokeTestSource.contains('SettingsScreen'), isTrue);
    });

    test('ケース9: シナリオが5マスタ全部(豆/グラインダー/ドリッパー/フィルター/メソッド)の一覧→詳細→編集を踏んでいる', () {
      const requiredLabels = ['豆管理', 'ドリッパー管理', 'フィルター管理', 'メソッド管理', 'グラインダー管理'];
      for (final label in requiredLabels) {
        expect(
          smokeTestSource.contains(label),
          isTrue,
          reason: 'シナリオに $label への導線がありません',
        );
      }
      // 詳細→編集(CreateFormScaffold)への遷移確認を踏んでいること。
      expect(smokeTestSource.contains('CreateFormScaffold'), isTrue);
      expect(smokeTestSource.contains("find.byTooltip('編集')"), isTrue);
    });
  });
}
