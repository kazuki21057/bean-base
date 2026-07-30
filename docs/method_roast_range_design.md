# メソッドの推奨焙煎度「幅」対応 設計書 (T3-71)

最終更新: 2026-07-30 / 作成: 上位モデル(Opus 5)による T3-71 の設計実行
正本: 本書。実装タスク **T3-71a / T3-71b** はこの内容をそのまま実装すること。**本書に無い仕様を発明しない。** 不明点があれば実装を止めてユーザーに質問する。

> **このドキュメントの位置づけ**
> 2026-07-30 のユーザー要望「推奨焙煎度は幅を持って設定したい。スライダーで幅を設定できるのが理想」の設計成果物。T3-47 で `MethodMaster.recommendedRoastLevel`(単一値)として実装した推奨焙煎度を、**下限〜上限の範囲**に拡張する。**コードは1行も書いていない**(`CLAUDE.md` §日次改修ループ運用ルール「モデル分担ルール」)。
> 前提設計書: `docs/roast_slider_design.md`(T3-54、`RoastLevelSlider`)。本書のウィジェットはその設計を範囲版に写したものであり、**色・レイアウト・変換規則・地雷はすべて同書を踏襲する**。

---

## 1. 結論とユーザー決定事項

**`methods_master` に「推奨焙煎度(最浅)」「推奨焙煎度(最深)」の2列を新設し、021 の入力を `RangeSlider` ベースの新ウィジェット `RoastRangeSlider` に置き換える。既存の「推奨焙煎度」列は読み取り専用の後方互換フォールバックとして残す。**

### 1.1 ユーザー決定事項(2026-07-30、`AskUserQuestion` で確認済み)

| # | 論点 | 決定 |
|---|---|---|
| ① | 範囲が未設定のメソッドを F3(おすすめレシピ)でどう扱うか | **候補外**(現行 T3-48 の挙動を維持)。未設定=「どの豆にも提案しない」。ユーザーが各メソッドに範囲を設定するまでおすすめカードは出ない |
| ② | Sheets 側のデータの持ち方 | **新2列に分ける**。「推奨焙煎度(最浅)」「推奨焙煎度(最深)」。既存の「推奨焙煎度」列は消さず、読み取り時のフォールバックとして残す |
| ③ | 未検証で残っている T3-48 とのデプロイ順 | **幅対応まで含めて一緒にデプロイ**。T3-48 は検証・コミットまで済ませ、本番反映は T3-71b 完了後にまとめて行う |

### 1.2 なぜ幅なのか(仕様の意図)

「4:6メソッドは中煎り〜中深煎り向き」のように、抽出メソッドが想定する焙煎度は**点ではなく帯**である。T3-47 の単一値では、豆の焙煎度と完全一致しない限り候補から外れてしまい、F3(おすすめレシピ)がほとんど提案を出せない。範囲にすることで「その豆の焙煎度が帯に入っているか」で判定でき、実用的な絞り込みになる。

### 1.3 副次的なバグ修正(意図した効果)

現行 T3-48 の候補判定は `m.recommendedRoastLevel == bean.roastLevel` という**生文字列の完全一致**であり、豆側が旧5段階表記(`'中煎り'`)・メソッド側が新8段階表記(`'ハイ'`)だと**同じ焙煎度なのに一致しない**。本設計では両者を `roastOrdinalMap` で順序値に変換してから比較するため、この不整合が解消される。**この修正効果を walkthrough / NEXT_SESSION に記載すること。**

---

## 2. 変更対象ファイル一覧(確定)

| ファイル | 変更内容 | タスク |
|---|---|---|
| `lib/models/method_master.dart` | `recommendedRoastMin` / `recommendedRoastMax` を追加(§3.1) | T3-71a |
| `lib/models/method_master.g.dart` | 上記2件を `fromJson`/`toJson` に**手編集で**追加(§3.2、build_runner は使わない) | T3-71a |
| `lib/utils/roast_range.dart` | **新規作成**。範囲の解決・判定・表示整形(§4) | T3-71a |
| `lib/services/sheets_service.dart` | `getMethods()` の keyMap と `_reverseMapMethod()` の reverseMap に**両方**追加(§3.3) | T3-71a |
| `gas/Code.gs` | `EXISTING_SHEET_EXTRA_COLUMNS['methods_master']` に2列追加(§3.4) | T3-71a |
| `lib/widgets/roast_level_slider.dart` | グラデーション色定数を**公開名に変更するだけ**(§5.1) | T3-71a |
| `lib/widgets/roast_range_slider.dart` | **新規作成**。`RoastRangeSlider` ウィジェット(§5) | T3-71a |
| `lib/screens/create/method_create_screen.dart` (021) | `RoastLevelSlider` → `RoastRangeSlider` に置換(§6.1) | T3-71a |
| `lib/screens/method_detail_screen.dart` (020) | 推奨焙煎度の表示を範囲表記に(§6.2) | T3-71a |
| `test/roast_range_slider_test.dart` | **新規作成**。ウィジェット単体テスト7件(§8.1) | T3-71a |
| `test/method_template_test.dart` | 既存の推奨焙煎度テスト3件を範囲版に更新(§8.2) | T3-71a |
| `lib/services/suggestion_service.dart` | 候補メソッドの絞り込みを範囲判定に差し替え(§7.1) | T3-71b |
| `lib/widgets/dashboard/recipe_suggestion_card.dart` | ドキュメントコメントの更新のみ(§7.2) | T3-71b |
| `test/suggestion_service_test.dart` | 範囲判定のテストを追加・更新(§8.3) | T3-71b |
| `test/recipe_suggestion_card_test.dart` | 既存のまま通ることを確認(§8.4) | T3-71b |

**触らないファイル**: `lib/services/math/encoding.dart`(`roastOrdinalMap` / `roastLevels8` / `roastLevels8En` は**一切変更しない**)、`lib/services/gp_service.dart`、`lib/widgets/brew/gp_explorer_section.dart`(030 のメソッド別ランキングは今回は絞り込まない。§10-①参照)、`lib/screens/brew_recipe_screen.dart` と `lib/models/pending_brew_info.dart`(`MethodMaster(...)` を構築しているが `recommendedRoast*` は指定しておらず、新フィールドが任意引数のため無変更で通る)。

---

## 3. データモデルとシート列

### 3.1 `MethodMaster` への追加(`lib/models/method_master.dart`)

既存の `recommendedRoastLevel` の**直後**に、同じ書式で2フィールド追加する。

```dart
  final String? recommendedRoastLevel;   // 既存。T3-71以降は「旧・単一値」= 読み取り専用フォールバック
  final String? recommendedRoastMin;     // 追加: 範囲の浅い側
  final String? recommendedRoastMax;     // 追加: 範囲の深い側
```

コンストラクタにも `this.recommendedRoastMin,` `this.recommendedRoastMax,` を **`this.recommendedRoastLevel,` の直後**に追加する(いずれも任意引数)。

- **型は `String?`**(順序値 `double` ではない)。理由: `roastLevel` 系は本番シートに旧5段階表記や自由入力が残っており、アプリ内では常に「生の文字列を持ち、参照時に `roastOrdinalMap` で解決する」流儀に統一してあるため(`docs/roast_slider_design.md` §4)。
- **`@JsonKey` は付けない**(既存の `recommendedRoastLevel` と同じく素の `String?`)。Sheets 側の値は日本語ラベル文字列であり、数値セルに化ける余地が無いため `_parseString` は不要。

### 3.2 `method_master.g.dart` の手編集(build_runner は使わない)

`dart run build_runner build` は**このマシンで既知のクラッシュを起こし、全モデルの `*.g.dart` を消したまま停止する**(`rules/lessons_archive.md` L63、直近では 2026-07-30 の T3-48 でも再発)。**手編集すること。**

`_$MethodMasterFromJson` の `recommendedRoastLevel: json['recommendedRoastLevel'] as String?,` の直後に:
```dart
  recommendedRoastMin: json['recommendedRoastMin'] as String?,
  recommendedRoastMax: json['recommendedRoastMax'] as String?,
```
`_$MethodMasterToJson` の `'recommendedRoastLevel': instance.recommendedRoastLevel,` の直後に:
```dart
      'recommendedRoastMin': instance.recommendedRoastMin,
      'recommendedRoastMax': instance.recommendedRoastMax,
```
(インデントは既存行に合わせる)

### 3.3 `SheetsService` のマッピング(**2箇所とも**必須)

| 場所 | 追加する行 |
|---|---|
| `getMethods()` の `keyMap`(`'推奨焙煎度': 'recommendedRoastLevel',` の直後) | `'推奨焙煎度(最浅)': 'recommendedRoastMin',`<br>`'推奨焙煎度(最深)': 'recommendedRoastMax',` |
| `_reverseMapMethod()` の `reverseMap`(`'recommendedRoastLevel': '推奨焙煎度',` の直後) | `'recommendedRoastMin': '推奨焙煎度(最浅)',`<br>`'recommendedRoastMax': '推奨焙煎度(最深)',` |

**列名の括弧は半角 `(` `)`** とする(既存の `'基準豆量(g)'` `'初期購入量(g)'` と同じ流儀。`'湯温（℃）'` は全角だが、これは元シートの既存列名に合わせた例外であり新規列では真似しない)。

### 3.4 GAS の列プロビジョニング(`gas/Code.gs`)

```js
  'methods_master': ['推奨焙煎度', '推奨焙煎度(最浅)', '推奨焙煎度(最深)'],
```
- `EXISTING_SHEET_EXTRA_COLUMNS` は冪等(既にある列はスキップ)なので、既存の `'推奨焙煎度'` は**残したまま**2列を足す。
- 直前のコメント群の末尾に `// T3-71: methods_master に推奨焙煎度の範囲2列を追加(既存の推奨焙煎度は後方互換で残す)。` を追記する。
- 反映は `clasp push` + `clasp deploy --deploymentId <既存ID>`(=URL維持の redeploy)。**実行前に必ずチャットでユーザーの許可を得ること**(2026-07-30 の恒久ルール、`rules/lessons_archive.md` L91)。
- **列が無いまま書き込むと GAS は黙って値を捨てる**(POST は成功扱い)。`rules/lessons_archive.md` L69 の頻出バグと同型なので、push 後に `curl` で `?sheet=methods_master` を叩き、ヘッダーに2列が増えたことを必ず確認する。

---

## 4. 範囲の解決規則(`lib/utils/roast_range.dart` 新規)

**この規則がアプリ全体で唯一の正**。UI もサービスも必ずここを通す。文字列比較で焙煎度を突き合わせるコードを新たに書かないこと。

### 4.1 API

```dart
/// 焙煎度の範囲(順序値 1.0〜8.0、min <= max)。
class RoastRange {
  final double min;
  final double max;
  const RoastRange(this.min, this.max);

  bool get isPoint => min == max;
  bool contains(double ordinal) => ordinal >= min && ordinal <= max;
}

/// [method] の推奨焙煎度の範囲を解決する。未設定・解決不能なら null。
RoastRange? resolveMethodRoastRange(MethodMaster method);

/// [method] の推奨焙煎度が [beanRoastOrdinal] を含むか。
/// 範囲が未設定(resolve が null)なら **false**(= 候補外。§1.1①のユーザー決定)。
bool methodMatchesRoastOrdinal(MethodMaster method, double beanRoastOrdinal);

/// 020(詳細画面)などの表示用ラベル。§4.3。
String formatMethodRoastRange(MethodMaster method);
```

`lib/utils/` に置く理由: 既存の `lib/utils/bean_stock_calculator.dart` と同じ「モデルを受け取って派生値を計算する純関数」の置き場だから。**`encoding.dart`(定数のみ・モデル非依存)にモデル依存の関数を足さないこと。**

### 4.2 `resolveMethodRoastRange` の手順(この通りに実装する)

```
1. a = roastOrdinalMap[method.recommendedRoastMin]  (null/空文字列なら null)
   b = roastOrdinalMap[method.recommendedRoastMax]  (null/空文字列なら null)
2. a も b も非 null → RoastRange(min(a,b), max(a,b))     ※ 逆転していても入れ替えて救う
3. 片方だけ非 null → その値で RoastRange(v, v)            ※ 片側だけ入力された過渡状態を点として扱う
4. 両方 null → 旧列 c = roastOrdinalMap[method.recommendedRoastLevel] を引く
   - c が非 null → RoastRange(c, c)                     ※ T3-47 で入れた単一値の後方互換
   - c も null → null(未設定 or 未知の文字列)
5. 範囲外(1.0 未満 / 8.0 超)の値が混じったら null を返す(現状の map には該当なし)
```

`roastOrdinalMap` が旧5段階表記(`'中煎り'`→4.0)も英語表記(`'High'`→4.0)も解決するため、**表記ゆれはこの1行で吸収される**。

### 4.3 `formatMethodRoastRange` の出力(020 の表示規則)

| 状態 | 出力例 |
|---|---|
| 範囲(min≠max) | `ミディアム 〜 フルシティ` |
| 点(min==max) | `シティ (City)` ※ `roastLevels8En` を併記 |
| 未設定だが生文字列が残っている(未知の値) | その生文字列をそのまま返す(`recommendedRoastMin` → `recommendedRoastMax` → `recommendedRoastLevel` の順で最初の非空値) |
| 完全に未設定 | `-` |

区切りは**全角チルダではなく波ダッシュ `〜`(U+301C)** を使う(本リポジトリの既存文言に合わせる)。

---

## 5. `RoastRangeSlider` ウィジェット仕様

### 5.1 前準備: 色定数の公開(`lib/widgets/roast_level_slider.dart`)

現在ファイルプライベートな
```dart
const _kRoastLightest = Color(0xFFC8A87C);
const _kRoastDarkest = Color(0xFF3B2314);
```
を **`kRoastLightest` / `kRoastDarkest` に改名(先頭のアンダースコアを取るだけ)** し、同ファイル内の参照2箇所(`LinearGradient(colors: [...])`)も直す。**それ以外は一切変更しない。** 新ウィジェットはこれを import して同じ色を使う(色定数を再定義してコピーしないこと)。

### 5.2 API(この通りに実装する)

```
ファイル: lib/widgets/roast_range_slider.dart
クラス:   class RoastRangeSlider extends StatelessWidget
```

| 引数 | 型 | 既定値 | 意味 |
|---|---|---|---|
| `minValue` | `String?` | (必須) | 範囲の浅い側。**生の保存値をそのまま渡す** |
| `maxValue` | `String?` | (必須) | 範囲の深い側。同上 |
| `onChanged` | `void Function(String? min, String? max)` | (必須) | 値が変わったときに呼ぶ。渡すのは常に `roastLevels8` の日本語正規ラベル2つ、またはクリア時の `(null, null)` |
| `label` | `String` | `'推奨焙煎度'` | ラベル行の見出し |
| `trailing` | `Widget?` | `null` | ラベル行右端のスロット(T3-51 の焙煎度説明ページ導線用。T3-71a では常に `null`) |
| `enabled` | `bool` | `true` | `false` で操作不可・淡色表示 |

- **必ず `StatelessWidget`(制御コンポーネント)にすること。** 内部に選択状態を持ってはならない(`docs/roast_slider_design.md` §8-①、`MockChoiceChips` 型の再発防止)。
- `compact` は**作らない**。今回の利用箇所は 021 のみで縦積みフォームだから。必要になったタスクで追加する。

### 5.3 表示状態(3状態、これがすべて)

`minValue`/`maxValue` を §4.2 と同じ手順(**ただし旧列フォールバックは無し**。ウィジェットは渡された2値だけを見る)で順序値 `lo` / `hi` に解決し分岐する。

| 状態 | 条件 | 現在値表示 | RangeSlider の `values` | サム色 | クリアボタン |
|---|---|---|---|---|---|
| **A: 設定済み(範囲)** | `lo != null && hi != null && lo != hi` | `'ミディアム 〜 フルシティ  3〜6/8'`<br>`TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kEspresso)` | `RangeValues(lo, hi)` | `kEspresso` | **有効** |
| **A': 設定済み(点)** | `lo == hi` | `'シティ (City)  5/8 のみ'`(同スタイル) | `RangeValues(lo, lo)` | `kEspresso` | **有効** |
| **B: 未設定** | 両方 null/空文字列 | `'未設定(スライダーを動かして範囲を選択)'`<br>`TextStyle(fontSize: 13, color: kMocha)` | `RangeValues(3, 6)`(**保存されない既定位置**) | `kLatte` | **無効**(`onPressed: null`) |
| **C: 未知の値** | 非空だが `roastOrdinalMap` に無い | `'未設定(登録値: 「$minValue」)'`(B と同スタイル。両方非空で異なる場合は `「$minValue」「$maxValue」`) | `RangeValues(3, 6)` | `kLatte` | **有効**(押すと `onChanged(null, null)`) |

- **片方だけ解決できた場合は §4.2 手順3 と同じく点として扱う**(状態 A')。
- **状態 C では `onChanged` を呼ばない。** ユーザーがスライダーを触らずに保存すれば元の文字列がそのまま保存される(`docs/roast_slider_design.md` §4.4 と同じ思想)。
- クリアボタンは `TextButton`。スタイル・配置は `RoastLevelSlider` の `clearButton` をそのまま踏襲する。

### 5.4 レイアウト(`RoastLevelSlider` の非 compact 版に揃える)

```
┌──────────────────────────────────────────────┐
│ 推奨焙煎度                        [クリア]    │  ← ラベル行
│                                              │
│      ミディアム 〜 フルシティ  3〜6/8          │  ← 現在値(中央、大きめ)
│                                              │
│   ░░░░●▓▓▓▓████████●░░░░░░░░░                │  ← グラデーション(範囲外は白でくすませる)
│                                              │
│   浅い                                 深い   │  ← 端ラベル
└──────────────────────────────────────────────┘
```

外枠 `Padding(padding: const EdgeInsets.only(bottom: 14))` → `Column(crossAxisAlignment: CrossAxisAlignment.start)`、ラベル行 → `SizedBox(height: 4)` → `Center(現在値)` → トラック → 端ラベル行。**すべて `RoastLevelSlider` の該当箇所をそのまま写す**(フォントサイズ・色 `kMocha`/`kEspresso`・`horizontal: 12` のパディングを含む)。色定数は `create_form_widgets.dart` の既存のもの(`kEspresso` `kMocha` `kLatte` `kAccent`)を使い、新しいテーマファイルを作らない。

### 5.5 トラックの実装方法(この方式で作ること)

`RoastLevelSlider` と同じく「グラデーションを背面に敷き、トラックを透明にした `RangeSlider` を前面に重ねる」。ただし範囲版では**選択帯の内外が見分けられる必要がある**ため、**範囲外を白の半透明で覆う**(帯の中だけが原色で出る)。

```dart
SizedBox(
  height: 40,
  child: LayoutBuilder(
    builder: (context, constraints) {
      const hPad = 12.0;
      final trackW = (constraints.maxWidth - hPad * 2).clamp(1.0, double.infinity);
      double fx(double o) => (o - 1) / 7 * trackW;   // 順序値→トラック上のx座標
      return Stack(
        alignment: Alignment.center,
        children: [
          // 背面: グラデーションバー + 範囲外のくすませ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: hPad),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kRoastLightest, kRoastDarkest]),
                        ),
                      ),
                    ),
                    if (<状態A/A'>) ...[
                      Positioned(left: 0, top: 0, bottom: 0, width: fx(lo),
                          child: ColoredBox(color: Colors.white.withValues(alpha: 0.55))),
                      Positioned(left: fx(hi), top: 0, bottom: 0, right: 0,
                          child: ColoredBox(color: Colors.white.withValues(alpha: 0.55))),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // 前面: トラックを透明にした RangeSlider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              activeTickMarkColor: Colors.white.withValues(alpha: 0.7),
              inactiveTickMarkColor: Colors.white.withValues(alpha: 0.7),
              thumbColor: <§5.3 の規則>,
              overlayColor: kAccent.withValues(alpha: 0.2),
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
              overlappingShapeStrokeColor: Colors.white,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: RangeSlider(
              min: 1, max: 8, divisions: 7,
              values: <§5.3 の values>,
              onChanged: enabled
                  ? (v) => onChanged(
                        roastLevels8[v.start.round() - 1],
                        roastLevels8[v.end.round() - 1],
                      )
                  : null,
            ),
          ),
        ],
      );
    },
  ),
)
```

- **`RangeSlider` のテーマキーは `Slider` と別物**。`thumbShape` ではなく **`rangeThumbShape`**(`RoundRangeSliderThumbShape`)、目盛りは `rangeTickMarkShape`。`RoastLevelSlider` から `thumbShape:` をコピペしても効かないので注意。
- 2つのサムが重なったとき(点状態)の視認性のため `overlappingShapeStrokeColor: Colors.white` を必ず入れる。
- **必ず `.round()` を経由**して index を計算する(浮動小数誤差で `7.999…` → index 6 になる事故の防止)。
- 状態 B/C のときは範囲外オーバーレイを出さず、トラック全体を `Opacity(opacity: 0.4)` で包む。`enabled: false` のときも同様に `Opacity(0.4)`。
- `.withOpacity()` は使わない(非推奨)。`.withValues(alpha: ...)` を使う。

---

## 6. 画面ごとの適用方法(T3-71a)

### 6.1 021 メソッド登録/編集 (`lib/screens/create/method_create_screen.dart`)

**状態フィールド**(48行目付近):
```dart
  String? _recommendedRoastLevel;              // 削除
  String? _roastMin;                           // 追加
  String? _roastMax;                           // 追加
```

**`initState`**(73行目付近の `_recommendedRoastLevel = edit?.recommendedRoastLevel;` を置換):
```dart
    _roastMin = edit?.recommendedRoastMin ?? edit?.recommendedRoastLevel;
    _roastMax = edit?.recommendedRoastMax ?? edit?.recommendedRoastLevel;
```
旧単一値しか無いメソッドを編集で開くと「点」として表示され、保存すれば新2列へ移る(**遅延マイグレーション**)。

**フォーム**(279行目付近の `RoastLevelSlider(...)` を置換):
```dart
            RoastRangeSlider(
              minValue: _roastMin,
              maxValue: _roastMax,
              onChanged: (min, max) => setState(() {
                _roastMin = min;
                _roastMax = max;
              }),
            ),
```
**⚠️ `setState` を必ず付ける**(制御コンポーネントなので、無いとサムが動かない)。`label` は既定値 `'推奨焙煎度'` なので指定不要。

**`_submit()`**(142行目付近の `recommendedRoastLevel: _recommendedRoastLevel,` を置換):
```dart
      recommendedRoastLevel: '',        // 旧列は保存のたびに空にする(§6.3)
      recommendedRoastMin: _roastMin,
      recommendedRoastMax: _roastMax,
```

**import**: `roast_level_slider.dart` の import が未使用になるなら `roast_range_slider.dart` に差し替える(021 で他に `RoastLevelSlider` を使っていないことを確認済み)。

### 6.2 020 メソッド詳細 (`lib/screens/method_detail_screen.dart`)

`fields:` の推奨焙煎度の行(58〜60行目)を置換:
```dart
        ('推奨焙煎度', formatMethodRoastRange(method)),
```
`lib/utils/roast_range.dart` を import する。**他のフィールド行は触らない。**

### 6.3 旧列を保存時に空にする理由(仕様として明記)

| 編集前の保存値 | ユーザーの操作 | 保存後 |
|---|---|---|
| 旧列=`'シティ'`、新2列=空 | 何も触らず保存 | 新2列=`'シティ'`/`'シティ'`、旧列=`''`(**値は失われない**) |
| 旧列=`'シティ'`、新2列=空 | 範囲 ミディアム〜フルシティ に変更 | 新2列=`'ミディアム'`/`'フルシティ'`、旧列=`''` |
| 旧列=`'謎の焙煎'`(未知) | 何も触らず保存 | 新2列とも `'謎の焙煎'`、旧列=`''`(生文字列は保持される) |
| すべて空 | クリアを押す/何もしない | すべて空のまま |

`initState` が旧列を新2列に読み込んでから保存するため、**旧列を空にしても情報は失われない**。旧列を残したまま両方に値があると「どちらが正か」が二重管理になるので、保存のたびに片付ける設計にしている。なお 2026-07-30 時点で本番 `methods_master` 12件はすべて推奨焙煎度が未設定(「-」)であり、実質的に移行対象は存在しない。**T3-71a の実装前に `curl` で本番 `methods_master` を1回取得し、旧列に値が入っているメソッドが無いことを確認すること**(あった場合はその値を控えてから進める)。

---

## 7. F3(おすすめレシピ)の候補判定(T3-71b)

### 7.1 `lib/services/suggestion_service.dart`

`suggestWithGp` の候補絞り込み(73行目付近):
```dart
    final candidateMethods =
        methods.where((m) => m.recommendedRoastLevel == bean.roastLevel).toList();   // 置換前
    final candidateMethods =
        methods.where((m) => methodMatchesRoastOrdinal(m, roastOrdinal)).toList();   // 置換後
```
- `roastOrdinal` は直前(69行目)で `roastOrdinalMap[bean.roastLevel]` として解決済み、`null` なら既に early return しているため**そのまま使える**。
- `lib/utils/roast_range.dart` を import する。
- **範囲未設定のメソッドは候補外**(§1.1①)。`methodMatchesRoastOrdinal` が `false` を返すのでこの1行で満たされる。
- `candidateMethods.isEmpty` のとき `null` を返す既存の挙動は**変更しない**。
- クラス冒頭のドキュメントコメント(28〜45行目)の「`recommendedRoastLevel`が対象豆の焙煎度と一致するもの」という記述を「推奨焙煎度の範囲(`recommendedRoastMin`〜`recommendedRoastMax`、旧単一値も後方互換で解決)に対象豆の焙煎度が含まれるもの」に書き換える。`suggestWithGp` の docコメント(56行目付近)も同様。
- **`suggestFor`(group_best フォールバック)は無変更**。`candidateMethodIds` を受け取る現行シグネチャのままでよい(絞り込みは呼び出し側で済んでいる)。

### 7.2 `lib/widgets/dashboard/recipe_suggestion_card.dart`

34行目付近のドキュメントコメント「`recommendedRoastLevel`が一致するものに限られる」を範囲判定の記述に更新する。**ロジックの変更は不要**(`methods` をそのまま `suggestWithGp` に渡しており、絞り込みはサービス側の責務)。

---

## 8. テスト計画

**スライダーの操作は `tester.drag(...)` を使わないこと**(ドラッグ量と divisions の対応が環境依存)。`tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(const RangeValues(3, 6))` のようにコールバックを直接呼ぶ。

### 8.1 新規 `test/roast_range_slider_test.dart`(T3-71a、7件)

| # | 入力 | 期待 |
|---|---|---|
| 1 | `minValue: null, maxValue: null` | `'未設定(スライダーを動かして範囲を選択)'` が出る / `values == RangeValues(3, 6)` / クリアの `onPressed` が `null` |
| 2 | `'ミディアム'` / `'フルシティ'` | `'ミディアム 〜 フルシティ'` を含むテキスト / `values == RangeValues(3, 6)` |
| 3 | `'シティ'` / `'シティ'` | `'シティ (City)'` を含むテキスト / `values == RangeValues(5, 5)` |
| 4 | `'中煎り'` / `'深煎り'`(旧5段階) | `'ハイ 〜 フレンチ'` を含むテキスト / `values == RangeValues(4, 7)`(**後方互換の回帰テスト**) |
| 5 | `'フルシティ'` / `'ミディアム'`(逆転) | `'ミディアム 〜 フルシティ'` として表示され `values == RangeValues(3, 6)`(入れ替えて救う) |
| 6 | `'謎の焙煎'` / `null`(未知) | `'謎の焙煎'` を含む未設定表示 / `values == RangeValues(3, 6)` / この時点で `onChanged` は**呼ばれていない** |
| 7 | `'ライト'`/`'ライト'` で `RangeSlider.onChanged(RangeValues(2, 5))` を直接呼ぶ | コールバックに `('シナモン', 'シティ')` が渡る。続けてクリアをタップすると `(null, null)` が渡る |

あわせて `lib/utils/roast_range.dart` の純関数テストを同ファイル内(または `test/roast_range_test.dart`)に置く: `resolveMethodRoastRange` の §4.2 手順1〜5 と `methodMatchesRoastOrdinal` の境界値(範囲の両端は `true`、範囲外は `false`、未設定は `false`)。

### 8.2 既存 `test/method_template_test.dart` の更新(T3-71a)

| 対象テスト | 変更内容 |
|---|---|
| `setUp` の `methods[0]`(200行目付近) | `recommendedRoastLevel: 'シティ'` を残しつつ `recommendedRoastMin: 'ミディアム', recommendedRoastMax: 'フルシティ'` を追加 |
| `'020詳細に推奨焙煎度が表示される'` | 期待を `find.text('ミディアム 〜 フルシティ')` に変更 |
| `'020詳細の編集→021で推奨焙煎度の初期値が引き継がれる'` | 期待を `find.textContaining('ミディアム 〜 フルシティ')` に変更 |
| `'021新規登録で推奨焙煎度をスライダーで設定するとMethodMasterに保存される'` | `find.byType(Slider)` → `find.byType(RangeSlider)`、`slider.onChanged!(5.0)` → `rangeSlider.onChanged!(const RangeValues(3, 6))`、期待を `lastAddedMethod?.recommendedRoastMin == 'ミディアム'` / `recommendedRoastMax == 'フルシティ'` に変更。テスト名も「範囲を設定すると」に更新 |

**注意**: `RangeSlider` は `Slider` のサブクラスではないため、021 から `Slider` を探す既存アサーションは**必ず落ちる**。`find.byType(Slider)` の残りが無いか grep で確認すること。

### 8.3 `test/suggestion_service_test.dart` の更新(T3-71b)

- ヘルパー `_method(String id, {String? recommendedRoastLevel})` に `String? min, String? max` を追加。
- 既存の「候補メソッドが無ければ提案しない」テストは**そのまま通る**(未設定=候補外を維持したため)。
- 追加ケース(最低4件):
  1. 豆 `'ハイ'`(4.0)、メソッド範囲 `ミディアム`〜`シティ`(3〜5) → 候補になる。
  2. 豆 `'ハイ'`、メソッド範囲 `フレンチ`〜`イタリアン`(7〜8) → 候補外。
  3. 豆 `'中煎り'`(旧表記、4.0)、メソッド範囲 `ミディアム`〜`シティ` → **候補になる**(§1.3 の回帰テスト)。
  4. メソッドが旧単一値 `recommendedRoastLevel: 'ハイ'` のみで新2列が空、豆 `'ハイ'` → 候補になる(後方互換)。
- 範囲の**両端**(豆が `'ミディアム'`=下限ちょうど、`'シティ'`=上限ちょうど)が候補に入ることも確認する。

### 8.4 `test/recipe_suggestion_card_test.dart`(T3-71b)

`_defaultMethod` は `recommendedRoastLevel: '浅煎り'`(=2.0)で、対象豆も `'浅煎り'` のため**旧列フォールバックで従来どおり通る**。**無理に書き換えず、まず全件実行して通ることを確認する**。落ちた場合のみ `recommendedRoastMin: 'シナモン', recommendedRoastMax: 'シナモン'` を足す(2.0 で同値)。

### 8.5 全体

`flutter analyze` 新規 issue 0 / `flutter test` 全件パス(現状 272件+ T3-48 分の増減 + 新規9件程度)。

---

## 9. 既知の地雷(必ず読むこと)

1. **`dart run build_runner build` を実行しない** — このマシンで既知のクラッシュ(`rules/lessons_archive.md` L63)。`method_master.g.dart` は §3.2 のとおり手編集する。誤って実行して `*.g.dart` が消えたら `git checkout -- 'lib/**/*.g.dart'` で復元する。
2. **列プロビジョニングの5点セット**(`rules/lessons_archive.md` L69) — ①モデル ②`.g.dart` ③keyMap ④reverseMap ⑤GAS `EXISTING_SHEET_EXTRA_COLUMNS` + `clasp push`/`redeploy`。**GAS はヘッダーに無いキーを黙って捨て、POST は成功扱いになる**ので、列追加を忘れると「保存したのに消える」バグになる。
3. **`RangeSlider` のテーマキーは `Slider` と違う** — `rangeThumbShape` / `RoundRangeSliderThumbShape` / `rangeTickMarkShape`(§5.5)。
4. **`roastOrdinalMap` を絶対に変更しない** — F1回帰・F4 GP・F5好み検定が直接参照している。今回 `encoding.dart` は無変更。
5. **020(詳細画面)は編集→保存→pop直後に表示が更新されない**(`rules/lessons_archive.md` L89、T3-47 で実際に踏んだ)。本番確認では**019 の一覧までいったん戻って再度タップ**するか、フルリロードして確認する。「保存できていない」と誤判定しないこと。
6. **`dart format` をファイル全体にかけない** — 無関係な lint が湧く(`docs/roast_slider_design.md` §8-③)。変更箇所だけ手で整える。
7. **`.withOpacity()` を使わない** — `.withValues(alpha:)`。
8. **`[Antigravity]` ログ** — スライダー操作ごとのログは出さない。021 の保存時ログ(既存)で十分。新規ログ追加は不要。
9. **本番確認でメソッドを新規作成しない** — 既存メソッドの編集画面を開いて表示・操作を見るところまでにする。範囲を実際に保存して確かめる場合は、ユーザーが使う実メソッド1件に**妥当な範囲**を設定する(テスト用のダミーメソッドを本番に増やさない)。
10. **T3-48 の未検証差分が working tree に残っている** — T3-71b は `suggestion_service.dart` / `recipe_suggestion_card.dart` / 関連テストという**まったく同じファイル**を触る。**必ず T3-71a より前に T3-48 の `flutter analyze` → `flutter test` を通し、コミットしてから**着手すること(§11 の順序)。

---

## 10. スコープ外(今回やらないこと)

1. **030(レシピ探索、`gp_explorer_section.dart`)のメソッド別ランキングを推奨焙煎度で絞り込むこと** — T3-52 で作ったランキング表は「実際に記録があるメソッド」を GP で順位付けするものであり、推奨焙煎度は現在参照していない。範囲で絞ると記録のあるメソッドが消えて探索が痩せるおそれがあるため、今回は変更しない。必要になればユーザー要望として別タスク化する。
2. **AI によるメソッド推奨焙煎度の自動入力** — 今回は手入力のみ。
3. **豆側(012)の焙煎度を範囲にすること** — 豆の焙煎度は単一値のままで正しい(`RoastLevelSlider` は無変更)。
4. **F4/GP の湯温をメソッド依存にする改修** — T3-48 の範囲であり本書では扱わない。

---

## 11. 実装タスクへの分解

`docs/改修マスタープラン.md` §3 Phase 3 に反映済み。**いずれも Sonnet 5 で実施可能**(設計判断は本書ですべて確定済み)。

### 前提: T3-48 の仕上げ(着手順の最初)

T3-71a に入る前に、working tree に残っている T3-48 の差分を `flutter analyze` → `flutter test` → `flutter build web` で検証し、**コミットまで済ませる**(push・デプロイはしない)。T3-71b が同じファイルを触るため、ここを飛ばすと切り分けができなくなる。

### T3-71a — 推奨焙煎度の範囲化(モデル・シート・021/020 UI) (M、依存: T3-48 の検証完了)

1. 本番 `methods_master` を `curl` で取得し、旧「推奨焙煎度」列に値があるメソッドが無いことを確認(§6.3)。
2. `lib/models/method_master.dart` + `method_master.g.dart`(手編集)に2フィールド追加(§3.1・§3.2)。
3. `lib/services/sheets_service.dart` の keyMap / reverseMap **両方**に追加(§3.3)。
4. `gas/Code.gs` に2列追加(§3.4)→ **ユーザーの許可を得てから** `clasp push` + `clasp deploy --deploymentId <既存ID>` → `curl` でヘッダー増加を確認。
5. `lib/utils/roast_range.dart` を新規作成(§4)。
6. `lib/widgets/roast_level_slider.dart` の色定数を公開名に改名(§5.1)、`lib/widgets/roast_range_slider.dart` を新規作成(§5)。
7. 021 / 020 を §6 のとおり改修。
8. テスト: `test/roast_range_slider_test.dart` 新規(§8.1)、`test/method_template_test.dart` 更新(§8.2)。
9. 検証: `flutter analyze`(新規 0)→ `flutter test`(全パス)→ `flutter build web`。

**終了条件**: 021 で推奨焙煎度を範囲スライダーで設定でき、本番 `methods_master` の新2列に保存され、020 に `ミディアム 〜 フルシティ` の形式で表示される。旧単一値のメソッドを編集で開くと点として表示され、保存すると新2列へ移る。

### T3-71b — F3 の候補判定を範囲判定に差し替え (S、依存: T3-71a)

1. `lib/services/suggestion_service.dart` の絞り込みを `methodMatchesRoastOrdinal` に置換し、docコメントを更新(§7.1)。
2. `recipe_suggestion_card.dart` のコメント更新(§7.2)。
3. テスト更新・追加(§8.3・§8.4)。
4. 検証: analyze / test / build web → ローカル配信 + `claude-in-chrome` で本番 GAS 実データに対し 001 ダッシュボードのおすすめカードを確認。
5. **ユーザーの許可を得てから** `firebase deploy --only hosting` → 本番確認 → `git push`。

**終了条件**: メソッドに設定した推奨焙煎度の範囲に豆の焙煎度が含まれるときだけ、そのメソッドがおすすめレシピの候補になる。豆側が旧5段階表記でも正しく判定される。範囲未設定のメソッドは提案されない。

---

## 12. 未解決・ユーザー確認待ち

なし。§1.1 の3点をユーザー確認済みで、他に設計判断は残っていない。実装中に本書と食い違う事実(本番データ・既存コードの実態)を見つけた場合は、**発明せずユーザーに確認すること**(`CLAUDE.md` 絶対規則)。
