# 焙煎度スライダー UI 設計書 (T3-54)

最終更新: 2026-07-29 / 作成: 上位モデル(Opus 5)による T3-54 の設計実行
正本: 本書。実装タスク **T3-54a / T3-54b** はこの内容をそのまま実装すること。**本書に無い仕様を発明しない。** 不明点があれば実装を止めてユーザーに質問する。

> **このドキュメントの位置づけ**
> `docs/改修マスタープラン.md` §3 Phase 3 の T3-54(⚠️上位モデルで実施)の成果物。T3-54 のタスク本文は「スライダー化の要否・具体的なUI設計自体をこのタスクの中で検討すること」という指示だったため、本書で **①要否の結論 ②ウィジェット仕様 ③適用範囲 ④実装タスクへの分解** を確定させた。**コードは1行も書いていない**(CLAUDE.md §日次改修ループ運用ルール「モデル分担ルール」)。

---

## 1. 結論(要否の判断)

**スライダー化する。ただし素の `Slider` ではなく、専用ウィジェット `RoastLevelSlider` を新規作成して置き換える。**

### 1.1 スライダーにすべき理由

| 観点 | 現状(`ChoiceChip` 8択) | スライダー |
|---|---|---|
| 尺度の性質 | 焙煎度は **順序尺度 1.0〜8.0**(T3-42、`roastOrdinalMap`)。チップは並列選択肢に見え、順序があることが伝わらない | 位置が順序そのものを表す。「もう少し深く」という操作が直感的 |
| 縦幅 | 8個の日本語ラベルは幅が広く(`フルシティ`=5文字、`イタリアン`=5文字)、モバイル幅(約360px)では **2〜3行に折り返す** | 1行のトラック+値ラベルで固定高に収まる |
| 既存部品との整合 | — | 評価スコアが既に `MockScoreSlider`(0〜10)でスライダー。**本アプリで順序尺度をスライダーで入力するのは既存パターン**であり、焙煎度をスライダーにするほうが一貫する |
| 視覚的手がかり | 文字だけ | トラックを焙煎色グラデーションにでき、「浅い→深い」が色で分かる(§3.3) |

### 1.2 素の `Slider` では不足する点(だから専用ウィジェットにする)

1. **8個のラベルをトラック下に並べられない**。上記のとおり日本語ラベルが長く、モバイル幅では確実に潰れる。→ **端ラベル(浅い/深い)+現在値の大きな表示** に置き換える(§3.2)。
2. **`Slider` には「未設定」が無い**。012 の煎り度は任意項目で、現状のチップUIは再タップで未選択に戻せる。→ **淡色サム+クリアボタン** で表現する(§3.4、2026-07-29ユーザー決定)。
3. **保存値は文字列**(`BeanMaster.roastLevel` は `String`)であり、旧5段階表記や未知の自由入力が本番データに存在する。→ 文字列↔順序値の変換・後方互換の責務をウィジェット内に閉じ込める(§4)。

### 1.3 ユーザー決定事項(2026-07-29、`AskUserQuestion` で確認済み)

| # | 論点 | 決定 |
|---|---|---|
| ① | 未設定の表現 | **1〜8 + クリアボタン方式**(`min:1 max:8 divisions:7`)。未設定時は淡色サムを中央に置き「未設定」と表示、ラベル行右の「クリア」で未設定に戻す。※「0=未設定の9目盛り」案は不採用 |
| ② | 適用範囲 | **012 のみを T3-54a で実施。040(回帰予測フォーム)・030(レシピ探索)は T3-54b として分離**。※011 豆詳細は表示専用で、編集は 012 の編集モード(`BeanCreateScreen(editData:)`)を使うため、012 の対応で自動的にカバーされる(§5.2) |
| ③ | トラックの見た目 | **焙煎色グラデーション**(浅煎りベージュ → 深煎りダークブラウン) |

---

## 2. 変更対象ファイル一覧(確定)

| ファイル | 変更内容 | タスク |
|---|---|---|
| `lib/widgets/roast_level_slider.dart` | **新規作成**。`RoastLevelSlider` ウィジェット | T3-54a |
| `lib/services/math/encoding.dart` | 定数 `roastLevels8En` を追加(§4.1) | T3-54a |
| `lib/screens/create/bean_create_screen.dart` (012) | `MockChoiceChips`(煎り度) → `RoastLevelSlider` に置換。不要になったメンバを削除(§5.1) | T3-54a |
| `test/roast_level_slider_test.dart` | **新規作成**。ウィジェット単体テスト6件(§7.1) | T3-54a |
| `test/bean_create_screen_test.dart` | 既存テストが通ることの確認(§7.2) | T3-54a |
| `lib/widgets/statistics/regression_section.dart` (040) | `_roastDropdown()` → `RoastLevelSlider(compact: true)` | T3-54b |
| `lib/widgets/brew/gp_explorer_section.dart` (030) | 焙煎度 `DropdownButtonFormField` → `RoastLevelSlider(compact: true)` | T3-54b |

**触らないファイル**: `lib/screens/bean_detail_screen.dart`(011、§5.2)、`lib/screens/create/brew_evaluation_screen.dart`(031、焙煎度は豆から自動コピーされ入力UIが無い)、`lib/services/math/*` の統計ロジック(順序値の定義は一切変えない)。

---

## 3. `RoastLevelSlider` ウィジェット仕様

### 3.1 API(この通りに実装する)

```
ファイル: lib/widgets/roast_level_slider.dart
クラス:   class RoastLevelSlider extends StatelessWidget
```

| 引数 | 型 | 既定値 | 意味 |
|---|---|---|---|
| `value` | `String?` | (必須) | 現在の焙煎度ラベル。**生の保存値をそのまま渡す**(8段階の日本語/英語、旧5段階表記、未知の自由入力、`null`、`''` のいずれもあり得る) |
| `onChanged` | `ValueChanged<String?>` | (必須) | 値が変わったときに呼ぶ。**渡すのは常に `roastLevels8` の日本語正規ラベル**、またはクリア時の `null` |
| `label` | `String` | `'煎り度'` | ラベル行の見出し |
| `trailing` | `Widget?` | `null` | ラベル行の右端に置く任意ウィジェット。**T3-51(焙煎度説明ページ)の情報アイコンを差し込むためのスロット**。T3-54a では常に `null` のまま(§6) |
| `compact` | `bool` | `false` | `true` で横並びフォーム向けの省スペース表示(§3.5)。T3-54b で使用 |
| `enabled` | `bool` | `true` | `false` で操作不可・淡色表示 |

**必ず `StatelessWidget`(制御コンポーネント)にすること。** 内部に `_selected` 等の状態を持ってはならない。理由は §8-①(既知の地雷)。

### 3.2 通常表示(`compact: false`)のレイアウト

```
┌──────────────────────────────────────────────┐
│ 煎り度                        [クリア] [📖]  │  ← ラベル行
│                                              │
│           ミディアム (Medium)  3/8            │  ← 現在値(中央、大きめ)
│                                              │
│   ▒▒▒▒▒●▓▓▓▓▓████████████████                │  ← グラデーショントラック
│                                              │
│   浅い                                 深い   │  ← 端ラベル
└──────────────────────────────────────────────┘
```

widget ツリー(上から順):

1. **外枠**: `Padding(padding: const EdgeInsets.only(bottom: 14))` — `MockChoiceChips` / `MockTextField` と同じ下マージンにして他フォーム項目と行間を揃える。中身は `Column(crossAxisAlignment: CrossAxisAlignment.start)`。
2. **ラベル行**: `Row` — 左に `Text(label, style: TextStyle(fontSize: 13, color: kMocha))`(`MockChoiceChips` のラベルと同一スタイル)、`Spacer()`、クリアボタン(§3.4)、`if (trailing != null) trailing!`。
3. `const SizedBox(height: 4)`
4. **現在値表示**: 横幅いっぱいの `Center`(§3.4 に文言規則)。
5. **トラック**: §3.3。
6. **端ラベル行**: `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('浅い'), Text('深い')])`、いずれも `TextStyle(fontSize: 11, color: kMocha)`。左右に `EdgeInsets.symmetric(horizontal: 12)` のパディングを入れてトラック端と揃える。

色定数は既存の `lib/screens/create/create_form_widgets.dart` のもの(`kEspresso` `kMocha` `kLatte` `kCream` `kAccent`)を import して使う。**新しいテーマファイルを作らない。**

### 3.3 グラデーショントラックの実装方法(この方式で作ること)

`SliderTrackShape` を自作すると煩雑なため、**「グラデーションの `Container` を背面に敷き、トラックを透明にした `Slider` を前面に重ねる」** 方式で実装する。

```
SizedBox(
  height: 40,
  child: Stack(
    alignment: Alignment.center,
    children: [
      // 背面: グラデーションバー
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(colors: [kRoastLightest, kRoastDarkest]),
          ),
        ),
      ),
      // 前面: トラックを透明にした Slider
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 8,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          activeTickMarkColor: Colors.white.withValues(alpha: 0.7),
          inactiveTickMarkColor: Colors.white.withValues(alpha: 0.7),
          thumbColor: <§3.4 の規則>,
          overlayColor: kAccent.withValues(alpha: 0.2),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        ),
        child: Slider(min: 1, max: 8, divisions: 7, value: <§4.2>, onChanged: <§4.3>),
      ),
    ],
  ),
)
```

- **新規色定数**(`roast_level_slider.dart` の先頭にファイルプライベートで定義してよい):
  - `const kRoastLightest = Color(0xFFC8A87C);` (浅煎りのベージュ)
  - `const kRoastDarkest  = Color(0xFF3B2314);` (深煎りのダークブラウン)
- `horizontal: 12` は `Slider` 内部のサム半径ぶんの余白に合わせた値。**実機/ブラウザで見てトラック端とグラデーション端がずれていたら 10〜14 の範囲で微調整してよい**(ここだけは目視調整を許可する)。
- `.withValues(alpha:)` を使うこと(`.withOpacity()` は非推奨。既存コード `create_form_widgets.dart:290` に倣う)。
- `enabled: false` のときはグラデーションを `Opacity(opacity: 0.4)` で包む。

### 3.4 現在値表示・サム色・クリアボタンの規則(状態別、これがすべて)

`value` を §4.2 の手順で順序値 `o`(`double?`)に解決したうえで、次の3状態に分岐する。

| 状態 | 条件 | 現在値表示 | Slider の `value` | サム色 | クリアボタン |
|---|---|---|---|---|---|
| **A: 設定済み** | `o != null` | `'${roastLevels8[o.toInt()-1]} (${roastLevels8En[o.toInt()-1]})  ${o.toInt()}/8'`<br>例: `ミディアム (Medium)  3/8`<br>`TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kEspresso)` | `o` | `kEspresso` | **有効** |
| **B: 未設定** | `value == null \|\| value!.isEmpty` | `'未設定(スライダーを動かして選択)'`<br>`TextStyle(fontSize: 13, color: kMocha)` | `4.0`(中央寄りの既定位置。**この値は保存されない**) | `kLatte`(淡色) | **無効**(`onPressed: null`) |
| **C: 未知の値** | `value` が非空だが `roastOrdinalMap` に無い | `'未設定(登録値: 「${value}」)'`<br>`TextStyle(fontSize: 13, color: kMocha)` | `4.0` | `kLatte`(淡色) | **有効**(押すと `onChanged(null)`) |

- **クリアボタン**: `TextButton(child: const Text('クリア', style: TextStyle(fontSize: 12)), onPressed: <上表>)`。押下時は `onChanged(null)` を呼ぶ。`compact: true` のときは **表示しない**(§3.5)。
- **状態Cが重要**: 未知の文字列を勝手に消してはならない。ウィジェットは「未設定として表示するが `onChanged` は呼ばない」ため、ユーザーがスライダーを触らずに保存すれば **元の文字列がそのまま保存される**(§4.4)。

### 3.5 コンパクト表示(`compact: true`、T3-54b 用)

040/030 は複数の入力が `Row` で横並びになっており、通常表示のままでは縦幅が増えてレイアウトが崩れる。`compact: true` では:

- 現在値を**中央の大きな表示ではなくラベル行の右側にインライン表示**する: `煎り度  ミディアム 3/8`(`fontSize: 13, fontWeight: FontWeight.bold, color: kEspresso`)。
- **端ラベル行(浅い/深い)を省略**する。
- **クリアボタンを表示しない**(040/030 は既定値が必ずあり未設定になり得ないため)。
- トラック部分の `SizedBox` の高さを `40` → `32`、`thumbShape` の `enabledThumbRadius` を `10` → `8` にする。
- 全体の高さの目安は 56px 前後。`Expanded` の中に置いても壊れないよう、固定幅を持たせないこと。

---

## 4. 文字列 ↔ 順序値の変換規則(後方互換の要)

### 4.1 `encoding.dart` への追加(T3-54a)

`lib/services/math/encoding.dart` に、既存の `roastLevels8` の直後に以下を追加する。**順序は `roastLevels8` と1対1に対応させること**(index が同じ = 同じ焙煎度)。

```
/// 新8段階の英語表記(浅い順)。roastLevels8 と同じ index が同じ段階を指す。
/// T3-54(焙煎度スライダー)の値表示で「ミディアム (Medium)」のように併記するために使う。
const List<String> roastLevels8En = [
  'Light',
  'Cinnamon',
  'Medium',
  'High',
  'City',
  'Full City',
  'French',
  'Italian',
];
```

**注意**: これは `roastOrdinalMap` の英語キーと同じ綴り(`Full City` はスペース入り)。`roastOrdinalMap` 自体は**一切変更しない**(統計処理 F1/F4/F5 が直接参照しているため)。

### 4.2 `value`(String?) → 順序値 `o`(double?)

```
1. value が null または空文字列 → o = null (状態B)
2. roastOrdinalMap[value] を引く
   - ヒットした → o = その値
     ※ これにより次がすべて正しく解決される:
       ・新8段階の日本語   'ミディアム' → 3.0
       ・新8段階の英語     'Medium'     → 3.0
       ・旧5段階の日本語   '中煎り'     → 4.0 (= ハイ)
   - ヒットしない → o = null (状態C)
3. 念のため o が 1.0〜8.0 の範囲外なら o = null として扱う(現状の map には該当なし)
```

**旧5段階 → 新8段階の対応**(`roastOrdinalMap` に定義済み、再確認用): 浅煎り→2.0(シナモン) / 中浅煎り→3.0(ミディアム) / 中煎り→4.0(ハイ) / 中深煎り→5.0(シティ) / 深煎り→7.0(フレンチ)。

### 4.3 Slider 操作 → `onChanged` に渡す値

```
onChanged: enabled ? (double v) => onChanged(roastLevels8[v.round() - 1]) : null
```

- `divisions: 7` があるため `v` は 1.0〜8.0 の整数値になるが、**必ず `.round()` を経由**して index 計算する(浮動小数の誤差で `7.999...` → index 6 になる事故を防ぐ)。
- 渡すのは**常に日本語の正規ラベル**。英語表記や旧表記を保存値として書き戻すことはしない。

### 4.4 保存時の挙動(仕様として明記、Sonnet が驚かないように)

| 編集前の保存値 | ユーザーの操作 | 保存後の値 |
|---|---|---|
| `'中煎り'`(旧5段階) | スライダーを触らない | `'中煎り'` のまま(**書き換えない**) |
| `'中煎り'` | スライダーを触った(位置は 4 = ハイのまま) | `'ハイ'` に正規化される |
| `'謎の焙煎'`(未知) | 触らない | `'謎の焙煎'` のまま |
| `'謎の焙煎'` | クリアを押した | `''`(012 側で `_roastLevel ?? ''` として保存) |
| `null` | スライダーを操作 | 選んだ8段階の日本語ラベル |

**「触ったときだけ正規化される」のは意図した仕様**であり、バグではない。旧表記のまま残っても `roastOrdinalMap` が解決するので統計処理には影響しない。

---

## 5. 画面ごとの適用方法

### 5.1 012 豆登録/編集 (`lib/screens/create/bean_create_screen.dart`) — T3-54a

**置換前**(現状 488〜493 行目付近):
```
MockChoiceChips(
  label: '煎り度',
  options: _roastChoices,
  initialValue: _roastLevel,
  onChanged: (v) => _roastLevel = v,
),
```

**置換後**:
```
RoastLevelSlider(
  value: _roastLevel,
  onChanged: (v) => setState(() => _roastLevel = v),
),
```

**⚠️ `setState` を必ず付けること。** 現状の `MockChoiceChips` は内部状態で自分の見た目を更新するため呼び出し側が `setState` していないが、`RoastLevelSlider` は制御コンポーネントなので **`setState` が無いとサムが動かない**。ここを写し間違えると「スライダーが動かない」不具合になる。

**あわせて削除するもの**(いずれも煎り度専用で他に使われていないことを確認済み):

| 場所 | 削除内容 |
|---|---|
| 34行目付近 | `static const _roastOptions = roastLevels8;` |
| 40行目付近 | `late List<String> _roastChoices;` のフィールド宣言 |
| 72行目付近(`initState`内) | `_roastChoices = _withCurrentValue(_roastOptions, _roastLevel);` |
| 83行目付近 | `static List<String> _withCurrentValue(...)` メソッド本体<br>※**このファイル内のものだけ削除**。`dripper_create_screen.dart` / `filter_create_screen.dart` にも同名の static メソッドがあるが、そちらは材質・形状・サイズで使用中なので**絶対に消さない** |
| 314行目付近(AI抽出の `setState` 内) | `_roastChoices = _withCurrentValue(_roastOptions, _roastLevel);` の1行だけ削除。**`_roastLevel = extracted.roastLevel;` と `filled.add('煎り度');` は残す** |
| 13行目 | `import '../../services/math/encoding.dart';` — `roastLevels8` の参照が無くなり未使用 import になるので**削除する**(`flutter analyze` が `unused_import` を出す) |

**副次的なバグ修正(意図した効果)**: 現状、AI 自動入力(「パッケージ画像から自動入力(AI)」)で焙煎度が抽出されても、`MockChoiceChips` は `initialValue` を `initState` でしか読まないため **チップの選択が画面上で更新されない**(SnackBar には「自動入力しました: 煎り度」と出るのに選択が変わらない)。`RoastLevelSlider` は制御コンポーネントなので、この置換で自動的に直る。**walkthrough / NEXT_SESSION にこの修正効果を記載すること。**

### 5.2 011 豆詳細 (`lib/screens/bean_detail_screen.dart`) — 変更なし(スコープ外)

- 011 は `MasterDetailTemplate` の `fields: [('煎り度', bean.roastLevel), ...]`(`(String, String)` タプルのリスト)で表示するだけの**表示専用画面**。焙煎度の**編集は `onEdit` から `BeanCreateScreen(editData: bean)` すなわち 012 の編集モードに遷移して行う**ため、T3-54a で 012 を直せば「011 の焙煎度入力」も同時に満たされる(T3-54 の終了条件「012/011 の入力がスライダーで行える」はこれで達成)。
- `MasterDetailTemplate.fields` は豆・グラインダー・ドリッパー・フィルター・メソッドの**5マスター共通の API** であり、ここを widget 対応に変えると CLAUDE.md の「全マスタータブへの一律適用」の影響範囲が一気に広がる。**読み取り専用ゲージ表示にする案は今回採用しない。**

### 5.3 040 統計 / 030 抽出 — T3-54b(別タスク)

| 画面 | 現状 | 置換後 |
|---|---|---|
| 040 `lib/widgets/statistics/regression_section.dart` の `_roastDropdown()`(565行目付近) | `DropdownButtonFormField<String>`、`_roastLabel` を保持 | `RoastLevelSlider(value: _roastLabel, compact: true, onChanged: (v) => setState(() => _roastLabel = v ?? _roastLabel))` |
| 030 `lib/widgets/brew/gp_explorer_section.dart`(123行目付近) | `DropdownButtonFormField<String>`、`_selectedRoast`(既定 `'ハイ'`) | `RoastLevelSlider(value: _selectedRoast, compact: true, onChanged: (v) => setState(() => _selectedRoast = v ?? 'ハイ'))` |

- 030 側の `static const _roastOptions = <(String, double)>[...]`(38〜48行目)は、ドロップダウン構築にしか使っていないなら削除する。**ただし `roastOrdinalMap[_selectedRoast]` を使う 102 行目のロジックは残す**(順序値への変換はそのまま必要)。
- 両画面とも `null` にはならない(`?? 既定値` で吸収する)ので、`compact: true` によりクリアボタンは出ない。
- **レイアウト確認が必須**: どちらも `Row` + `Expanded` の中にあるため、縦幅が増えてオーバーフロー(黄黒ストライプ)が出ていないかブラウザで必ず目視する。

---

## 6. T3-51(焙煎度説明ページ)との連携

T3-54 の検討事項③「041の焙煎度説明ページ(T3-51)への導線をスライダー上でどう確保するか」への結論:

- **`RoastLevelSlider` に `trailing` スロットを用意するだけにし、T3-54a は T3-51 に依存させない。** T3-54a の時点では `trailing: null`(何も表示されない)。
- **T3-51 の実装時に**、`StatsTheoryLink`(`lib/screens/stats_theory_screen.dart:38`)と同型の小さな `IconButton`(`Icons.menu_book_outlined`, `size: 20`, `color: kAccent`, `visualDensity: VisualDensity.compact`)を作り、012 の呼び出し側で `RoastLevelSlider(trailing: const RoastGuideLink(), ...)` として差し込む。**`RoastLevelSlider` 自身は改修不要。**
- T3-51 の説明ページの画面IDは **`044`** を割り当てる(`lib/routing/app_screen.dart` の使用済みIDは 040=統計 / 041=統計の理論 / 042=統計処理の稼働状況 / 043=Geminiモデル設定 まで。045 以降と 029・032〜039 が空き)。この決定は `docs/改修マスタープラン.md` の T3-51 の行にも反映済み。

---

## 7. テスト計画

### 7.1 新規 `test/roast_level_slider_test.dart`(T3-54a、6件)

**スライダーの操作は `await tester.drag(...)` を使わないこと**(ドラッグ量とdivisionsの対応が環境依存で不安定)。代わりに **`tester.widget<Slider>(find.byType(Slider)).onChanged!(5.0)` のようにコールバックを直接呼ぶ**。

| # | 入力 | 期待 |
|---|---|---|
| 1 | `value: null` | `'未設定(スライダーを動かして選択)'` が表示される / `Slider.value == 4.0` / クリアボタンの `onPressed` が `null` |
| 2 | `value: 'ミディアム'` | `'ミディアム (Medium)  3/8'` を含むテキストがある / `Slider.value == 3.0` |
| 3 | `value: '中煎り'`(旧5段階) | `'ハイ (High)  4/8'` を含むテキストがある / `Slider.value == 4.0`(**後方互換の回帰テスト**) |
| 4 | `value: '謎の焙煎'`(未知) | `'謎の焙煎'` を含む未設定表示になる / `Slider.value == 4.0` / この時点で `onChanged` は**呼ばれていない** |
| 5 | `value: 'ライト'` で `Slider.onChanged(5.0)` を直接呼ぶ | コールバックに `'シティ'` が渡る(index=4) |
| 6 | `value: 'ライト'` でクリアボタンをタップ | コールバックに `null` が渡る |

`compact: true` の表示テストは T3-54b で追加する(端ラベルとクリアボタンが無いこと)。

### 7.2 既存テストへの影響(T3-54a)

- `test/bean_create_screen_test.dart` の 239 行目付近に `roastLevel: '中煎り'` を持つ編集データのケースがある。**ChoiceChip を直接探すアサーションは無いことを確認済み**だが、実装後に必ず全件実行して通ることを確認する。
- 焙煎度の順序値を使う統計テスト(`test/math/encoding_test.dart`, `test/math/design_matrix_test.dart`, `test/regression_section_test.dart`, `test/gp_explorer_section_test.dart`)は **`roastOrdinalMap` を変更しないため影響しない**。もし落ちたら「変えてはいけないものを変えた」サインなので差分を見直すこと。
- 既存テスト全203件がパスすること。

---

## 8. 既知の地雷(過去に踏んだもの。必ず読むこと)

1. **`initialValue` は再ビルドで反映されない** — `TextFormField.initialValue` や、`initState` でしか `initialValue` を読まない自前の StatefulWidget(`MockChoiceChips` がまさにこれ)は、親が `setState` しても表示が更新されない。T3-58 の根本原因でもある。**だから `RoastLevelSlider` は必ず `StatelessWidget`(制御コンポーネント)にする。**
2. **呼び出し側の `setState` 忘れ** — 上記の裏返し。012 では `onChanged: (v) => setState(() => _roastLevel = v)` と書く(§5.1)。
3. **`dart format` をファイル全体にかけない** — 2026-07-27(NEXT_SESSION -4.69節)に、既存ファイル全体を整形した結果、無関係な箇所で新規 lint 4件(`curly_braces_in_flow_control_structures`)が発生した。**変更した箇所だけ手で整えること。**
4. **`roastOrdinalMap` を絶対に変更しない** — F1回帰・F4 GP・F5好み検定が直接参照している。今回追加するのは `roastLevels8En` のみ。
5. **`.withOpacity()` は使わない** — 非推奨。`.withValues(alpha: ...)` を使う(既存コードに倣う)。
6. **`[Antigravity]` ログ** — スライダー操作は高頻度なので毎回ログを出さない。012 の保存時ログ(既存)に焙煎度が含まれていればそれで十分。新規のログ追加は不要。
7. **`flutter build web` 後の目視確認では新規データを作らない** — テストデータ削除タスク(T3-46)が未完のため、確認は**既存豆の編集画面を開いてスライダーの表示・操作を見るところまで**にし、保存はしない(または元の値に戻して保存する)。本番 `bean_master` にテスト豆を増やさないこと。
8. **オーバーフロー確認** — スライダーは `Row`/`Expanded` の中で幅を要求する。012 は縦積みなので問題ないが、T3-54b の 040/030 では黄黒ストライプが出ていないか必ずブラウザで確認する。

---

## 9. 実装タスクへの分解

`docs/改修マスタープラン.md` §3 Phase 3 に反映済み。**いずれも Sonnet 5 で実施可能**(設計判断は本書ですべて確定済み)。

### T3-54a — `RoastLevelSlider` の新規作成と 012 への適用 (M、依存: なし)

1. `lib/services/math/encoding.dart` に `roastLevels8En` を追加(§4.1)。
2. `lib/widgets/roast_level_slider.dart` を新規作成(§3・§4)。`compact` 分岐も**このタスクで作り込む**(T3-54b で使うため)。
3. `lib/screens/create/bean_create_screen.dart` を §5.1 の表のとおり置換・削除。
4. `test/roast_level_slider_test.dart` を新規作成(§7.1、6件)。
5. 検証: `flutter analyze`(新規issue 0)→ `flutter test`(203+6件パス)→ `flutter build web` → ローカル配信+`claude-in-chrome` で 012 を目視(§8-⑦の制約に従う)。
6. デプロイ(`firebase deploy --only hosting`)→ 本番確認。

**終了条件**: 012 の煎り度がスライダーで入力でき、旧5段階表記の既存豆を編集しても正しい段階が表示され、AI 自動入力で抽出された焙煎度がスライダーに即座に反映される。

### T3-54b — 040/030 の焙煎度入力をコンパクトスライダーに統一 (S〜M、依存: T3-54a)

1. §5.3 の表のとおり 2 ファイルを置換。
2. `test/roast_level_slider_test.dart` に `compact: true` の表示テスト2件(端ラベルが無い・クリアボタンが無い)を追加。
3. 既存の `test/regression_section_test.dart` / `test/gp_explorer_section_test.dart` が通ることを確認(ドロップダウンを探すアサーションがあれば差し替え)。
4. 検証: analyze / test / build web →ブラウザで 040 と 030 のレイアウト崩れ(オーバーフロー)が無いことを目視。

**終了条件**: 040 の回帰予測フォームと 030 のレシピ探索の焙煎度選択がスライダーになり、予測結果・ヒートマップが従来どおり更新され、レイアウト崩れが無い。

---

## 10. 未解決・ユーザー確認待ち

なし。§1.3 の3点をユーザー確認済みで、他に設計判断は残っていない。
