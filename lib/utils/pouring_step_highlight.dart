import '../models/pouring_step.dart';

/// タイマー連動のハイライト対象ステップ(0始まりindex)を、経過秒数と
/// ステップ一覧から求める。抽出タイマー未動作時にnullを返すかどうかは
/// 呼び出し側の責務(このファイルはelapsedSecが渡された前提で計算する)。
///
/// 「加算時間(秒)」が0のステップ(例: 蒸らし開始などの瞬間アクション)は
/// それ自体の待機区間を持たない。直後の非ゼロステップに**独自の説明文が
/// 無い場合のみ**(単なる待機の継続とみなせる場合)、その待機区間の
/// ハイライトを0秒ステップ側へ譲る。直後のステップが独自の説明文を
/// 持つ場合(例: 井崎式メソッドの2投目・3投目の指示)はそのステップ自身を
/// ハイライトする。
///
/// 過去バージョンは説明文の有無を見ずに常に0秒ステップ側へ譲っていたため、
/// 独自の指示を持つステップが一度もハイライトされず、抽出が進むほど
/// ハイライトと実際の注湯タイミングがずれて見える不具合があった(T3-79)。
int? activeStepIndex(List<PouringStep> steps, double elapsedSec) {
  int cumulative = 0;
  int? zeroGroupStart;
  for (var i = 0; i < steps.length; i++) {
    final start = cumulative;
    final step = steps[i];
    final duration = step.duration;
    if (duration == 0) {
      zeroGroupStart ??= i;
      continue;
    }
    cumulative += duration;
    if (elapsedSec >= start && elapsedSec < cumulative) {
      if (step.description.trim().isEmpty && zeroGroupStart != null) {
        return zeroGroupStart;
      }
      return i;
    }
    zeroGroupStart = null;
  }
  return null;
}
