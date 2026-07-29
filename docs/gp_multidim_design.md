# T3-52 設計書: F4 レシピ探索の多次元化(粒度追加 + メソッド別GP)

作成: 2026-07-30 / 作成者: 上位モデル(Opus 5)/ 対象タスク: **T3-52**
正本の位置づけ: **本書は `statistics_feature_design.md` §2.3・§7.5・§1.3・§9.5 の T3-52 による改訂内容を定義する差分設計書**。数値計算の一般規則(計算はDartローカル、Geminiは解釈のみ、点推定+不確実性のセット表示)は引き続き `statistics_feature_design.md` §0 が優先。

実装は本書のとおり行えば設計判断が不要な粒度まで確定させてある。**本書に無いフィールド名・シート列名・閾値を発明しないこと。** 疑義があれば実装を止めてユーザーに質問する。

---

## 1. 目的とゴール

T3-50 のヒアリング結果「同じ豆で最適なメソッド・湯温・粒度を知りたい」に応える。

現状 `GpService` の入力は **湯温・brew ratio・抽出時間の3次元**のみで、ユーザーが最も知りたい **粒度・メソッド** が探索対象外になっている(`gp_service.dart` の `xsRaw.add([r.temperature, ratio, r.totalTime])`)。

**終了条件(マスタープラン記載)**: 030 のレシピ探索で、豆を選ぶと「推奨メソッド・湯温・粒度」が根拠(予測スコアと不確実性)付きで提示される。

対応方針は2本立て:

- **粒度** → GP の4つ目の連続次元として追加する(§3)。
- **メソッド** → カテゴリ変数なので連続次元に入れず、**メソッドごとに別々のGPをフィットして最良予測スコアを比較**する(§4)。

---

## 2. 事前に判明した既存バグ(T3-52 の前提、必ず先に直す)

本設計の実装前に**本番データを実測して発見した2件の潜在バグ**。どちらも「キー名が本番シートの列名と一致しておらず、対象フィールドが常に `null` になっている」もの。**粒度の正規化は `GrinderMaster.grindRange` に依存するため、これを直さない限り T3-52 は原理的に動かない。**

### 2.1 `GrinderMaster.grindRange` が常に null

| | 値 |
|---|---|
| 現状のキー名 | `lib/services/sheets_service.dart` `getGrinders()` の keyMap に `'挽き目範囲': 'grindRange'` |
| 本番 `mill_master` の実際の列名 | **`挽き目調整段階`** |
| 結果 | キーが一致せず `grindRange` は常に `null` |
| 逆マップ側 | 同ファイル `_reverseMapGrinder`(現状 690 行目付近)も `'grindRange': '挽き目範囲'` → 同じく要修正 |

本番 `mill_master` の実データ(2026-07-30 実測、全3件):

| ミルID | ミル名 | 挽き目調整段階 |
|---|---|---|
| `M001` | Timemore c3 pro | 20 |
| `M002` | Kingrinder K6 | 180 |
| `916e917a` | ドリップバッグ | 0 |

### 2.2 `MethodMaster.grindSize` が常に null

| | 値 |
|---|---|
| 現状のキー名 | `getMethods()` の keyMap に `'粒度': 'grindSize'` |
| 本番 `methods_master` の実際の列名 | **`挽き目（Kingrinder K6）`**(丸括弧は**全角**。`（`/`）` を半角で書くと一致しない) |
| 逆マップ側 | `_reverseMapMethod`(現状 708 行目付近)の `'grindSize': '粒度'` も要修正 |

### 2.3 型ガード(修正すると新たに顕在化するクラッシュ)

`GrinderMaster.grindRange` も `MethodMaster.grindSize` も宣言は `String?` だが、**本番シートの当該列は数値**(20 / 180 / 0、80 / 95 など)。キー名を直すと Sheets から `int`/`double` が流れ込み、`type 'int' is not a subtype of type 'String?'` で `fromJson` が落ちる(CLAUDE.md「ID/外部データは `.toString()` で明示キャスト」の典型例。`FilterMaster.size` が同じ理由で `@JsonKey(fromJson: _parseString)` を持っているので、**同じパターンをそのまま流用する**)。

> **注意**: `_fetchData` は行ごとに try/catch していて例外は握り潰されログに出るだけなので、**一覧が黙って空になる**形で失敗する。「動いているように見えるが値が入らない」に気付きにくい。

### 2.4 派生ヘルパ(新規追加)

`GrinderMaster` に、クリック総段階数を数値で得るゲッターを追加する:

```dart
/// 挽き目調整段階を数値で返す。未設定・0・解析不能なら null。
/// (Sheetsは "20" / "180" / "0" のように数値を返すが、フィールドは
///  後方互換のため String? のまま保持している。)
int? get grindSteps {
  final v = double.tryParse((grindRange ?? '').trim());
  if (v == null || v <= 0) return null;
  return v.round();
}
```

`grindSteps == null` のミル(= ドリップバッグ)は **GP の学習対象からも目標ミルの選択肢からも除外**する(§3.2)。

---

## 3. 粒度を4次元目に追加する

### 3.1 正規化(必須)

粒度の目盛りはミルごとにスケールが違う(20段階 / 180段階)ため、**生のクリック数をそのまま投入してはならない**。正規化:

```
gNorm = clicks / grindSteps        ∈ (0, 1]
clicks    = CoffeeRecord.grindSize を double に解析した値
grindSteps = その記録の grinderId に対応する GrinderMaster.grindSteps
```

`CoffeeRecord.grindSize` は `String` なので `double.tryParse` で解析する。解析不能・`<= 0`・`grinderId` がマスタに無い・`grindSteps == null` の行は **GP 学習から除外**する(件数を UI に表示する。§5.4)。

逆変換(推薦値をユーザーに見せるとき):

```
clicks = (gNorm * targetGrindSteps).round()
```

### 3.2 ミル間比較可能性の限界と、その扱い(重要)

**線形正規化はミル間の物理的な粒径一致を保証しない。** 本番実測(2026-07-30、有効161件)では正規化後の分布がほとんど重ならない:

| ミル | 生クリック範囲 | 正規化後 `gNorm` |
|---|---|---|
| M001 (Timemore c3 pro, 20段階) | 13 – 18 | 0.65 – 0.90 |
| M002 (Kingrinder K6, 180段階) | 65 – 125 | 0.36 – 0.69 |

このまま混ぜると GP は「M001 の記録＝粗挽き / M002 の記録＝細挽き」と誤って学習する。かといってミルで完全分割するとデータ量が足りない(M001 は49件、うちメソッド別では最大19件)。

**採用する対処(既存の重み付けの枠組みに乗せる)**: 目標ミルと異なるミルの記録には、既存の産地・焙煎度の重みに **ミル不一致係数 0.5 を乗算**する。

```
w = w_originRoast × (record.grinderId == targetGrinderId ? 1.0 : 0.5)
w_originRoast = 1.0  (originId一致 かつ roastOrdinal一致)
              = 0.5  (originId一致 かつ |Δroast| <= 1)
              = 0.2  (それ以外)
```

これは既存設計の「信頼度の低いデータほどノイズ大として扱う」(`σ_n²/wᵢ`)という考え方の素直な拡張であり、新しい機構を導入しない。**この限界は `statistics_feature_design.md` §11(既知の限界)に追記する**(§7)。

---

## 4. メソッドはカテゴリ変数 → メソッド別GP

### 4.1 方式

`methodId` ごとに学習データを分割し、**メソッド1つにつき GP を1つフィット**する。各メソッドについて探索グリッド上の最良予測 μ とその不確実性を求め、**メソッド横断でランキングして「このメソッドが有望」と提示**する。

μ は「同じ 1–10 の総合評価スケール上の予測値」なので、別々にフィットした GP 間でも比較してよい(各 GP は定数平均 + ゼロ平均GP なので、`yMean` が違っても予測値自体は同じ尺度)。

### 4.2 最小データ条件の見直し(§1.3 F4 の改訂)

**旧**: 全メソッドをプールして `n_eff ≥ 10`(d=3)。
**新**: メソッドごとに **`n_eff ≥ 6.0` かつ 生データ行数 `n ≥ 8`**。

改訂理由(設計書に理由コメントとして残すこと):

1. **旧閾値のままでは機能が成立しない。** 本番実測では、どの豆を選んでも `n_eff ≥ 10` を満たすメソッドは 1〜2 件しか無く、「メソッドを比較する」という T3-52 の目的が達成できない。

   実測値(2026-07-30、有効161件・4次元の有効行のみ):

   | 対象 (originId / 焙煎度) | `77443f2b` | `method001` | `607358c0` | `2b92984d` |
   |---|---|---|---|---|
   | origin_5 / シティ | 15.9 | 6.5 | 11.5 | 3.8 |
   | origin_5 / ハイ | 18.1 | 8.3 | 8.9 | 4.7 |
   | origin_15 / ハイ | 12.0 | 9.2 | 5.4 | 3.8 |
   | origin_1 / シナモン | 12.0 | 5.6 | 4.8 | 3.8 |

   (生の行数は `77443f2b`=60, `method001`=28, `607358c0`=24, `2b92984d`=19。残る9メソッドは 7件以下で `n ≥ 8` により自動的に対象外。)

2. **GP はノンパラメトリックで自己正則化するため、データ不足時の劣化が穏やか。** 点が少ないと周辺尤度グリッドが大きい `σ_n` を選び、事後平均は定数平均に回帰し、事後分散は広がる。すなわち「自信満々に間違える」のではなく「自信が無いと表示される」方向に壊れる。回帰(F1)の `n ≥ 5×説明変数` のような厳しい下限は GP には当てはまらない。

3. **不確実性を必ず併記し、確信度バッジで補う**ので、低 n のフィットをユーザーが過信しない(§5.2、および `statistics_feature_design.md` §0「点推定+不確実性をセット表示」)。

**どのメソッドも条件を満たさない場合**は、既存の固定文言をそのまま表示する:
> 「この属性の推薦にはデータが不足しています(この産地×焙煎度に近い記録が10件相当に達していません)。」

※ この文言中の「10件相当」は閾値変更に合わせて **「この豆に近い記録が十分に集まっているメソッドがまだありません。」** に差し替える(固定文言の改訂も本設計の一部)。

### 4.3 確信度バッジ

| n_eff | バッジ表示 | 色 |
|---|---|---|
| ≥ 12.0 | `確信度: 高` | `kAccent` |
| 8.0 以上 12.0 未満 | `確信度: 中` | `kMocha` |
| 6.0 以上 8.0 未満 | `確信度: 低` | `kMocha`(薄) |

### 4.4 ランキング規則

- **並び順**: 探索グリッド上の最良予測 μ の**降順**。
- **同点時(μ の差が 0.05 未満)**: `n_eff` の降順を優先する。
- **「有望」マーク**: 先頭1件のみに付ける。
- LCB(下側信頼限界)での並べ替えは**採用しない**(常に高 n のメソッドが勝ち、探索の意味が薄れるため)。代わりに μ と 95% 予測区間と確信度バッジを並記して判断材料をそのまま見せる。

---

## 5. API 仕様(`lib/services/gp_service.dart`)

### 5.1 型

```dart
/// 探索空間上の1点。g は正規化粒度 (0,1]。
typedef GpPoint = ({double t, double r, int s, double g});
```

`GpModel` は**フィールド構成を変更しない**(`xTrain` 等が 4 列になるだけ)。ただし以下2つを追加する:

```dart
final int nRows;        // 学習に使った生データ行数 (最小データ条件の n)
final String methodId;  // このモデルがどのメソッドのものか (UI のランキング表示用)
```

### 5.2 メソッド別フィット(新規、既存 `fit` を置き換える)

```dart
/// [methodId] のメソッドについて、(originId, roastOrdinal, targetGrinderId) 向けに
/// 重み付き GP をフィットする。最小データ条件 (n_eff >= 6.0 かつ nRows >= 8) を
/// 満たさない場合は null。
GpModel? fitForMethod(
  List<CoffeeRecord> records, {
  required String methodId,
  required String originId,
  required double roastOrdinal,
  required String targetGrinderId,
  required Map<String, int> grindStepsByGrinderId, // grinderId -> GrinderMaster.grindSteps
});
```

行の採否と重み:

1. `r.methodId != methodId` → 除外。
2. `r.scoreOverall <= 0` / `r.brewRatio == null` / `r.temperature <= 0` / `r.totalTime <= 0` → 除外(既存条件を踏襲)。
3. `double.tryParse(r.grindSize)` が null または `<= 0` → 除外。
4. `grindStepsByGrinderId[r.grinderId]` が null → 除外(ドリップバッグ・未知ミル)。
5. `gNorm = clicks / grindSteps`。`gNorm > 1.0` の場合は `1.0` にクランプ(入力ミス対策)。
6. 重みは §3.2 の式。
7. `xsRaw.add([r.temperature, ratio, r.totalTime.toDouble(), gNorm])`。

`nEff = Σwᵢ`、`nRows = xsRaw.length`。`nEff < 6.0 || nRows < 8` なら `null`。

> **既存 `fit()` は削除する**(3次元前提で呼び出し元が `gp_explorer_section.dart` のみのため)。`fitWithParams` はテスト用の入口としてシグネチャそのまま残す(次元数は `xsRaw[0].length` から動的に決まるので変更不要)。

### 5.3 予測

```dart
GpPrediction predict(
  GpModel model, double temperature, double brewRatio, int totalTimeSec, double grindNorm);
```

`xRaw = [temperature, brewRatio, totalTimeSec.toDouble(), grindNorm]` に変わるだけで、以降のロジック(標準化・`kStar`・Cholesky・EI)は現行のまま。

### 5.4 探索グリッド(2段階、§2.3.3 の改訂)

4次元の全探索は計算量が爆発する(旧: 17×9×9=1377点 → 素朴に拡張すると 1万9千点/メソッド × 最大4メソッド)。Web で数秒フリーズするため **2段階探索**にする。

**粗グリッド(750点/メソッド)** — ランキング用:

| 次元 | 範囲 | 刻み | 点数 |
|---|---|---|---|
| 湯温 t | 80 – 96 | 4 | 5 |
| brew ratio r | 14.0 – 18.0 | 1.0 | 5 |
| 時間 s (秒) | 120 – 240 | 30 | 5 |
| 正規化粒度 g | 0.30 – 0.95 | 0.13 | 6 |

**精密化(局所細グリッド)** — 表示対象メソッドのみ:

粗グリッドの μ 最大点 `x_c` を中心に、各次元 **±1粗ステップ**の範囲を細刻みで再探索する。範囲は上表の全体範囲でクリップする。

| 次元 | 細刻み | 走査点数(最大) |
|---|---|---|
| 湯温 | 1 | 9 |
| ratio | 0.5 | 5 |
| 時間 | 15 | 5 |
| 粒度 | 0.05 | 7 |

最大 1575 点。μ 最大点と EI 最大点は**粗+細の全評価点を通して**選ぶ。

```dart
/// [refine] = false なら粗グリッドのみ (ランキング用・高速)。
({GpPrediction best, GpPoint bestX, GpPrediction explore, GpPoint exploreX})
    optimize(GpModel model, {bool refine = true});
```

> 全メソッドのランキングは `optimize(model, refine: false)`、表示中メソッドの推奨条件は `optimize(model)` で求める。

---

## 6. UI 仕様(`lib/widgets/brew/gp_explorer_section.dart` の作り直し)

配置は変更しない(030 `brew_recipe_screen.dart` 内、`FormSection` の中。`StatsTheoryLink(section: StatsTheorySection.gp)` もそのまま)。

### 6.1 セレクタ(現行の「産地 + 焙煎度」を置き換える)

| 項目 | 仕様 |
|---|---|
| **豆** | `beanMasterProvider` から、`originId` が空でない豆のみ。並び順は **`seekOptimalConditions == true` の豆を先頭**、その後は豆名の昇順。探索対象の豆はラベル先頭に `★` を付ける。既定値は先頭の豆 |
| **ミル** | `grinderMasterProvider` から `grindSteps != null` の豆挽きミルのみ(= ドリップバッグを除外)。既定値は**抽出記録での使用回数が最も多いミル**(実測では M002 = Kingrinder K6) |

`originId` と `roastOrdinal` は選択した `BeanMaster` から導出する(`roastOrdinalMap[bean.roastLevel]`)。`roastLevel` が `roastOrdinalMap` に無い豆は欠測なので、豆ドロップダウンから除外し「焙煎度が未設定の豆はn件除外」と注記する。

> **`seekOptimalConditions` は 2026-07-30 時点で本番28件すべて未回答(null)**。したがって「★付きのみに絞る」実装にすると**画面が常に空になる**。必ず全豆を出したうえで並び順と `★` で区別すること。キャプションに「★ = 最適条件探索の対象に設定した豆」と添える。

### 6.2 メソッド比較表

候補メソッド = `methodMasterProvider` の全メソッドのうち `fitForMethod` が非 null を返したもの。§4.4 の規則で並べる。

| 列 | 内容 |
|---|---|
| メソッド名 | `MethodMaster.name`。先頭行のみ「有望」チップを付ける |
| 予測スコア | `μ.toStringAsFixed(1)` + ` [下限, 上限]`(95%予測区間) |
| 確信度 | §4.3 のバッジ |
| n | `n_eff` を小数1桁 |

予測区間は既存実装と同じく `totalSd = sqrt(sd² + σ_n²)`、`μ ± 1.96·totalSd` を `0.0–10.0` にクランプする(`statistics_feature_design.md` §2.5)。

行タップで「表示中メソッド」を切り替える(既定は先頭行)。

条件を満たさなかったメソッドは `ExpansionTile`「データ不足のメソッド (n件)」に畳んで、メソッド名と理由(`記録n件 / n_eff x.x`)だけ列挙する。

### 6.3 推奨条件カード(表示中メソッド)

現行の「おすすめの条件」カードを踏襲しつつ粒度を追加する。

```
おすすめの条件 — <メソッド名>
湯温 90℃ / 湯:豆 1:15.5 / 時間 2:30 / 粒度 92 クリック (Kingrinder K6・180段階中)
予測スコア 7.8 [6.4, 9.2] (95%予測区間)

試してみる価値がある条件 (EI最大)
湯温 86℃ / 湯:豆 1:17.0 / 時間 3:00 / 粒度 108 クリック
```

- 粒度は必ず**選択中ミルのクリック数**に逆変換して表示する(正規化値 `gNorm` は画面に出さない)。
- 「試してみる価値がある条件」(EI最大点)は T3-53(検証状況の可視化)がそのまま使えるよう、この時点で表示しておく。

### 6.4 ヒートマップ

現行の `Table` + 色付き `Container`(湯温4値 × 比率5値の粗グリッド)を維持する。固定する軸が1つ増えるのでキャプションを変更:

```
予測総合評価マップ (<メソッド名> / 時間 2:30・粒度 92 クリック 固定)
```

時間と粒度は §5.4 の `optimize()` が返した推奨点の値で固定する。

### 6.5 除外件数の表示

学習から除外した行がある場合、セクション末尾に薄字で1行:
> 「粒度またはミルが未記録の n 件は計算から除外しました。」

---

## 7. `statistics_feature_design.md` への反映(本タスクで上位モデルが実施済み)

| 節 | 改訂内容 |
|---|---|
| §1.3 | F4 の最小条件を「メソッドごとに n_eff ≥ 6.0 かつ n ≥ 8」に変更。案内文も差し替え |
| §2.3.1 | 入力を d=4(湯温・brew ratio・総抽出時間・正規化粒度)に変更 |
| §2.3.3 | 候補グリッドを §5.4 の2段階探索に差し替え |
| §7.5 | `GpService` のシグネチャを §5 に差し替え。UI 記述を §6 に差し替え |
| §9.5 | テスト仕様を §8 に差し替え |
| §11 | ミル間の線形正規化の限界(§3.2)を既知の限界として追記 |

いずれも本書へのポインタを張り、詳細の二重管理を避ける。

---

## 8. テスト仕様(`statistics_feature_design.md` §9.5 の改訂)

### 8.1 既存3テストの扱い

`test/gp_service_test.dart` の既存テストのうち:

- **`expectedImprovement` の3ケース(§9.5-3)は無変更**。次元に依存しない。
- **§9.5-1(訓練点で mean≈y, sd<1e-2)と §9.5-2(遠点で sd≈σ_f)は、`xs` に4列目を足すだけ**で期待値は変更しない。どちらも次元に依存しない性質のため。`predict` の呼び出しを4引数に直す。

4列目に使う値(12行、既存の行順に対応。0.30–0.95 に散らばらせてある):

```
0.72, 0.44, 0.80, 0.50, 0.65, 0.36, 0.55, 0.75, 0.42, 0.60, 0.48, 0.68
```

> 次元が増えると訓練点間の距離が広がり `K` の条件数はむしろ改善するため、`σ_n=1e-6` でも Cholesky は安定する。期待値・許容誤差は §9.5 の既存値をそのまま使うこと。

### 8.2 新規テスト(最低5件)

| # | 対象 | 内容 |
|---|---|---|
| 1 | `GrinderMaster.grindSteps` | `grindRange` が `"20"` → 20、`"180"` → 180、`"0"` → null、`null`/`""`/`"abc"` → null |
| 2 | keyMap 修正 | `GrinderMaster.fromJson` に `{'挽き目調整段階': 180}`(**数値**)を remap した Map を渡して `grindRange == "180"`・`grindSteps == 180` になる(= 型ガードの回帰テスト)。`MethodMaster` も `挽き目（Kingrinder K6）` に数値 80 を入れて同様に確認 |
| 3 | `fitForMethod` の行フィルタ | `methodId` 違い・粒度未記録・`grindSteps` が無いミル(ドリップバッグ)の記録が除外され、`nRows` が期待どおりになる |
| 4 | `fitForMethod` の最小データ条件 | `n_eff = 5.9` 相当で `null`、`6.0` 相当かつ `nRows >= 8` で非 null。`nRows = 7` なら `n_eff` が足りていても `null` |
| 5 | ミル不一致の重み | 目標ミルと同じ記録と違う記録を同数与え、違う側の重みが半分になっている(= 同一入力でも `nEff` が `1.0 + 0.5` の比で積み上がる)ことを確認 |
| 6 | `optimize` の粗/細 | `refine: false` と `refine: true` で `bestX` が返り、`refine: true` の `best.mean` が `refine: false` の `best.mean` **以上**である(細グリッドは粗グリッドの最大点を含むため単調) |

widget テストは既存の 030 系テストに準じ、少なくとも「豆とミルのドロップダウンが表示される」「データ不足時に固定文言が出る」の2件を追加する。

---

## 9. 実装タスクへの分解

**T3-52 は下記4タスクに分解する。順序厳守(a → b → c、d は c と同時可)。** すべて Sonnet 5 で実施可能。

| ID | 内容 | 終了条件 | 依存 | サイズ |
|---|---|---|---|---|
| **T3-52a** | §2 の既存バグ修正。`sheets_service.dart` の `getGrinders()`/`_reverseMapGrinder`/`getMethods()`/`_reverseMapMethod` のキー名を本番列名(`挽き目調整段階` / `挽き目（Kingrinder K6）`、括弧は全角)に修正し、`GrinderMaster.grindRange` と `MethodMaster.grindSize` に `@JsonKey(fromJson: _parseString)` を付与、`GrinderMaster.grindSteps` ゲッターを追加。§8.2 のテスト1・2を追加 | 020/010系の詳細画面で挽き目調整段階と挽き目が表示され、`flutter test` 全パス | なし | S |
| **T3-52b** | §5 の `GpService` 4次元化。`fitForMethod` 新設・`fit` 削除・`predict` 4引数化・`optimize` の2段階グリッド化・`GpModel` に `nRows`/`methodId` 追加。§8.1 の既存テスト修正と §8.2 のテスト3〜6を追加 | `flutter test` 全パス(既存281件+新規) | T3-52a | M |
| **T3-52c** | §6 の `gp_explorer_section.dart` 作り直し(豆+ミルセレクタ、メソッド比較表、推奨条件カード、ヒートマップのキャプション変更、除外件数表示)。widget テスト2件追加 | 030 で豆を選ぶと推奨メソッド・湯温・粒度が予測スコアと95%予測区間付きで表示される | T3-52b | M |
| **T3-52d** | §7 のとおり `statistics_feature_design.md` を改訂(本書へのポインタ方式) | 設計書と実装の記述が一致 | T3-52c | S |

> **T3-53(検証状況の可視化)は T3-52c 完了後に着手可能**になる。EI 最大点の表示(§6.3)を T3-52c で先に入れてあるので、T3-53 はその上に試行履歴の重ね描きを足す形になる。

---

## 10. 実装時の地雷(既知、必ず読むこと)

1. **全角括弧**: `挽き目（Kingrinder K6）` の括弧は全角。半角で書くとキーが一致せず、無言で `null` になる(§2.2)。
2. **数値列を `String?` で受ける**: キー名を直した瞬間に `type 'int' is not a subtype of type 'String?'` が出る。`_parseString` を必ず付ける(§2.3)。
3. **`_fetchData` は例外を握り潰す**: 行単位の try/catch でログに出すだけなので、失敗は「クラッシュ」ではなく「一覧が空/値が欠落」として現れる。修正後は必ず本番データで実値が入ることを確認する。
4. **`seekOptimalConditions` は本番全件 null**: ★絞り込みを実装すると画面が空になる(§6.1)。
5. **`coffee_data` の焙煎度は旧5段階表記**(浅煎り/中浅煎り/中煎り/中深煎り/深煎り)が主。`roastOrdinalMap` が両方を吸収するので**独自の変換を書かない**。
6. **`coffee_data` の `産地ID` は168件中91件が空**。空 originId の記録は重み 0.2 として学習に残る(除外しない)。
7. **GAS の列追加は不要**。T3-52 では新しいシート列を作らないので `EXISTING_SHEET_EXTRA_COLUMNS` の変更も `clasp push` も要らない。
8. **マスター詳細画面は編集→保存→pop直後に表示が更新されない**(`rules/lessons_archive.md` L89)。T3-52a の本番確認では一覧に戻って再訪問するかフルリロードすること。
9. **`claude-in-chrome` の一覧グリッドのスクロールは不安定**(同 L87)。粘らず GAS 直叩き or widget テストに切り替える。
