// ignore_for_file: always_use_package_imports
import '../models/pouring_step.dart';

/// 注湯ステップの湯量を現在の豆量でスケーリングする共通ロジック。
///
/// 030(抽出レシピ画面)と[MethodStepsEditor]の両方で使う。
/// `waterRatio`が設定されていれば`ratio * currentWeight`で求め、
/// 未設定(null/0)のステップは`methodBaseWeight`との比率でスケールする。
/// T3-58: 030本体の計算式とMethodStepsEditorの表示計算式が食い違っていた
/// (エディタ側がratio無しステップをスケールしていなかった)ため、
/// ロジックをここに一本化した。
double scaledStepWaterAmount(
  PouringStep step, {
  required double currentWeight,
  required double methodBaseWeight,
}) {
  if (step.waterRatio != null && step.waterRatio! > 0) {
    return step.waterRatio! * currentWeight;
  }
  final scaleFactor = methodBaseWeight > 0 ? (currentWeight / methodBaseWeight) : 1.0;
  return step.waterAmount * scaleFactor;
}
