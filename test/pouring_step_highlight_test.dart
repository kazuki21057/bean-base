import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/utils/pouring_step_highlight.dart';

/// T3-80: 抽出タイマー連動のハイライト対象ステップ集合を求める[activeStepIndexes]の単体テスト。
/// 本番の実データ(method001=4:6メソッド、654c2399=井崎式、9a4a54a9=急冷式)から
/// 再現したケースを検証する。
///
/// 新仕様: 各ステップの「操作時刻」は先頭からの`加算時間`の累計(=画面の
/// 「経過時間」列)であり、そのステップは自分の操作時刻が到来してから次の
/// 操作時刻が到来するまで点灯し続ける。同一操作時刻の複数ステップは同時に
/// 点灯し、最後の操作時刻を過ぎた後は最終ステップを点灯させ続ける(H4/H6)。
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

  group('4:6メソッド型(method001: 0,45,45,40,35,45)', () {
    // 操作時刻: 0:00(蒸らし) / 0:45 / 1:30 / 2:10 / 2:45 / 3:30(ドリッパーを外す)
    final steps = [
      step(duration: 0, description: '蒸らし'),
      step(duration: 45, description: ''),
      step(duration: 45, description: ''),
      step(duration: 40, description: ''),
      step(duration: 35, description: ''),
      step(duration: 45, description: 'ドリッパーを外す'),
    ];

    test('0:00〜0:44は先頭ステップが点灯', () {
      expect(activeStepIndexes(steps, 0), {0});
      expect(activeStepIndexes(steps, 44.9), {0});
    });

    test('45.0秒ちょうどは2番目のステップに切り替わる', () {
      expect(activeStepIndexes(steps, 45.0), {1});
    });

    test('89.9秒はまだ2番目のステップ', () {
      expect(activeStepIndexes(steps, 89.9), {1});
    });

    test('90.0秒は3番目のステップに切り替わる', () {
      expect(activeStepIndexes(steps, 90.0), {2});
    });

    test('210秒(最終操作時刻)ちょうどは最終ステップが点灯', () {
      expect(activeStepIndexes(steps, 210), {5});
    });

    test('400秒(合計時間超過)でも最終ステップが点灯し続ける(H4回帰)', () {
      expect(activeStepIndexes(steps, 400), {5});
    });
  });

  group('井崎式型(654c2399: 0,60,60,0,60)', () {
    // 操作時刻: 0:00 / 1:00 / 2:00 / 2:00(同時刻) / 3:00
    final steps = [
      step(duration: 0, description: '端までかける、スピン'),
      step(duration: 60, description: '端までかける、1投目より強く'),
      step(duration: 60, description: '端までかける、2投目より強く'),
      step(duration: 0, description: '3回スピン'),
      step(duration: 60, description: '3-4分で落ち切り'),
    ];

    test('0秒は先頭ステップ(0秒ステップ)が点灯する(H2回帰)', () {
      expect(activeStepIndexes(steps, 0), {0});
    });

    test('60秒は2番目のステップが点灯する', () {
      expect(activeStepIndexes(steps, 60), {1});
    });

    test('120秒は同一操作時刻2:00の2ステップが同時に点灯する(H6回帰)', () {
      expect(activeStepIndexes(steps, 120), {2, 3});
    });

    test('180秒は最終ステップが点灯する', () {
      expect(activeStepIndexes(steps, 180), {4});
    });
  });

  group('急冷式型(9a4a54a9: 0,0,40,30,30,30,50)', () {
    // 先頭2ステップがともに0秒(操作時刻0:00)。
    final steps = [
      step(duration: 0, description: '氷80g'),
      step(duration: 0, description: 'かき混ぜる'),
      step(duration: 40, description: ''),
      step(duration: 30, description: ''),
      step(duration: 30, description: ''),
      step(duration: 30, description: ''),
      step(duration: 50, description: '抽出完了'),
    ];

    test('0秒は先頭2ステップが同時に点灯する', () {
      expect(activeStepIndexes(steps, 0), {0, 1});
    });
  });

  test('空リストは空集合', () {
    expect(activeStepIndexes([], 10), <int>{});
  });
}
