import 'package:flutter_test/flutter_test.dart';
import 'package:bean_base/models/pouring_step.dart';
import 'package:bean_base/utils/pouring_step_scaling.dart';

/// T3-58: 030(抽出レシピ)本体と[MethodStepsEditor]の湯量スケーリング計算を
/// 一本化した共通関数[scaledStepWaterAmount]の単体テスト。
void main() {
  PouringStep step({double? waterRatio, required double waterAmount}) => PouringStep(
        id: 'S1',
        methodId: 'M1',
        stepOrder: 1,
        duration: 30,
        waterAmount: waterAmount,
        waterReference: 15.0,
        waterRatio: waterRatio,
        description: 'Bloom',
      );

  test('waterRatioが設定されている場合、現在の豆量にratioを掛ける', () {
    final s = step(waterRatio: 2.0, waterAmount: 999); // waterAmountは無視される
    final result = scaledStepWaterAmount(s, currentWeight: 30.0, methodBaseWeight: 15.0);
    expect(result, closeTo(60.0, 0.001));
  });

  test('waterRatioが未設定の場合、methodBaseWeightとの比率でスケールする', () {
    final s = step(waterAmount: 30.0);
    final result = scaledStepWaterAmount(s, currentWeight: 30.0, methodBaseWeight: 15.0);
    // 豆量が基準の2倍なので湯量も2倍
    expect(result, closeTo(60.0, 0.001));
  });

  test('waterRatioが0の場合もmethodBaseWeightとの比率でスケールする(0はwaterRatio未設定扱い)', () {
    final s = step(waterRatio: 0, waterAmount: 30.0);
    final result = scaledStepWaterAmount(s, currentWeight: 45.0, methodBaseWeight: 15.0);
    expect(result, closeTo(90.0, 0.001));
  });

  test('methodBaseWeightが0以下の場合はスケールせずwaterAmountをそのまま返す', () {
    final s = step(waterAmount: 30.0);
    final result = scaledStepWaterAmount(s, currentWeight: 30.0, methodBaseWeight: 0);
    expect(result, closeTo(30.0, 0.001));
  });

  test('豆量が基準と同じ場合はスケールなし(waterAmountのまま)', () {
    final s = step(waterAmount: 120.0);
    final result = scaledStepWaterAmount(s, currentWeight: 15.0, methodBaseWeight: 15.0);
    expect(result, closeTo(120.0, 0.001));
  });
}
