import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';
import 'package:bean_base/screens/log_list_screen.dart';
import 'package:bean_base/widgets/bean_image.dart';

/// Cycle 20 T3-14: 002(抽出履歴)の一覧行、左側のアイコンを豆の画像に変更した
/// ことの検証。`MockListRow`が元々対応していた`imageUrl`引数を、豆マスターの
/// `imageUrl`から解決して渡すだけの変更のため、画像あり/なし双方の表示を確認する。
CoffeeRecord _record({required String id, required String beanId}) {
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
    methodId: 'm1',
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
          beanMasterProvider.overrideWith((ref) async => [beanWithImage, beanWithoutImage]),
          methodMasterProvider.overrideWith((ref) async => [method]),
          grinderMasterProvider.overrideWith((ref) async => []),
          dripperMasterProvider.overrideWith((ref) async => []),
          filterMasterProvider.overrideWith((ref) async => []),
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
}
