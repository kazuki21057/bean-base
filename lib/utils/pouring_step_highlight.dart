import '../models/pouring_step.dart';

/// タイマー連動で点灯させるステップ(0始まりindex)の集合を返す。
///
/// 各ステップの「操作時刻」は、先頭からそのステップまでの「加算時間(秒)」の
/// 累計であり、画面の「経過時間」列に表示されている値と一致する。
/// `加算時間`は**そのステップの操作を行うまでの待ち時間**であって、操作自体の
/// 所要時間ではない(本番データで確認済み。例: 4:6メソッドは 0:00 蒸らし →
/// 0:45 / 1:30 / 2:10 / 2:45 に注湯 → 3:30 ドリッパーを外す)。
///
/// そのため、あるステップは**自分の操作時刻が到来してから、次の操作時刻が
/// 到来するまで**点灯し続ける。操作時刻が同じステップが複数ある場合
/// (0秒ステップとその直後など)は、それらを**同時に**点灯させる。
/// 最後の操作時刻を過ぎた後は最終ステップを点灯させ続ける。
///
/// 過去バージョンは点灯区間を[前の操作時刻, 自分の操作時刻)としていたため、
/// 常に1ステップ先を点灯させており、実際の注湯タイミングとずれていた(T3-80)。
Set<int> activeStepIndexes(List<PouringStep> steps, double elapsedSec) {
  if (steps.isEmpty) return const <int>{};

  final actionTimes = <int>[];
  var cumulative = 0;
  for (final step in steps) {
    cumulative += step.duration;
    actionTimes.add(cumulative);
  }

  // 最初の操作時刻より前は、直後に来る先頭ステップを予告点灯する。
  if (elapsedSec < actionTimes.first) return <int>{0};

  // 直近に到来した操作時刻を求める(最後の操作時刻を過ぎた後はそれを保持)。
  var current = actionTimes.first;
  for (final t in actionTimes) {
    if (t <= elapsedSec) {
      current = t;
    } else {
      break;
    }
  }

  final result = <int>{};
  for (var i = 0; i < actionTimes.length; i++) {
    if (actionTimes[i] == current) result.add(i);
  }
  return result;
}
