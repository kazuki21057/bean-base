# T3-53 設計書: 最適条件探索の「検証状況」可視化(画面045)

作成: 2026-07-31 / 作成者: 上位モデル(Opus 5)/ 対象タスク: **T3-53**
正本の位置づけ: 本書は **T3-53 の実装仕様の単一の真実**。前提となる GP の仕様は `docs/gp_multidim_design.md`(T3-52)、数値計算の一般規則は `statistics_feature_design.md` §0(計算は Dart ローカル、Gemini は解釈のみ、点推定+不確実性のセット表示)が引き続き優先。

**本書に無いフィールド名・シート列名・閾値・画面IDを発明しないこと。** 疑義があれば実装を止めてユーザーに質問する。**本タスクで新しいシート列・GAS 変更・モデルのフィールド追加は一切発生しない**(既存データの読み取りと集計のみ)。

---

## 1. 目的とゴール

T3-50 のヒアリング結果「**現在の検証状況がわかると嬉しい**」に応える。

T3-52c で 030(抽出レシピ画面)に「レシピ探索」セクションができ、**これから試すべき条件**(推奨条件・EI最大点)は出るようになった。しかし「**自分がこれまで何をどれだけ試したのか**」「**探索空間のどこが手つかずなのか**」「**もう十分探索できたと言えるのか**」は一切見えない。T3-53 はこの「振り返り側」を足す。

### 終了条件(マスタープラン記載、そのまま)

> 探索対象の豆について、**試行回数・実測条件の分布・次の推奨条件・探索の進捗度合いが1画面で確認できる**

### タスク定義の表示案(4項目)と本書での対応

| タスク定義の項目 | 本書での実現 |
|---|---|
| ① 試行回数と評価スコアの推移(折れ線) | §7.3「スコアの推移」(fl_chart `LineChart`、実測系列+これまでの最高スコア系列) |
| ② 試した条件の分布(GPヒートマップ上に実測点を重ねる) | §7.4「試した条件の分布」(`GpHeatmap` に overlay 対応を追加、§5) |
| ③「次に試すと良い条件」カード | §7.2(T3-52c の EI 最大点をそのまま再掲+根拠を明示) |
| ④ 最適条件に到達したと言える状態かの判定 | §6「探索の進み具合」(EI 最大値による3段階判定) |

---

## 2. 配置の決定(タスク文の「配置場所は要検討」への回答)

**決定: 専用画面 `045 探索の検証状況` を新設する。030 のレシピ探索セクション内には統合しない。**

理由:

1. **030 のレシピ探索セクションは T3-52c で既に長い**(豆/ミルセレクタ + メソッド比較表 + 推奨条件カード + EI カード + ヒートマップ)。ここへ折れ線・試行一覧・進捗判定を足すと、030 の主目的(注湯ステップとタイマー)が画面の遥か下へ押し出される。
2. **検証状況は「豆単位の振り返り」であり、抽出直前の作業文脈とは目的が違う**。T3-50 で `seekOptimalConditions` を ON にした豆について「進み具合を確認する」という、腰を据えた閲覧行為。
3. **011(豆詳細)からの導線が自然に取れる**。豆を見ていて「この豆どこまで詰めたっけ」と思ったときに、030 を経由せず直行できる。

そのかわり **030 からも1タップで飛べるようにし、030 側の選択(豆・ミル・メソッド)を初期値として引き継ぐ**(§8)。これで「統合しない」ことによる分断を回避する。

### 画面ID

| 項目 | 値 |
|---|---|
| 画面ID | **`045`** |
| enum 識別子 | `AppScreen.explorationStatus` |
| 日本語名(`titleJa`) | **`探索の検証状況`** |
| ファイル | `lib/screens/exploration_status_screen.dart` |
| クラス | `ExplorationStatusScreen` |

`045` は `04x`(統計系: 040 統計情報 / 041 理論 / 042 稼働状況 / 043 Geminiモデル / 044 焙煎度ガイド)の続き番号で、`lib/routing/app_screen.dart` 現行の enum に未使用であることを確認済み(2026-07-31 時点の空き: `029, 032〜039, 045〜089`)。**着手時に `app_screen.dart` を再確認し、重複が無いことを必ず確かめること。**

---

## 3. 画面の入力(引数)と状態

```dart
class ExplorationStatusScreen extends ConsumerStatefulWidget {
  /// 遷移元で選択中だった豆(011 からは必ず指定、030 からも指定)。
  /// null または解決できない ID の場合は §7.1 の既定値ルールで決める。
  final String? initialBeanId;
  /// 遷移元で選択中だったミル。null なら §7.1 の既定値ルール。
  final String? initialGrinderId;
  /// 遷移元で選択中だったメソッド。null なら §7.1 の既定値ルール。
  final String? initialMethodId;

  const ExplorationStatusScreen({
    super.key,
    this.initialBeanId,
    this.initialGrinderId,
    this.initialMethodId,
  });
}
```

内部状態は `_selectedBeanId` / `_selectedGrinderId` / `_selectedMethodId` の3つのみ(`_GpExplorerSectionState` と同じ流儀)。`initState` で widget の引数を代入し、`build` 側で「選択肢に存在しなければ既定値へフォールバック」する(`gp_explorer_section.dart` 現行の `if (!selectable.any(...)) { ... }` パターンをそのまま踏襲)。

`screen_registry.dart` の引数なしエントリ(ギャラリー経由の表示)もあるため、**3引数すべて null でも成立しなければならない**。

---

## 4. 集計ロジック: `ExplorationStatusService`(新規)

**集計は必ずサービスへ切り出し、画面ウィジェットには置かない**(テスト可能性のため。`StatisticsService` / `GpService` と同じ方針)。

ファイル: **`lib/services/exploration_status_service.dart`**

### 4.1 型

```dart
/// 1回の試行(= この豆の抽出記録1件)。
class ExplorationTrial {
  final CoffeeRecord record;
  /// 1始まりの試行番号(brewedAt 昇順。同時刻は id の昇順で安定化する)。
  final int index;
  /// 正規化粒度 (0,1]。粒度が数値として読めない/ミルの挽き目調整段階が
  /// 未登録の場合は null。
  final double? grindNorm;
  /// 湯:豆比。CoffeeRecord.brewRatio をそのまま入れる(null 可)。
  final double? brewRatio;
  /// 条件4次元(湯温・比率・時間・正規化粒度)がすべて揃っているか。
  /// false の行は散布の重ね描き・ユニーク条件数の対象外(スコア推移には使う)。
  final bool hasFullCondition;
  /// この試行までの最高スコア(自分を含む累積最大)。
  final int bestSoFar;
}

/// この豆の探索サマリ。
class ExplorationSummary {
  /// brewedAt 昇順の全有効試行(scoreOverall > 0 のみ)。
  final List<ExplorationTrial> trials;
  /// hasFullCondition == true の試行のうち、条件キー(§4.3)が異なるものの数。
  final int uniqueConditionCount;
  /// 最高スコアの試行(trials が空なら null)。同点なら brewedAt が早い方。
  final ExplorationTrial? bestTrial;
  /// 平均 scoreOverall(trials が空なら 0.0)。
  final double meanScore;
  /// 最終試行日(trials.last.record.brewedAt。空なら null)。
  final DateTime? lastTriedAt;
  /// この豆の記録のうち scoreOverall <= 0 で除外した件数。
  final int unscoredCount;
  /// trials のうち hasFullCondition == false の件数(散布に出せない件数)。
  final int conditionIncompleteCount;
}

/// 探索の進み具合(§6)。
enum ExplorationProgress { early, midway, converged }
```

### 4.2 API

```dart
class ExplorationStatusService {
  /// [beanId] の豆についての探索サマリを作る。
  /// [grindStepsByGrinderId] は grinderId -> GrinderMaster.grindSteps。
  ExplorationSummary summarize(
    List<CoffeeRecord> records, {
    required String beanId,
    required Map<String, int> grindStepsByGrinderId,
  });

  /// EI の最大値から探索の進み具合を判定する(§6)。
  /// 戻り値の gauge は 0.0–1.0(ゲージ表示用)。
  ({ExplorationProgress level, double gauge}) judgeProgress(double eiMax);
}

final explorationStatusServiceProvider = Provider((ref) => ExplorationStatusService());
```

**日本語の表示文言はサービスに置かない**(enum → 文言のマッピングは画面側が持つ)。理由: 表示都合の変更でサービスのテストが壊れないようにするため。

### 4.3 行の採否・派生値の規則(実装が迷わないように全部書く)

`summarize` の処理順:

1. `records` から `r.beanId == beanId` の行だけ取る。
2. `r.scoreOverall <= 0` の行は **`trials` に入れず `unscoredCount` に数える**(評価が未入力の記録。スコア推移の軸が壊れるため)。
3. 残りを `brewedAt` の昇順に並べる。**同一 `brewedAt` の場合は `id` の昇順**でタイブレークして順序を安定させる(Sheets は同日複数記録がありうる)。
4. 各行について:
   - `grindNorm`: `double.tryParse(r.grindSize.trim())` を `clicks` とし、`clicks != null && clicks > 0` かつ `grindStepsByGrinderId[r.grinderId] != null` のときのみ `clicks / grindSteps` を代入。**`gNorm > 1.0` は `1.0` にクランプ**(`GpService.fitForMethod` と同じ扱い)。それ以外は `null`。
   - `brewRatio`: `r.brewRatio`(既存 getter)をそのまま。
   - `hasFullCondition`: `brewRatio != null && r.temperature > 0 && r.totalTime > 0 && grindNorm != null`。
   - `bestSoFar`: 先頭からの累積最大。
5. `uniqueConditionCount`: `hasFullCondition == true` の試行について、下記**条件キー**の重複を除いた数。

**条件キー(丸め規則。これ以外の丸めをしないこと)**

```
key = "${temperature.round()}|${(brewRatio! * 2).round()}|${(totalTime / 15).round()}|${clicks.round()}"
```

意味: 湯温 1℃ / 湯:豆比 0.5 / 総抽出時間 15秒 / 粒度は生クリック値(丸めなし、`clicks` は §4.3-4 の値)。この刻みは `GpService.optimize` の**細グリッドの刻みと一致させてある**(`gp_multidim_design.md` §5.4)ので、「グリッド上で見て同じ点かどうか」と一致する。粒度だけミルによって刻みが違うため生クリック値を使う。

6. `bestTrial`: `scoreOverall` の最大。同点なら `index` が小さい方(= 先に到達した試行)。
7. `meanScore`: `trials` の `scoreOverall` の単純平均(重み付けはしない)。

> **重要な注意(実装者向け)**: `summarize` は **`beanId` 一致の記録のみ**を見る。これは GP の学習集合(`fitForMethod` が産地・焙煎度・ミルで重み付けして**他の豆の記録も含める**)とは**別物**。両者を混同しないこと。画面上でもこの違いを明示する(§7.4 の凡例、§9 の注意書き)。

---

## 5. `GpHeatmap` の切り出しと overlay 対応

現在ヒートマップは `_GpExplorerSectionState._buildHeatmap` / `_labelCell` / `_valueCell` として **private**。045 でも同じものを使うため、**共通ウィジェットへ切り出して 030 側もそれを使うように置き換える**(コピペ二重管理を作らない)。

ファイル: **`lib/widgets/brew/gp_heatmap.dart`**

```dart
/// ヒートマップに重ねる実測点。
class GpHeatmapPoint {
  final double temperature;
  final double brewRatio;
  final int score;
  /// true = 表示中の豆自身の記録、false = 参考(現状は未使用、将来の拡張用)。
  final bool isPrimary;
}

/// 予測総合評価マップ(湯温×湯:豆比。時間・粒度は固定)。
/// [overlay] を渡すと、実測点があるセルに件数バッジと枠を描く(T3-53)。
class GpHeatmap extends StatelessWidget {
  final GpModel model;
  final int fixedTime;
  final double fixedGrind;
  final List<GpHeatmapPoint> overlay; // 既定 const []
  const GpHeatmap({...});
}
```

- 軸は現行のまま: 湯温 `[80, 85, 90, 95]`、比率 `[14, 15, 16, 17, 18]`(4×5=**20セル**)。
- セルの色・μ表示・最大値セルの太枠は**現行の見た目を変えない**(030 の既存 widget テストを壊さないため)。
- **セル ↔ 実測点の対応規則**: 点 `p` はセル `(t_c, r_c)` に属する ⟺ `|p.temperature - t_c| <= 2.5 && |p.brewRatio - r_c| <= 0.5`。
  (軸の刻みの半分。湯温は 5℃刻み → 2.5、比率は 1.0 刻み → 0.5。**同じ点が複数セルに属することは境界値でのみ起こりうるが、その場合は両方に数える**。件数バッジは「その付近で試した回数」の目安なので厳密な排他分割は不要。)
- 実測点があるセル: セル右下に小さく `●n`(n=件数、fontSize 9、色 `kEspresso` または `Colors.white`(背景が濃いとき、現行 `_valueCell` の `textColor` と同じ判定))を重ねる。
- 実測点が **0件のセル**: 追加の描画はしない(斜線・ハッチは入れない)。「未試行」はバッジの有無で読み取れるうえ、20セル中の実測セル数を §7.4 のキャプションに数字で書くため。
- `overlay` が空(030 からの呼び出し)のときは**現行と完全に同じ描画**になること。

### 030 側の変更

`gp_explorer_section.dart` の `_buildHeatmap` / `_labelCell` / `_valueCell` を削除し、`GpHeatmap(model: ..., fixedTime: bestX.s, fixedGrind: bestX.g)` を呼ぶだけにする。**キャプション行(`予測総合評価マップ (...)`)は 030 側に残す**(045 側は別文言を使うため)。

---

## 6. 「探索の進み具合」判定(タスク定義④)

### 6.1 判定に使う値

**表示中メソッドの GP モデルについて `GpService.optimize(model)`(`refine: true`)が返す `explore.ei`** を `eiMax` とする。これは探索グリッド(粗+細)上での期待改善量の最大値。

`expectedImprovement` の単位は **総合評価スコア(1〜10)と同じ**(「今の最高値 `fStar` をどれだけ上回れると期待できるか」の期待値、`xi = 0.01`)。したがって閾値を点数の感覚で決められる。

### 6.2 閾値(この値を使うこと。変えない)

| `eiMax` | `ExplorationProgress` | 画面の文言(画面側が持つ) |
|---|---|---|
| `>= 0.20` | `early` | **まだ試す価値のある条件が残っています** |
| `0.05` 以上 `0.20` 未満 | `midway` | **かなり探索できています(あと少し)** |
| `< 0.05` | `converged` | **ほぼ探索し尽くしました** |

根拠(コメントとして実装に残すこと):

- 総合評価は 1〜10 の整数入力なので、**期待改善量 0.05 点は入力粒度(1点)の 1/20** であり、実質「これ以上グリッド上に伸びしろが見えない」状態。
- 0.20 点は「20回に4回くらいは今の最高を上回る」程度の期待値で、まだ試す動機がある水準。
- LCB や事後分散そのものではなく EI を使うのは、**EI が「未試行領域の広さ(分散)」と「そこが良さそうか(平均)」を1つの量に統合している**ため、タスク定義④「最適条件に到達したと言えるか」に最も素直に対応する。

### 6.3 ゲージ

```
gauge = (1.0 - min(eiMax, 1.0) / 1.0).clamp(0.0, 1.0)
```

`eiMax = 1.0`(総合評価1点分の伸びしろ)を「探索の入り口」とみなす線形写像。**あくまで目安**なので、画面では `LinearProgressIndicator` の下に「目安」と明記し、**必ず `eiMax` の実数値も併記する**(`statistics_feature_design.md` §0「点推定+不確実性をセット表示」の精神)。パーセント表示はしない(疑似的な精度を与えないため)。

### 6.4 GP が無い場合

**表示中メソッドの GP モデルが `null`(最小データ条件未達)の場合、この判定は行わない。** 「まだ判定できません(この豆に近い記録が十分に集まっているメソッドがまだありません)。」と表示する。スコア推移(§7.3)と試行一覧(§7.5)は GP 非依存なので**引き続き表示する**。

---

## 7. 画面構成(045)

`MockScreenScaffold(screen: AppScreen.explorationStatus, showSettingsAction: false, maxWidth: 720, children: [...])` を使う(044 `RoastGuideScreen` と同じ流儀)。各ブロックは `FormSection`(`lib/screens/create/create_form_widgets.dart`)で囲む。色は既存の `kAccent` / `kCream` / `kMocha` / `kEspresso` のみを使う。

上から順に:

### 7.1 セレクタ(`FormSection` 外、先頭)

| 項目 | 仕様 |
|---|---|
| **豆** | `beanMasterProvider` から `originId` が空でなく `roastOrdinalMap` に `roastLevel` があるもの。並びは **`seekOptimalConditions == true` を先頭**、その後は名前昇順。ラベル先頭に `★`。既定値 = `initialBeanId` が選択肢にあればそれ、無ければ先頭 |
| **ミル** | `grinderMasterProvider` から `grindSteps != null` のもの。既定値 = `initialGrinderId` が選択肢にあればそれ、無ければ**抽出記録での使用回数が最多**のミル(`gp_explorer_section.dart` 現行ロジックと同一) |
| **メソッド** | `fitForMethod` が非 null を返したメソッドのみ。並びは **`GpService.optimize(model, refine: false)` の μ 降順**(`gp_multidim_design.md` §4.4 と同じ)。既定値 = `initialMethodId` が候補にあればそれ、無ければ先頭。**候補が0件のときはドロップダウン自体を出さず**、§6.4 の文言を出す |

キャプション: `★ = 最適条件探索の対象に設定した豆`(030 と同じ)。

> **地雷**: `seekOptimalConditions` は 2026-07-30 時点で本番28件すべて未回答(`null`)。**★でフィルタしてはいけない**(画面が常に空になる)。並び順と印だけに使う。

### 7.2 「探索サマリ」+「次に試すと良い条件」

`FormSection(icon: Icons.explore_outlined, title: '探索サマリ')`

- 1行目: `試行 N 回 / 条件の種類 M 通り`(`trials.length` と `uniqueConditionCount`)
- 2行目: `最高スコア X 点(YYYY/MM/DD、湯温 90℃ / 湯:豆 1:15.5 / 時間 2:30 / 粒度 92 クリック)`
  - `bestTrial.hasFullCondition == false` のときは条件部分を省き `(YYYY/MM/DD、条件の一部が未記録)` とする。
- 3行目: `平均スコア X.X 点 / 最終試行 YYYY/MM/DD`
- `unscoredCount > 0` のとき薄字1行: `評価が未入力の N 件は集計から除外しました。`
- `conditionIncompleteCount > 0` のとき薄字1行: `条件(湯温・比率・時間・粒度)の一部が未記録の N 件は条件の分布に表示できません。`

続けて **「次に試すと良い条件」カード**(`kCream` 背景、`kAccent` 枠。030 の EI カードと同じ見た目):

```
次に試すと良い条件 — <メソッド名>
湯温 86℃ / 湯:豆 1:17.0 / 時間 3:00 / 粒度 108 クリック (Kingrinder K6・180段階中)
予測スコア 7.2 [5.8, 8.6] (95%予測区間) / 期待改善量 0.31
```

- 条件は `optimize(model).exploreX` を選択中ミルのクリック数に逆変換して表示(`clicks = (g * grindSteps).round()`。**正規化値 `gNorm` は画面に出さない**)。
- 予測区間は `totalSd = sqrt(sd² + σ_n²)`、`μ ± 1.96·totalSd` を `0.0–10.0` にクランプ(既存と同じ)。
- 期待改善量は `explore.ei` を小数2桁。

### 7.3 「スコアの推移」(タスク定義①)

`FormSection(icon: Icons.show_chart, title: 'スコアの推移')`

fl_chart の `LineChart`。高さ 220。

| 系列 | 内容 | 見た目 |
|---|---|---|
| 実測 | x = `index`(1..N)、y = `scoreOverall` | 実線 `kAccent`、`FlDotData(show: true)` で点も出す |
| これまでの最高 | x = `index`、y = `bestSoFar` | 破線 `kMocha`(`dashArray: [4, 3]`)、点なし |

- y軸: `minY: 0, maxY: 10`、目盛り 2 刻み。
- x軸: 試行番号。`N <= 10` なら全目盛り、`N > 10` なら `(N / 5).ceil()` 刻みで間引く(ラベル重なり防止)。
- 凡例は チャート下に小さな色見本+ラベル(`実測` / `これまでの最高`)を `Row` で置く。
- **`trials.length < 2` のときはチャートを描かず**、`記録が2件以上になるとスコアの推移を表示します。` と表示する(1点だけの折れ線は情報量ゼロで、fl_chart の軸計算も不安定になるため)。
- タップ/ツールチップは実装しない(`LineTouchData(enabled: false)`)。モバイルでのスクロール阻害を避ける。

### 7.4 「試した条件の分布」(タスク定義②)

`FormSection(icon: Icons.grid_on_outlined, title: '試した条件の分布')`

- 見出し行(キャプション):
  `予測総合評価マップ (<メソッド名> / 時間 <推奨点の時間>・粒度 <推奨点のクリック数> クリック 固定)`
  ※ 固定値は `optimize(model).bestX`(μ最大点)の `s` と `g` を使う。030 と同じ。
- `GpHeatmap(model: model, fixedTime: bestX.s, fixedGrind: bestX.g, overlay: points)`
  - `points` = `summary.trials` のうち `hasFullCondition == true` の行を `GpHeatmapPoint(temperature: r.temperature, brewRatio: brewRatio!, score: r.scoreOverall, isPrimary: true)` に写像したもの。
- ヒートマップ直下に**必ず**2行:
  - `●n = その条件付近で試した回数(この豆の記録のみ)`
  - `湯温×比率の20マス中、実測があるのは K マスです。`(K = 1件以上の点が属したセル数)
- さらに薄字で1行(**混同を防ぐための注意書き、省略不可**):
  `色は予測値です。産地・焙煎度が近い他の豆の記録も学習に使っているため、●が無いマスにも予測値が出ます。`

### 7.5 「試行の一覧」

`FormSection(icon: Icons.list_alt_outlined, title: '試行の一覧')`

`Table`。**新しい順(`index` 降順)**。列:

| 列 | 内容 |
|---|---|
| 日付 | `yyyy/MM/dd`(`intl` の `DateFormat`) |
| メソッド | `methodMasterProvider` から `record.methodId` を名前に解決。未解決なら `-` |
| 条件 | `90℃ / 1:15.5 / 2:30 / 92cl`。欠測部分は `-`(例: 粒度が読めないなら `92cl` の代わりに `-`) |
| 点 | `scoreOverall` |

- 先頭 **10件** を常時表示。11件以上ある場合は下に `ExpansionTile('すべての試行を表示 (N件)')` を置き、その中に全件を出す。
- 粒度のクリック数は `record.grindSize` の**生の値**をそのまま出す(その記録を取ったミルが選択中ミルと違う可能性があるため、正規化・逆変換をしない)。ミルが選択中と異なる行は日付の右に `別ミル` の小さなチップを付ける。

### 7.6 空状態

| 状況 | 表示 |
|---|---|
| 選択可能な豆が無い | `産地・焙煎度が登録された豆がまだありません(豆マスタで産地と焙煎度を登録すると探索できます)。`(030 と同一文言) |
| 選択可能なミルが無い | `挽き目調整段階が登録されたミルがまだありません(ミルマスタで登録すると探索できます)。`(030 と同一文言) |
| `summary.trials` が空 | `この豆の抽出記録がまだありません。抽出して評価を登録すると、ここに検証状況が表示されます。` を出し、§7.3〜§7.5 は描かない(§7.2 の「次に試すと良い条件」は GP があれば出す) |
| GP候補メソッドが0件 | §6.4 の文言。§7.2 の EI カード・§7.4 は描かない。§7.3・§7.5 は描く |

---

## 8. 導線(2箇所)

### 8.1 030(抽出レシピ)のレシピ探索セクションから

`gp_explorer_section.dart` の `_buildRecommendation` 内、**EI カードの直下**(ヒートマップの上)に `TextButton.icon` を1つ置く。

```
[icon: Icons.history_toggle_off]  この豆の検証状況を見る
```

押下時:

```dart
debugPrint('[Antigravity] Action: 検証状況画面(045)へ遷移 beanId=$_selectedBeanId methodId=$_selectedMethodId');
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ExplorationStatusScreen(
      initialBeanId: _selectedBeanId,
      initialGrinderId: _selectedGrinderId,
      initialMethodId: _selectedMethodId,
    ),
  ),
);
```

### 8.2 011(豆詳細)から

`bean_detail_screen.dart` の `extraSections` に、**「在庫・購入」セクションの直後**へ新しい `FormSection` を追加する。

```dart
FormSection(
  icon: Icons.explore_outlined,
  title: '最適条件の探索',
  children: [ /* 説明1行 + ボタン */ ],
)
```

- 説明1行(`fontSize: 12, color: kMocha`):
  - `currentBean.seekOptimalConditions == true` のとき → `この豆は最適条件の探索対象です。`
  - それ以外(`false` / `null`)のとき → `この豆は探索対象に設定されていません(編集画面から設定できます)。`
- ボタン `OutlinedButton`「検証状況を見る」。**`seekOptimalConditions` の値にかかわらず常に押せる**(本番は全件 `null` のため。§7.1 の地雷と同じ理由)。
- 遷移: `ExplorationStatusScreen(initialBeanId: currentBean.id)`(ミル・メソッドは渡さない → 045 側の既定値ルールで決まる)。
- ログ: `debugPrint('[Antigravity] Action: 豆詳細011から検証状況画面(045)へ遷移 (id=${currentBean.id})');`

### 8.3 ルーティング登録

1. `lib/routing/app_screen.dart` の enum に `explorationStatus('045', '探索の検証状況'),` を **`roastGuide` の直後・`settings` の前**に追加。
2. `lib/routing/screen_registry.dart` の `switch` に `case AppScreen.explorationStatus: return const ExplorationStatusScreen();` を追加(**switch は網羅的なので、追加し忘れるとコンパイルエラーになる**=気付ける)。
3. `topLevelTabs` には**追加しない**(ボトムナビ/レールには出さない)。

---

## 9. 理論ページ(041)への追記

`lib/screens/stats_theory_screen.dart` の `StatsTheorySection.gp` の節末尾に、段落を2つ追加する(**enum に新しい section は足さない**)。

1. **EI(期待改善量)とは何か**: 「今の最高スコアをどれだけ上回れそうか」の期待値であること、未試行で不確実な場所ほど大きくなること、これが小さくなったら「探索し尽くした」と読めること。§6.2 の3段階の閾値(0.20 / 0.05)とその意味を明記。
2. **ヒートマップの色と ● の違い**: 色は GP の予測値(産地・焙煎度が近い他の豆の記録も学習に使う)、● はこの豆で実際に試した回数。**●が無いマスに予測値が出るのは異常ではない**こと。

045 のセクション見出し(§7.2)に `StatsTheoryLink(section: StatsTheorySection.gp)` を `trailing` として付ける(030 と同じ)。

---

## 10. テスト仕様

### 10.1 ユニットテスト: `test/exploration_status_service_test.dart`(新規、最低6件)

| # | 対象 | 内容 |
|---|---|---|
| 1 | `summarize` の行フィルタ | 他の豆の記録・`scoreOverall == 0` の記録が `trials` に入らず、後者が `unscoredCount` に数えられる |
| 2 | 並び順と `index` | `brewedAt` 昇順で `index` が 1..N になる。同一 `brewedAt` は `id` 昇順で安定する |
| 3 | `bestSoFar` | スコア `[6, 8, 7, 9]` → `bestSoFar` が `[6, 8, 8, 9]`。`bestTrial.index == 4` |
| 4 | `grindNorm` | `grindSize: '90'`・`grindSteps: 180` → `0.5`。`grindSize: '200'`・`grindSteps: 180` → **`1.0` にクランプ**。`grindSize: 'abc'` / ミル未登録 → `null` かつ `hasFullCondition == false` |
| 5 | `uniqueConditionCount` | 湯温 90.4 と 90.0(→ 同じ 90)、比率 15.2 と 15.3(→ `*2` して丸めると同じ 30)、時間 150 と 158(→ `/15` して丸めると同じ 10)の3組が**同一条件として1通りに畳まれる**。湯温 90 と 91 は別 |
| 6 | `judgeProgress` | `0.30` → `early` / `0.10` → `midway` / `0.01` → `converged`。境界 `0.20` は `early`、`0.05` は `midway`。`gauge` は `eiMax=1.0` で `0.0`、`eiMax=0.0` で `1.0`、`eiMax=2.0` で `0.0`(クランプ) |

### 10.2 ウィジェットテスト: `test/exploration_status_screen_test.dart`(新規、最低5件)

`test/gp_explorer_section_test.dart` の `_record` ヘルパと `helpers/fake_master_notifiers.dart` をそのまま流用する(記録8件で GP が成立する構成が既にある)。

| # | 内容 |
|---|---|
| 1 | 記録が十分にあるとき、`探索サマリ` / `次に試すと良い条件` / `スコアの推移` / `試した条件の分布` / `試行の一覧` の5見出しがすべて出る |
| 2 | `initialBeanId` / `initialMethodId` を渡すと、その豆・メソッドが選択された状態で開く |
| 3 | 該当豆の記録が0件のとき `この豆の抽出記録がまだありません` が出て、スコア推移・試行一覧が描かれない |
| 4 | 記録が1件だけのとき `記録が2件以上になるとスコアの推移を表示します` が出る |
| 5 | モバイル幅(390×844)でオーバーフローしない(`tester.takeException()` が null。T3-54b/T3-52c と同じ流儀) |

### 10.3 既存テストへの影響

- `test/gp_explorer_section_test.dart`: `GpHeatmap` 切り出し後も**見た目・文言は不変**なので、5件すべて無修正でパスすること。**パスしない場合は切り出しが等価でない**ので、テストを直すのではなく実装を直す。
- 現行 **324件**が全パスすること。

---

## 11. 実装タスクへの分解

**T3-53 は下記4タスクに分解する。順序: a と b は並行可 → c → d。すべて Sonnet 5 で実施可能。**

| ID | 内容 | 終了条件 | 依存 | サイズ |
|---|---|---|---|---|
| **T3-53a** | §5 のヒートマップ切り出し。`lib/widgets/brew/gp_heatmap.dart` に `GpHeatmap` / `GpHeatmapPoint` を新設(overlay の件数バッジ・セル対応規則を含む)、`gp_explorer_section.dart` の private 実装を削除して差し替え | `flutter analyze` 新規issue 0、`flutter test` 全324件パス(`gp_explorer_section_test.dart` を**無修正で**通す) | なし | S |
| **T3-53b** | §4・§6 の `ExplorationStatusService` 新設(`summarize` / `judgeProgress` / provider)。§10.1 のユニットテスト6件を追加 | `flutter test` 全パス(既存324 + 新規6) | なし | M |
| **T3-53c** | §3・§7・§8 の 045 画面新設(`exploration_status_screen.dart`)、`app_screen.dart` / `screen_registry.dart` への登録、030 と 011 の導線2箇所。§10.2 のウィジェットテスト5件を追加 | 011 と 030 から 045 へ遷移でき、探索サマリ・次に試すと良い条件・スコア推移・条件の分布・試行一覧が1画面で確認できる | T3-53a, T3-53b | L |
| **T3-53d** | §9 の理論ページ(041)追記。`docs/改修マスタープラン.md` §4 の画面インベントリ表に `045` の行を追加。`statistics_feature_design.md` §7.5 の末尾に本書へのポインタを1行追加 | 設計書・理論ページと実装の記述が一致 | T3-53c | S |

---

## 12. 実装時の地雷(既知、必ず読むこと)

1. **`seekOptimalConditions` は本番28件すべて `null`**。★で**絞り込むと画面が常に空になる**(`gp_multidim_design.md` §10-4 と同じ)。並び順と印にのみ使う。
2. **`summarize`(beanId 一致)と GP 学習集合(産地・焙煎度・ミルで重み付けした他豆込み)は別物**。試行回数と `model.nRows` / `model.nEff` は一致しない。画面でも §7.4 の注意書きで明示すること。**「試行 N 回」に `nRows` を使わない。**
3. **`GpService.optimize` は `refine: true` だと最大 1575 点を評価する**。045 では**表示中メソッドについて1回だけ**呼ぶこと。`build` のたびにメソッド候補全件を `refine: true` で回すと Web で数秒フリーズする。メソッド一覧の並び替えは `refine: false` を使う(030 と同じ使い分け)。
4. **`GpModel` の `fStar` は学習集合の最大スコア**であって「この豆の最高スコア」ではない。§7.2 の「期待改善量」の基準点がサマリの「最高スコア」とずれることがある。**これは仕様**(GP の定義どおり)。混乱を避けるため、EI カードには「この豆の最高スコア」を書かない。
5. **`grindSize` は `String`**(`_parseString` 経由)。数値として使うときは必ず `double.tryParse(...trim())`。空文字・全角数字は解析できず `null` になる。
6. **`brewRatio` は保存されない getter**(`CoffeeRecord` の計算プロパティ)。`totalWater` / `beanWeight` が 0 のとき `null` になりうる。必ず null チェックする。
7. **`roastOrdinalMap` は旧5段階表記と新8段階表記の両方を吸収する**。独自の変換を書かない(`gp_multidim_design.md` §10-5)。
8. **`screen_registry.dart` の `switch` は網羅的**。enum に足したら必ず `case` を足す(足さないとコンパイルエラー=気付ける。良い方のガード)。
9. **`fl_chart` は 0.69.0**。`LineChartBarData` の破線は `dashArray`、点の表示は `FlDotData`。バージョン差で API 名が違うので、既存の使用箇所(`lib/widgets/statistics/` 配下)の書き方に合わせること。**新しいチャートライブラリを追加しない。**
10. **マスター詳細画面は編集→保存→pop 直後に表示が更新されない**(`rules/lessons_archive.md` L89)。011 に導線を足した後の本番確認では、一覧に戻って再訪問するかフルリロードすること。
11. **`claude-in-chrome` の一覧グリッドのスクロールは不安定**(同 L87)。045 の本番確認で粘らないこと。widget テスト+コンソールログに切り替える。
12. **GAS の変更は不要**。新しいシート列を作らないので `EXISTING_SHEET_EXTRA_COLUMNS` の変更も `clasp push` も要らない。
