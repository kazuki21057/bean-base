import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/utils/pouring_step_highlight.dart';

/// T3-79: 抽出タイマー連動のハイライト対象ステップを求める[activeStepIndex]の単体テスト。
/// 本番の実データ(method001=4:6メソッド、654c2399=井崎式)から再現した2パターンを検証する。
void main() {
  PouringStep step({required int duration, required String description}) => PouringStep(
        id: 'S',
        methodId: 'M1',
        stepOrder: 1,
        duration: duration,
        waterAmount: 0,
        waterReference: 0,
        description: description,
      );

  group('4:6メソッド型(0秒ステップの直後が空文字の説明のみ)', () {
    // 本番method001: [0(蒸らし), 45(""), 45(""), 40(""), 35(""), 45(ドリッパーを外す)]
    final steps = [
      step(duration: 0, description: '蒸らし'),
      step(duration: 45, description: ''),
      step(duration: 45, description: ''),
      step(duration: 40, description: ''),
      step(duration: 35, description: ''),
      step(duration: 45, description: 'ドリッパーを外す'),
    ];

    test('蒸らし待機中(0〜45秒)は0秒ステップ(蒸らし)がハイライトされる', () {
      expect(activeStepIndex(steps, 20), 0);
    });

    test('2投目待機中(45〜90秒)は自分自身がハイライトされる', () {
      expect(activeStepIndex(steps, 60), 2);
    });

    test('最終ステップ(説明文あり)は自分自身がハイライトされる', () {
      expect(activeStepIndex(steps, 170), 5);
    });
  });

  group('井崎式型(0秒ステップの直後にも独自の説明文がある)', () {
    // 本番654c2399: [0(スピン), 60(1投目より強く), 60(2投目より強く), 0(3回スピン), 60(落ち切り)]
    final steps = [
      step(duration: 0, description: '端までかける、スピン'),
      step(duration: 60, description: '端までかける、1投目より強く'),
      step(duration: 60, description: '端までかける、2投目より強く'),
      step(duration: 0, description: '3回スピン'),
      step(duration: 60, description: '3-4分で落ち切り'),
    ];

    test('T3-79回帰: 1投目直後の待機(0〜60秒)は独自説明文を持つステップ自身がハイライトされる(旧実装は0秒ステップに奪われていた)', () {
      expect(activeStepIndex(steps, 30), 1);
    });

    test('2投目直後の待機(60〜120秒)も同様に自分自身がハイライトされる', () {
      expect(activeStepIndex(steps, 90), 2);
    });

    test('T3-79回帰: 中間の0秒ステップ直後(120〜180秒)も独自説明文を持つステップ自身がハイライトされる', () {
      expect(activeStepIndex(steps, 150), 4);
    });
  });

  test('全ステップの合計時間を超えた場合はnull', () {
    final steps = [step(duration: 30, description: 'A')];
    expect(activeStepIndex(steps, 60), isNull);
  });

  test('ステップが空の場合はnull', () {
    expect(activeStepIndex([], 10), isNull);
  });
}
