import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/log_list_screen.dart';
import 'package:bean_base/widgets/bean_image.dart';

import 'helpers/fake_master_notifiers.dart';

/// Cycle 20 T3-14: 002(抽出履歴)の一覧行、左側のアイコンを豆の画像に変更した
/// ことの検証。`MockListRow`が元々対応していた`imageUrl`引数を、豆マスターの
/// `imageUrl`から解決して渡すだけの変更のため、画像あり/なし双方の表示を確認する。
CoffeeRecord _record({required String id, required String beanId, String methodId = 'm1'}) {
  return CoffeeRecord(
    id: id,
    brewedAt: DateTime(2026, 7, 20, 9, 0),
    grinderId: '',
    dripperId: '',
    filterId: '',
    beanId: beanId,
    roastLevel: '',
    origin: '',
    beanWeight: 20,
    grindSize: '',
    methodId: methodId,
    taste: '',
    concentration: '',
    temperature: 92,
    bloomingWater: 40,
    totalWater: 300,
    bloomingTime: 45,
    totalTime: 210,
    scoreFragrance: 5,
    scoreAcidity: 5,
    scoreBitterness: 5,
    scoreSweetness: 5,
    scoreComplexity: 5,
    scoreFlavor: 5,
    scoreOverall: 7,
    comment: '',
  );
}

void main() {
  testWidgets('LogListScreen: 豆に画像がある場合はサムネイル(BeanImage)、無い場合はプレースホルダアイコンが表示される(T3-14)',
      (WidgetTester tester) async {
    final beanWithImage =
        BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true, imageUrl: 'https://example.com/bean.jpg');
    final beanWithoutImage = BeanMaster(id: 'b2', name: 'ブラジル', roastLevel: '深煎り', origin: 'ブラジル', isInStock: true);
    final method = MethodMaster(
      id: 'm1',
      name: 'V60',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith(
              (ref) async => [_record(id: 'r1', beanId: 'b1'), _record(id: 'r2', beanId: 'b2')]),
          beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [beanWithImage, beanWithoutImage])),
          methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [method])),
          grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [])),
          dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [])),
          filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [])),
        ],
        child: const MaterialApp(home: LogListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('ブラジル'), findsOneWidget);
    // 画像ありの豆(b1)の行だけBeanImageが使われ、そのimagePathが該当の豆のimageUrlと一致する。
    // 画像なしの豆(b2)の行はBeanImageを使わずプレースホルダアイコンのままになる
    // (テスト環境ではネットワーク画像取得が常に失敗するため、表示結果ではなく
    // どちらのウィジェットが使われているかで判定する)。
    final beanImageFinder = find.byType(BeanImage);
    expect(beanImageFinder, findsOneWidget);
    expect((tester.widget(beanImageFinder) as BeanImage).imagePath, 'https://example.com/bean.jpg');
  });

  testWidgets('LogListScreen: 豆で絞り込むと該当する記録だけが表示され、リセットで全件表示に戻る(T3-77)',
      (WidgetTester tester) async {
    final bean1 = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
    final bean2 = BeanMaster(id: 'b2', name: 'ブラジル', roastLevel: '深煎り', origin: 'ブラジル', isInStock: true);
    final method = MethodMaster(
      id: 'm1',
      name: 'V60',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith(
              (ref) async => [_record(id: 'r1', beanId: 'b1'), _record(id: 'r2', beanId: 'b2')]),
          beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [bean1, bean2])),
          methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [method])),
          grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [])),
          dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [])),
          filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [])),
        ],
        child: const MaterialApp(home: LogListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('ブラジル'), findsOneWidget);

    // 豆フィルタのドロップダウンを開いて「エチオピア」を選択する。
    await tester.tap(find.text('豆: すべて'));
    await tester.pumpAndSettle();
    // ドロップダウンメニュー内の項目(リストの行とは別インスタンス)をタップ。
    await tester.tap(find.text('エチオピア').last);
    await tester.pumpAndSettle();

    // 選択済みドロップダウンの表示ラベル自体にも「エチオピア」の文字列が
    // 出るため(閉じたボタンが選択中の項目を表示する)、行のみを見たい場合は
    // 「ブラジル」が消えたことで絞り込みが効いたと判定する。
    expect(find.text('ブラジル'), findsNothing);
    expect(find.text('1'), findsOneWidget); // フィルタ件数バッジ

    // リセットで全件表示に戻る。
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('ブラジル'), findsOneWidget);
  });

  testWidgets('LogListScreen: 複数条件を組み合わせて一致する記録が無い場合は案内文とリセット導線が表示される(T3-77)',
      (WidgetTester tester) async {
    final bean1 = BeanMaster(id: 'b1', name: 'エチオピア', roastLevel: '浅煎り', origin: 'エチオピア', isInStock: true);
    final bean2 = BeanMaster(id: 'b2', name: 'ブラジル', roastLevel: '深煎り', origin: 'ブラジル', isInStock: true);
    final method1 = MethodMaster(
      id: 'm1',
      name: 'V60',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );
    final method2 = MethodMaster(
      id: 'm2',
      name: '4:6メソッド',
      author: '',
      baseBeanWeight: 20,
      baseWaterAmount: 300,
      description: '',
      recommendedEquipment: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coffeeRecordsProvider.overrideWith(
              (ref) async => [_record(id: 'r1', beanId: 'b1'), _record(id: 'r2', beanId: 'b2', methodId: 'm2')]),
          beanMasterProvider.overrideWith(() => FakeBeanMasterNotifier(() async => [bean1, bean2])),
          methodMasterProvider.overrideWith(() => FakeMethodMasterNotifier(() async => [method1, method2])),
          grinderMasterProvider.overrideWith(() => FakeGrinderMasterNotifier(() async => [])),
          dripperMasterProvider.overrideWith(() => FakeDripperMasterNotifier(() async => [])),
          filterMasterProvider.overrideWith(() => FakeFilterMasterNotifier(() async => [])),
        ],
        child: const MaterialApp(home: LogListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 豆=エチオピア(b1)、メソッド=4:6メソッド(m2)という、どの記録とも
    // 一致しない組み合わせを選ぶ(r1はm1、r2はb2のため)。
    await tester.tap(find.text('豆: すべて'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('エチオピア').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('メソッド: すべて'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4:6メソッド').last);
    await tester.pumpAndSettle();

    expect(find.text('条件に一致する記録がありません'), findsOneWidget);
    // 「エチオピア」はフィルタチップ自身の選択中ラベルとして残るため、
    // 行が消えたことは選択されていない側の「ブラジル」で確認する。
    expect(find.text('ブラジル'), findsNothing);

    await tester.tap(find.text('フィルタをリセット'));
    await tester.pumpAndSettle();

    expect(find.text('エチオピア'), findsOneWidget);
    expect(find.text('ブラジル'), findsOneWidget);
  });
}
