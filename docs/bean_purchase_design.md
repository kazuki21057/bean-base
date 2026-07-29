# 追加購入フローと購入履歴の統合設計(T3-61)

作成: 2026-07-29 / 上位モデル(Opus 5)による設計タスク **T3-61** の成果物
正本: 本書。T3-62〜T3-65 の実装は**本書の記述をそのまま実装**し、レイアウト・フィールド名・列名を新規に検討しないこと。

## 0. 背景と、この設計が解く問題

現状のデータモデルは **豆1件 = 1回の購入** を前提にしている(`BeanMaster` が `purchaseDate` / `roastDate` / `initialQuantityGrams` を各1つずつ持つ)。そのため「同じ豆を買い足す」という運用が表現できず、買い足しても残量は増えず、購入日も古いままになる。

ユーザー要望は次の2つで、**どちらも「1回の購入イベント」を扱うため統合して設計する**。

1. 011(豆詳細)に**追加購入ボタン**を置き、押すと購入日・焙煎日・購入量を入力するダイアログが出る。入力すると既存の購入日・焙煎日が**更新**され、購入量が現在の残量に**加算**される。
2. **購入履歴**をリスト形式・カレンダー形式で追えるページ(購入日・購入豆・購入先が分かる)。

追加購入のたびに購入履歴へ1行追記される形にすることで、両者を1つのデータ基盤に載せる。

## 1. ユーザー承認済みの決定事項(2026-07-29)

| # | 論点 | 決定 |
|---|---|---|
| ① | カレンダーの実装方式 | **外部パッケージ `table_calendar` を追加する**(自前 GridView ではない) |
| ② | 既存の豆(23件超)の遡及登録 | **遡及登録する**。移行スクリプトで既存豆の「初回購入」を1行ずつ作る |
| ③ | 025 への導線 | **010(豆管理一覧)の AppBar + マスター管理ハブ**の2箇所(ナビゲーションのタブは増やさない) |
| ④ | 追加購入ダイアログでの購入店入力 | **入力できるようにする**(既定=豆の現在の購入店)。履歴には**店IDと店名の両方**を保存する |

タスク文の検討事項①〜⑥のうち、②(豆マスタ側の扱い)・④(ダイアログUI)・⑤(025の画面構成)・⑥(導線の具体)は本書 §3〜§7 で確定させた。

---

## 2. データモデル: `BeanPurchase` / シート `bean_purchases`

### 2.1 シート列定義(9列、**この順**)

`gas/Code.gs` の `ALLOWED_SHEETS` に `'bean_purchases'` を追加し、`NEW_SHEET_HEADERS['bean_purchases']` に以下を**この順で**定義する(`ensureSheet_` が初回POST時に自動生成する既存の仕組みに乗る)。

| # | シート列名 | フィールド名 | 型 | 必須 | 備考 |
|---|---|---|---|---|---|
| 1 | `購入ID` | `id` | String | ✓ | 新規: `bp_<millisSinceEpoch>` / 初回購入・遡及: `bp_init_<豆ID>` |
| 2 | `豆ID` | `beanId` | String | ✓ | `BeanMaster.id`。**数字だけの値になるため `_parseString` 必須**(§2.3) |
| 3 | `購入日` | `purchasedAt` | DateTime? | ✓ | ISO8601 で保存 |
| 4 | `焙煎日` | `roastDate` | DateTime? | | 未入力可 |
| 5 | `購入量(g)` | `quantityGrams` | double? | | 未入力可 |
| 6 | `購入店ID` | `storeId` | String | | `StoreMaster.id`。未選択・遡及登録時は空 |
| 7 | `購入店名` | `storeName` | String | | **表示用スナップショット**。これがあるため 025 は T3-69 を待たずに購入先を表示できる |
| 8 | `メモ` | `memo` | String | | |
| 9 | `登録日時` | `createdAt` | DateTime? | | この履歴行を作成した時刻 |

**豆名・豆画像は保存しない**(`beanId` から `beanMasterProvider` で都度解決する。豆名変更時に履歴が古い名前のまま残るのを避けるため)。購入店だけは店マスタ未整備の既存データがあるため、例外的に名前をスナップショットする。

### 2.2 モデルファイル

`lib/models/bean_purchase.dart`(+ `bean_purchase.g.dart` は**手書きでよい**。このマシンでは `build_runner` が不安定 = T3-34 の教訓)。`copyWith` は全9フィールド分用意する。

### 2.3 過去に踏んだ地雷(必ず守ること)

- **`String` フィールドはすべて `@JsonKey(defaultValue: '', fromJson: _parseString)`**(`BeanMaster._parseString` をコピー)。特に **`beanId` は `DateTime.now().millisecondsSinceEpoch.toString()` 由来で数字のみ**のため、Sheets が数値セルに変換して返し、素の `as String?` キャストだと実データ取得時に型キャストエラーで落ちる(T3-67 の `openedYear`・`FilterMaster.size` と同型の既知パターン)。`storeId` / `storeName` / `memo` も同様に `_parseString` にしておく。
- 日付は `BeanMaster._parseDate` をコピーして使う(`/` 区切り・スペース区切りの Sheets 表記を吸収する)。`toJson` 側は `toIso8601String()`。
- `double?` は `BeanMaster._parseDouble` をコピー。

### 2.4 DataService / SheetsService / Provider

- `lib/services/data_service.dart` に `getBeanPurchases()` / `addBeanPurchase(BeanPurchase)` / `updateBeanPurchase(BeanPurchase)` / `deleteBeanPurchase(String id)` を追加。
- `SheetsService` は `_storeKeyMap` / `getStores` / `_reverseMapStore` と**完全に同じ形**で実装する(`_beanPurchaseKeyMap` → `_fetchData('bean_purchases', ...)` → `_reverseMapBeanPurchase` → `_postData`)。**keyMap から reverseMap を生成する方式**なので、9列分のマッピングを1箇所書けばよい。`deleteBeanPurchase` は `{'購入ID': id}` を投げる。
- `FirestoreService`(レガシー)にも `UnimplementedError` スタブを4つ追加する(コンパイルエラー回避。既存の `fetchOriginMasters` / `getStores` と同じ扱い)。
- **`test/` 配下の `_FakeDataService`(12個以上ある)すべてに4メソッドの空実装を追加**する必要がある(T3-67 で実際に踏んだ作業。忘れると全テストがコンパイルエラーになる)。
- `lib/providers/data_providers.dart` に以下を追加(`StoreMasterNotifier` と同型)。

```
class BeanPurchaseNotifier extends OptimisticListNotifier<BeanPurchase> {
  fetch() => ref.watch(dataServiceProvider).getBeanPurchases();
  idOf(item) => item.id;
}
final beanPurchasesProvider = AsyncNotifierProvider<BeanPurchaseNotifier, List<BeanPurchase>>(...);
```

---

## 3. 豆マスタ側の扱い(検討事項②の決定)

**「最新購入の値で上書きし続ける」方針を採用する**(履歴からの導出には切り替えない)。理由: `BeanMaster.roastDate` は統計処理の鮮度算出(`brewedAt.difference(roastDate).inDays`)が直接参照しており、導出に切り替えると後方互換が壊れるため。豆マスタは常に「最新ロットの状態」を表す、と定義する。

追加購入1回で豆マスタに対して行う更新は以下のとおり。

| フィールド | 追加購入時の扱い |
|---|---|
| `purchaseDate` | 入力された購入日で**上書き** |
| `roastDate` | 入力された焙煎日で**上書き**。ただし**焙煎日が未入力なら上書きしない**(既存値を保持) |
| `initialQuantityGrams` | **変更しない**(「初回購入時の量」の意味のまま残す) |
| `stockBaselineGrams` | `calculateBeanRemainingGrams(bean, records) + 購入量` (T3-60 の基盤をそのまま使う) |
| `stockBaselineAt` | `DateTime.now()` |
| `isInStock` | 購入量 > 0 なら `true`(在庫ありに戻す) |
| `store` | 購入店を選択した場合、その**店名で上書き**する |
| `storeId` | **T3-69 で `BeanMaster` に追加された後**、選択した店IDで併せて上書きする(T3-69 の作業に含める) |

### 3.1 書き込み順序と失敗時の扱い(重要)

**必ず「① `addBeanPurchase`(履歴追記) → ② `updateBean`(豆マスタ更新)」の順で行う。**

- ① が失敗した場合: 何も変更せず中断し、日本語エラー SnackBar を出す。
- ① 成功・② 失敗の場合: 「購入履歴は記録しましたが、豆の残量・購入日の更新に失敗しました。もう一度お試しください」と SnackBar で明示し、`[Antigravity] Error:` で豆ID・購入日・購入量をログに残す。
- **この順序が安全な根拠**: 在庫基準点は「現在の残量 + 購入量」という**絶対値**として書き込むため、② が失敗した状態で再実行しても `calculateBeanRemainingGrams` の結果が変わらず、**二重加算にならない**。リトライで生じうる副作用は 025 に履歴行が1行重複することだけで、購入IDが異なるため識別可能。

② の保存は T3-45 の `updateOptimistic`、① は `addOptimistic` を使い、一覧・ダッシュボードに即時反映させる。

---

## 4. 追加購入ダイアログ(011)の仕様(検討事項④の決定)

### 4.1 導線

`BeanDetailScreen`(011)の `extraSections` の**「残量調整」セクション内**に、既存の「残量を調整」ボタンと並べて **「追加購入」ボタン**(`FilledButton`)を置く。セクションのタイトルは `'残量調整'` から **`'在庫・購入'`** に変更し、アイコンは `Icons.inventory_2_outlined` にする。行構成:

```
現在の残量: 85.5g            [追加購入] [残量を調整]
```

(狭い画面で溢れないよう、`Row` ではなく `Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end)` にボタン2つを入れ、テキストは `Expanded` のまま残す。)

### 4.2 ダイアログの入力項目

`_AddPurchaseDialog`(`StatefulWidget`)として実装する。**関数内で `showDialog` した直後に `TextEditingController.dispose()` してはならない**(T3-60 で踏んだ既知の不具合。ダイアログを閉じるアニメーション中に例外になる)。

| 項目 | ウィジェット | 既定値 | 必須 |
|---|---|---|---|
| 購入日 | `showDatePicker` を開くタップ可能な行 | **今日** | ✓ |
| 焙煎日 | `showDatePicker` を開くタップ可能な行 + クリアボタン | 空(未入力) | |
| 購入量(g) | `TextField`(`numberWithOptions(decimal: true)`) | 空 | ✓ |
| 購入店 | `DropdownButtonFormField<String>`(`storeMasterProvider` から。先頭に「(選択しない)」) | **豆の現在の `store` と店名が一致する店**。一致が無ければ「(選択しない)」 | |
| メモ | `TextField`(1行) | 空 | |

バリデーション(いずれも日本語 SnackBar、`SnackBarBehavior.floating` + 下マージン 80 = T3-44 の教訓):
- 購入量が未入力・数値でない・0以下 → 「購入量を正しく入力してください」
- 焙煎日が購入日より**後**の場合 → 「焙煎日は購入日より前の日付にしてください」

ダイアログ下部に**確認表示**として `現在の残量 85.5g → 285.5g` のように加算後の残量をライブで表示する(購入量の入力に追従)。

### 4.3 保存時の処理

§3 のとおり、① `bean_purchases` へ1行追記 → ② 豆マスタ更新、を1操作で行う。成功時は「追加購入を記録しました」の SnackBar。`[Antigravity] Action: 追加購入を記録 (豆ID=..., 購入量=...g, 購入店=...)` をログに出す。

011 は T3-60 で `beanMasterProvider` を `ref.watch` して最新の豆を都度解決する形になっているため、**画面を離れずに残量表示が即座に更新される**(追加の対応は不要)。

---

## 5. 初回購入の記録と既存豆の遡及登録(検討事項③の決定)

### 5.1 012(新規豆追加)での初回購入の記録

**新規登録時のみ**、豆の保存に成功したあと購入履歴を1行追記する(編集モードでは作らない)。

- `購入ID` = **`bp_init_<豆ID>`**
- `購入日` = 入力された `purchaseDate` / `焙煎日` = `roastDate` / `購入量(g)` = `initialQuantityGrams`
- `購入店ID` = 空(T3-69 まで) / `購入店名` = 入力された `store`
- `メモ` = 空 / `登録日時` = 現在時刻
- **購入日が未入力の場合は履歴行を作らない**(025 に表示できないため)
- 履歴追記に失敗しても**豆の登録自体は成功扱いにする**(SnackBar で「豆を登録しましたが購入履歴の記録に失敗しました」と出し、`[Antigravity] Error:` を残す)

ID を `bp_init_<豆ID>` 固定にすることで、§5.2 の移行スクリプトを後から流しても**衝突・重複しない**(既存IDとしてスキップされる)。

### 5.2 遡及登録スクリプト `tools/migrate_bean_purchases.dart`

`tools/migrate_stores.dart` と**同型**(`SheetsService` は `flutter_riverpod` → `dart:ui` 依存で素の `dart run` からロードできないため、`package:http` で GAS を直接叩く独立実装にする。**302リダイレクトの手動フォロー必須**)。

- 対象: 本番 `bean_master` の全行のうち **`購入日` が非空** のもの
- 生成する行: `購入ID` = `bp_init_<豆ID>` / `豆ID` / `購入日` / `焙煎日` / `購入量(g)` = `初期購入量(g)` / **`購入店ID` = 空** / `購入店名` = `購入店舗` の値をそのまま / `メモ` = `既存データからの遡及登録` / `登録日時` = 実行時刻
- 冪等: 実行のたび `bean_purchases` の既存 `購入ID` セットを取得し、未投入のものだけ追加する。2回目の実行で `added=0` になることを必ず確認する
- **実行前に対象一覧(豆名・購入日・購入量・購入店)をユーザーに提示する**

`購入店ID` を空のままにするのは、名寄せ規則(`docs/store_master_design.md` §3.2)の適用を T3-69 に一本化するため。**T3-69 で `tools/migrate_bean_store_id.dart` を拡張し、同じ名寄せ規則で `bean_purchases.購入店ID` も併せて埋めること。**

---

## 6. 購入履歴ページ 025(検討事項⑤の決定)

### 6.1 共通

- `lib/routing/app_screen.dart` に `beanPurchaseHistory('025', '購入履歴'),` を追加(`025` は T3-68 の時点から本タスク用に予約済み)。位置は `grinderNew('024', ...)` と `storeList('026', ...)` の間。
- `lib/routing/screen_registry.dart` に1件 case を追加。
- 画面ファイル: `lib/screens/bean_purchase_history_screen.dart`(クラス名 `BeanPurchaseHistoryScreen`)。
- `MockScreenScaffold(screen: AppScreen.beanPurchaseHistory, children: [...])` を使う(FAB は置かない。購入の登録は 011 の追加購入と 012 からのみ)。
- **`MasterSwitcherButton._entries` には追加しない**。購入履歴はマスターではないため、CLAUDE.md の「全マスタータブへの一律適用」規約の対象外。
- 表示順の基準は常に **`purchasedAt` の降順**。
- 空状態は「購入履歴がありません」。

### 6.2 リスト / カレンダーの切替

`children` の先頭に `SegmentedButton<_PurchaseViewMode>` を置く(`_PurchaseViewMode { list, calendar }`)。

- `list`: `Icons.list` + ラベル `'リスト'`
- `calendar`: `Icons.calendar_month` + ラベル `'カレンダー'`
- 既定は `list`。`ConsumerStatefulWidget` の `setState` で切り替える。

### 6.3 リスト形式(T3-64)

`beanPurchasesProvider` + `beanMasterProvider` を `watch` し、購入日の新しい順に `MockListRow` を並べる。

| 引数 | 値 |
|---|---|
| `icon` | `Icons.coffee` |
| `imageUrl` | 該当豆の `imageUrl`(`ImageUtils.getOptimizedImageUrl` を通す。T3-14/T3-22 と同じパターン) |
| `title` | 豆名(`beanId` から解決。見つからなければ `'(削除された豆)'`) |
| `subtitle` | `'2026/07/29 · Navy · 200.0g · 焙煎 07/25'` 形式。**購入店名が空の要素・焙煎日が null の要素は `·` ごと省略**する(`[...].where((e) => e.isNotEmpty).join(' · ')`) |
| `onTap` | 011(`BeanDetailScreen(bean: 該当豆)`)へ `Navigator.push`。豆が見つからない場合は `onTap: null` |

絞り込み(保存場所 T3-59・期間)は**実装しない**(スコープを膨らませない)。月ごとの見出しも付けない。

### 6.4 カレンダー形式(T3-65)

`table_calendar` の `TableCalendar` を使う。

| 引数 | 値 |
|---|---|
| `firstDay` | 購入履歴の最古の `purchasedAt`。履歴が空なら `DateTime.utc(今年 - 1, 1, 1)` |
| `lastDay` | `DateTime.utc(今日の年 + 1, 今日の月, 今日の日)` |
| `focusedDay` | state。`onPageChanged` で更新する(**更新しないと月送りが効かない**) |
| `selectedDay` / `selectedDayPredicate` | state + `(day) => isSameDay(_selectedDay, day)` |
| `onDaySelected` | `setState` で `_selectedDay` / `_focusedDay` を更新 |
| `locale` | `'ja_JP'` |
| `calendarFormat` | `CalendarFormat.month` 固定 |
| `availableCalendarFormats` | `const {CalendarFormat.month: '月'}`(フォーマット切替ボタンを出さない) |
| `headerStyle` | `HeaderStyle(formatButtonVisible: false, titleCentered: true)` |
| `eventLoader` | `(day) => _byDay[DateTime.utc(day.year, day.month, day.day)] ?? const []` |

マーカーは `table_calendar` 既定のドット表示をそのまま使う(`calendarBuilders` は書かない)。**豆画像サムネイルはマス内で崩れやすいので使わない。**

カレンダーの**下**に、選択日の購入内訳を §6.3 と同じ `MockListRow` で表示する(ボトムシートは使わない。Flutter Web で扱いづらく、ウィジェットテストも書きにくいため)。選択日に購入が無い場合は「この日の購入はありません」。見出しは `2026/07/29 の購入`。

#### 6.4.1 table_calendar 固有の地雷(必ず守ること)

1. **`pubspec.yaml` に `table_calendar: ^3.2.0` を追加する。** `flutter pub add --dry-run` で解決を確認済み(`table_calendar 3.2.0` + 推移依存 `simple_gesture_detector 0.2.1` の2件のみ増える。他パッケージのバージョンは動かない)。
2. **`locale: 'ja_JP'` を使うには `main()` で `await initializeDateFormatting('ja_JP', null);`(`package:intl/date_symbol_data_local.dart`)を `runApp` の前に呼ぶ必要がある。** 呼ばないと実行時に `LocaleDataException` で落ちる。`main.dart` には既に `flutter_localizations` の delegates と `locale: Locale('ja')` があるが、**これは intl の日付シンボルデータを初期化しない**(別物)。`main()` は既に `async` なので `WidgetsFlutterBinding.ensureInitialized()` の直後に1行足すだけでよい。
3. **イベントのマップは日付を UTC で正規化したキーにする。** `DateTime` の等価比較は時刻まで含むため、`purchasedAt` をそのままキーにすると `eventLoader` が絶対に一致しない。`Map<DateTime, List<BeanPurchase>>` を作る際も引く際も **必ず `DateTime.utc(y, m, d)`** に正規化すること。
4. `TableCalendar` は固有の高さを持つため `MockScreenScaffold` の `ListView` の子にそのまま置ける(`shrinkWrap` 等の対応は不要)。ただし月によって週の行数が 5/6 と変わり高さが変動する点は仕様として許容する。

---

## 7. 導線(検討事項⑥の決定)

1. **010(`BeanListScreen`)の AppBar**: `actions` の `MasterSwitcherButton` の**前**に `IconButton(icon: Icon(Icons.shopping_bag_outlined), tooltip: '購入履歴(025)へ', onPressed: → BeanPurchaseHistoryScreen を push)` を追加する。
2. **マスター管理ハブ(`MastersHubScreen.entries`)**: 末尾に `(Icons.shopping_bag_outlined, '購入履歴', '購入日/豆/購入先', (_) => const BeanPurchaseHistoryScreen())` を追加する。
   - **アイコンは `Icons.shopping_bag_outlined` を使う。** ハブでは `Icons.receipt_long_outlined` が既に「メソッド管理」で使われているため重複させない。
3. ナビゲーション(`NavigationRail` / `NavigationBar`)には**タブを追加しない**(Phase 1 で確定した画面構成に手を入れないため)。
4. 027(購入店詳細)の「この店の購入履歴」セクションは **T3-69 で追加**する(T3-68 で保留済み。本タスクのスコープ外)。

---

## 8. スコープ外(やらないこと)

- 025 からの購入履歴の**編集・削除**(閲覧専用。誤登録は Sheets を直接編集して直す)
- 購入価格・通貨の管理(要望に無い。列も作らない)
- 025 の絞り込み(期間・保存場所・購入店)、月ごとの小計・見出し
- カレンダーの週/2週表示、豆画像サムネイルのマーカー
- 購入履歴からの豆の新規作成
- 027 の「この店の購入履歴」(T3-69)

---

## 9. T3-62〜T3-65 への引き渡し(実装タスクの粒度)

いずれも **Sonnet 5 が設計判断をせずに実装できる**ことを意図している。着手順は T3-62 → T3-63 → T3-64 → T3-65(この順に依存)。

### T3-62 購入履歴のデータ基盤(M)
§2 のとおり。①`lib/models/bean_purchase.dart` + 手書き `.g.dart`(9フィールド、`_parseString`/`_parseDate`/`_parseDouble` を `BeanMaster` からコピー、`copyWith` 完備) ②`gas/Code.gs` の `ALLOWED_SHEETS` に `'bean_purchases'`、`NEW_SHEET_HEADERS` に §2.1 の9列を**この順**で追加 → `clasp push` + `clasp deploy --deploymentId <既存ID>` ③`DataService` に4メソッド + `SheetsService` 実装(`_storeKeyMap` と同型)+ `FirestoreService` にスタブ + **`test/` 配下の全 `_FakeDataService` に空実装** ④`data_providers.dart` に `BeanPurchaseNotifier` / `beanPurchasesProvider`。
テスト: `fromJson`/`toJson` 往復、**数字のみの `beanId` が文字列化されること**、空 JSON での既定値。

### T3-63 011 の追加購入ボタンとダイアログ(M)
§3・§4 のとおり。§4.1 のセクション改称(`残量調整` → `在庫・購入`)を含む。**書き込み順序(履歴 → 豆マスタ)と失敗時のメッセージは §3.1 のとおりに実装すること。**
テスト: ダイアログ描画、保存で `addBeanPurchase` と `updateBean` の**両方**が呼ばれること、`stockBaselineGrams` が「現在の残量 + 購入量」になること、焙煎日未入力時に既存 `roastDate` が保持されること、焙煎日 > 購入日でバリデーションエラーになること。

### T3-63b 012 の初回購入記録 + 遡及登録スクリプト(S〜M)
§5 のとおり。**T3-63 から分離した新規タスク**(011 のダイアログと 012 の保存処理は別ファイル・別テストのため)。`tools/migrate_bean_purchases.dart` の実行前に対象一覧をユーザーへ提示し、実行後に2回目で `added=0` を確認する。
テスト: 012 の新規保存で `addBeanPurchase` が `bp_init_<豆ID>` の ID で呼ばれること、購入日未入力なら呼ばれないこと、編集モードでは呼ばれないこと。

### T3-64 025 の新設 + リスト形式(M)
§6.1〜§6.3・§7 のとおり。`SegmentedButton` はこの時点で置き、カレンダー側は「準備中」ではなく **T3-65 まで `list` のみの単一表示にしておく**(セグメントは T3-65 で2つに増やす)。
テスト: フェイクデータで行が購入日降順に描画されること、豆名・購入店名・購入量が subtitle に出ること、行タップで 011 へ遷移すること、履歴0件で空状態が出ること。

### T3-65 025 にカレンダー形式を追加(M)
§6.2・§6.4 のとおり。**`pubspec.yaml` への `table_calendar: ^3.2.0` 追加と `main.dart` の `initializeDateFormatting('ja_JP', null)` は本タスクで行う**(§6.4.1 の地雷1・2)。
テスト: 購入がある日にマーカー(イベント)が載ること、日付タップでその日の内訳が出ること、購入が無い日をタップして「この日の購入はありません」が出ること。**`DateTime.utc` 正規化のユニットテストを1件入れる**(§6.4.1 の地雷3 の回帰防止)。

### T3-69 への追記(既存タスクの更新)
既存の作業に加えて、⑦ `tools/migrate_bean_store_id.dart` で `docs/store_master_design.md` §3.2 の名寄せ規則を **`bean_purchases.購入店ID` にも適用**する、⑧ 011 の追加購入ダイアログの保存時に `BeanMaster.storeId` も更新する(§3 の表)、を追加する。
