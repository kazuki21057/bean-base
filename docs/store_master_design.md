# 購入店マスタ(store_master)設計書 — T3-66 成果物

最終更新: 2026-07-28(T3-66、上位モデル(Opus 5)で実施。ユーザー承認済み)

本書は `docs/改修マスタープラン.md` §3 Phase 3 の **T3-66**(購入店マスタの設計 + 既存店の抽出 + Web情報の自動収集)の成果物である。
**T3-67(データ基盤)・T3-68(3画面)・T3-69(豆マスタの`store`→`storeId`移行)は、本書の決定内容をそのまま実装すればよい**(設計判断は本書で済んでいる。発明しないこと)。

---

## 1. ユーザー承認済みの決定事項(2026-07-28)

| 論点 | 決定 |
|---|---|
| 管理項目 | **フル13項目**(§2) |
| 既存データの名寄せ | **提案どおり名寄せ**(§3)。表記ゆれ3組を統合、非店舗値3件はマスタ化しない |
| 026/027/028の実装方式 | **既存テンプレート流用**(`MasterListTemplate`/`MasterDetailTemplate`) |
| 027(詳細)の表示内容 | **4種すべて**: この店で買った豆 / この店の購入履歴 / 統計(購入回数・総購入量・平均評価) / 関連する抽出履歴 |

---

## 2. 管理項目定義(フル13項目 → シート17列)

「13項目」は管理上の粒度。所在地は都道府県+住所の2列、業態は3フラグに展開するため、シート列としては**ID + 13項目の展開16列 + メタ2列 = 計19列**になる。
メタ2列(`情報取得元`/`情報取得日`)は§8のAI自動取得のためのもの。**T3-67の時点で最初から19列で作ること**(あとから列を足すと`NEW_SHEET_HEADERS`では反映されず`EXISTING_SHEET_EXTRA_COLUMNS`が必要になり、過去に頻発した列プロビジョニング漏れバグを踏む)。

| # | 管理項目 | シート列名(日本語) | Dartフィールド | 型 | 備考 |
|---|---|---|---|---|---|
| — | (ID) | `購入店ID` | `id` | `String` | **`fromJson`で`.toString()`キャスト必須**(既知のクラッシュ要因)。既定値`''` |
| 1 | 店名 | `店名` | `name` | `String` | 表示用の短い名前。`BeanMaster.store`の値と一致させる(T3-69の突合キー)。既定値`'-'` |
| 2 | 正式名称 | `正式名称` | `formalName` | `String` | 法人名や正式屋号。既定値`''` |
| 3 | URL | `URL` | `url` | `String` | 公式サイト。既定値`''` |
| 4 | 都道府県 | `都道府県` | `prefecture` | `String` | 一覧の絞り込みに使えるよう住所と分離。既定値`''` |
| 4 | 住所 | `住所` | `address` | `String` | 都道府県以下。郵便番号は住所の先頭に含めてよい。既定値`''` |
| 5 | 業態(オンライン) | `オンライン販売` | `hasOnlineShop` | `bool` | `_parseBool`(`BeanMaster`と同じ実装)を使う。既定値`false` |
| 5 | 業態(実店舗) | `実店舗` | `hasPhysicalStore` | `bool` | 同上 |
| 5 | 業態(焙煎所) | `焙煎所併設` | `hasRoastery` | `bool` | 同上 |
| 6 | 取扱豆の傾向 | `取扱豆の傾向` | `beanTendency` | `String` | 例「スペシャルティ中心/浅煎り多め」。既定値`''` |
| 7 | メモ | `メモ` | `memo` | `String` | 自由記述。既定値`''` |
| 8 | 画像URL | `店舗画像URL` | `imageUrl` | `String?` | Drive URL。`ImageService`の既存経路をそのまま使う |
| 9 | SNS | `SNS` | `snsUrl` | `String` | Instagram等のURL 1本。既定値`''` |
| 10 | 営業時間 | `営業時間` | `businessHours` | `String` | 自由文字列(「月-金10:00-17:00」等の複雑な表記があるため構造化しない)。既定値`''` |
| 11 | 定休日 | `定休日` | `closedDays` | `String` | 同上、自由文字列。既定値`''` |
| 12 | 電話番号 | `電話番号` | `phone` | `String` | 既定値`''` |
| 13 | 開業年 | `開業年` | `openedYear` | `String` | 「2015」等。**不明が多いため`int`ではなく`String`**(空欄を素直に表現できる)。既定値`''` |
| — | (メタ) | `情報取得元` | `sourceUrl` | `String` | §8のAI自動取得で埋めた場合の出典URL(複数あれば改行区切り)。手入力の店は空。既定値`''` |
| — | (メタ) | `情報取得日` | `infoFetchedAt` | `DateTime?` | §8のAI自動取得を実行した日時。`BeanMaster._parseDate`を流用 |

**bool のシート表現**: `TRUE`/`FALSE`(空欄は`false`扱い)。`BeanMaster._parseBool`が`'true'/'yes'/'1'`を受けるため、**同じ`_parseBool`を`StoreMaster`にもコピーし、大文字`TRUE`も通るよう`toLowerCase()`済みの比較になっている点を確認して流用する**。

**必須入力は`店名`のみ**。他はすべて任意(Web収集で埋まらない項目が多いため)。

---

## 3. 既存データの抽出結果と名寄せ

本番`bean_master`(全30件)の`購入店舗`列を全件取得して集計した結果(2026-07-28時点)。

### 3.1 生の値(11種)

| 件数 | 生の値 | 判定 |
|---|---|---|
| 7 | `Navy` | 実店舗 |
| 4 | `神戸珈琲物語` | 実店舗 |
| 4 | `HEISEI COFFEE The Factory` | 実店舗 |
| 2 | `SORA` | 実店舗(同定未確定) |
| 2 | `岬の焙煎所` | 実店舗 |
| 1 | `明暮焙煎研` | 実店舗。**正しくは「明暮焙煎所」**と判断(誤記) |
| 1 | `そら` | `SORA`の表記ゆれ |
| 1 | `ドリップバッグ` | **店名ではない**(商品形態。豆名「ちょっと贅沢な珈琲店」) |
| 1 | `コロンビア` | **店名ではない**(産地の誤入力) |
| 1 | `グアテマラ` | **店名ではない**(産地の誤入力) |
| 6 | (空欄) | 内訳: テスト豆2件(T3-46で削除予定) / Youth系3件 / 「岬焙煎所 中煎り パプアニューギニア…」1件 |

### 3.2 名寄せ規則(承認済み)

1. `SORA` + `そら` → **1店(`SORA`)に統合**
2. `岬の焙煎所` + 豆名が「岬焙煎所…」で購入店舗が空欄の1件 → **`岬の焙煎所`に統合**
3. `明暮焙煎研` → **`明暮焙煎所`に表記修正**(店名列も修正する)
4. 豆名が`Youth …`で購入店舗が空欄の3件 → **`Youth Coffee`を設定**
5. `ドリップバッグ` / `コロンビア` / `グアテマラ` の3件 → **購入店マスタを作らない**。該当豆の`storeId`は空欄のままにし、ユーザーが後から手動で紐付ける(`store`の自由入力文字列はそのまま残す=後方互換)

**結果: 購入店マスタは7店**。

---

## 4. 初期データ案(出典付き、T3-67で投入する)

**空欄の項目は「確証が得られなかった」ことを意味する。推測で埋めないこと。** ユーザーが027の編集画面から後で補完する前提。

`購入店ID`は**冪等な移行スクリプトのために固定スラッグ**を使う(タイムスタンプ生成にしない。再実行時に重複登録されるため)。

### store_navy

| 項目 | 値 |
|---|---|
| 購入店ID | `store_navy` |
| 店名 | `Navy` |
| 正式名称 | `Navy Coffee Roaster` |
| URL | `https://www.navycoffeeroaster.com/` |
| 都道府県 | `兵庫県` |
| 住所 | `〒673-0873 明石市大蔵中町4-8` |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / `TRUE` |
| 取扱豆の傾向 | `スペシャルティコーヒー(甘み・果実感を重視)` |
| SNS | `https://www.instagram.com/navy_coffee_roaster/` |
| 営業時間 | `8:00-18:00` |
| 定休日 | `火曜` |
| 電話番号 | `078-965-6998` |
| 開業年 | (空欄) |
| メモ | `※同名店が複数あるため同定要確認(三重県鈴鹿市のNavy Coffee Houseとは別)。地域的に明石の当店と判断した。` |

出典: <https://www.navycoffeeroaster.com/about-us> / <https://akashi-journal.com/gourmet/navy-coffee-roaster-2-2/>

### store_kobe_coffee

| 項目 | 値 |
|---|---|
| 購入店ID | `store_kobe_coffee` |
| 店名 | `神戸珈琲物語` |
| 正式名称 | `株式会社神戸珈琲` |
| URL | `https://kobecoffee.jp/` |
| 都道府県 | `兵庫県` |
| 住所 | `〒653-0827 神戸市長田区上池田6-8-23(上池田本店)` |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / `TRUE` |
| 取扱豆の傾向 | `珈琲鑑定士が厳選した豆の量り売り。紀州備長炭による炭火焙煎が看板商品` |
| SNS | (空欄) |
| 営業時間 | `平日9:00-17:30 土日祝8:00-17:30(上池田本店)` |
| 定休日 | (空欄) |
| 電話番号 | `078-621-3360`(上池田本店) |
| 開業年 | (空欄) |
| メモ | `直営10店舗(喫茶6/豆挽き売り4)。住所・電話・営業時間は本店のもの。どの店舗で購入したかはユーザーが後で補足すること。` |

出典: <https://www.kobecoffee.co.jp/access.html> / <https://kobecoffee.jp/> / <https://www.rakuten.co.jp/kobecoffee/>

### store_heisei

| 項目 | 値 |
|---|---|
| 購入店ID | `store_heisei` |
| 店名 | `HEISEI COFFEE The Factory` |
| 正式名称 | `株式会社平成珈琲` |
| URL | `https://www.heisei-coffee.co.jp/` |
| 都道府県 | `兵庫県` |
| 住所 | `神戸市垂水区本多聞3丁目6-12` |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / `TRUE` |
| 取扱豆の傾向 | `ブレンド + スペシャルティのシングルオリジン。ドイツProbat製UG22・P3の2台で焙煎` |
| SNS | `https://www.instagram.com/heiseicoffee/` |
| 営業時間 | (空欄) |
| 定休日 | (空欄) |
| 電話番号 | `078-224-1479`(本社) |
| 開業年 | `2019` |
| メモ | `The Factory(垂水区本多聞)は2026年オープンの焙煎工房併設店。公式サイトに記載の営業時間8:00-18:00・定休日(日祝/第三第五土曜)は本社/工房のもので、The Factory店舗としての営業時間かは未確認のため空欄にした。開業年2019は平成珈琲としての創業年。` |

出典: <https://www.heisei-coffee.co.jp/> / <https://kansai-kaiten.com/heiseicoffeethefactory-hontamon2606/> / <https://kobe-journal.com/archives/8836946975.html>

### store_sora

| 項目 | 値 |
|---|---|
| 購入店ID | `store_sora` |
| 店名 | `SORA` |
| その他すべて | (空欄) |
| メモ | `※未同定。「そら」表記の1件を統合済み。候補: ①古民家カフェSORA / Sora cafe(神戸市北区有馬) ②珈琲焙煎室そら(神奈川県伊勢原) ③焙煎幸房"そら"(岐阜県大垣)。地域的には①が有力だが確証がないため全項目を空欄にした。ユーザーによる同定が必要。` |

出典(候補のみ): <https://cafesora.jimdofree.com/> / <https://kobecco.hpg.co.jp/64940/>

### store_misaki

| 項目 | 値 |
|---|---|
| 購入店ID | `store_misaki` |
| 店名 | `岬の焙煎所` |
| 正式名称 | `岬の焙煎所` |
| URL | `https://live-coffee.ocnk.net/` |
| 都道府県 | `兵庫県` |
| 住所 | `神戸市兵庫区和田岬` |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / `TRUE` |
| 取扱豆の傾向 | `浅煎り〜深煎りの自家焙煎8種前後。看板は「和田岬ブレンド」。中南米・アフリカのスペシャルティ` |
| SNS | `https://www.instagram.com/misaki_no_mame/` |
| 営業時間 | `月-金10:00-17:00、第4土曜9:00-16:00` |
| 定休日 | `土日祝(第4土曜を除く)` |
| 電話番号 | (空欄) |
| 開業年 | `2015` |
| メモ | `番地は公式サイトに記載なし。関連店「misaki cafe musubi」は兵庫区今出在家町2-2-17 HD神戸ビル1階。` |

出典: <https://live-coffee.ocnk.net/> / <https://kisspress.jp/articles/55051/>

### store_akekure

| 項目 | 値 |
|---|---|
| 購入店ID | `store_akekure` |
| 店名 | `明暮焙煎所` |
| 正式名称 | `明暮焙煎所` |
| URL | `https://akekure-beans.com/` |
| 都道府県 | `兵庫県` |
| 住所 | `〒654-0033 神戸市須磨区東町1-2-9` |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / `TRUE` |
| 取扱豆の傾向 | `スペシャルティグレードの生豆のみ使用。ブレンド5種+シングルオリジン7種の計12種` |
| SNS | (空欄) |
| 営業時間 | `10:00-19:00` |
| 定休日 | `火曜・水曜` |
| 電話番号 | `078-739-1050` |
| 開業年 | `2017` |
| メモ | `本番データの表記「明暮焙煎研」は誤記と判断し「明暮焙煎所」に修正した(T3-69の突合時、旧表記も一致するようフォールバックすること)。` |

出典: <https://akekure-beans.com/about> / <https://kisspress.jp/articles/35724/> / <https://jp.kurasu.kyoto/blogs/kurasu-journal/akekure-beans-kobe-hyogo-2020-february-kurasupartnerroaster>

### store_youth

| 項目 | 値 |
|---|---|
| 購入店ID | `store_youth` |
| 店名 | `Youth Coffee` |
| 正式名称 | (空欄) |
| URL | `https://youthcoffee.stores.jp/` |
| 都道府県 | `兵庫県` |
| 住所 | (空欄) |
| オンライン販売/実店舗/焙煎所併設 | `TRUE` / `TRUE` / (空欄=`FALSE`) |
| 取扱豆の傾向 | (空欄) |
| SNS | (空欄) |
| 営業時間 | (空欄) |
| 定休日 | (空欄) |
| 電話番号 | (空欄) |
| 開業年 | (空欄) |
| メモ | `本番データでは購入店舗列が空欄で、豆名「Youth コロンビア/エチオピア/ケニア」3件から推定した店。神戸・三宮の立ち飲みスタイルのコーヒー店とみられるが、公式ストアがHTTP 403で取得できず二次情報のみ(営業8:00-18:00/火曜定休との記述あり)のため詳細は空欄にした。焙煎所併設かどうかも未確認。` |

出典: <https://youthcoffee.stores.jp/> (403) / <https://afroaster.com/koube-coffee>

---

## 5. 画面構成(026 / 027 / 028)

### 5.1 共通

- `lib/routing/app_screen.dart` に追加(**025〜028は現状すべて未使用であることを確認済み**):
  ```dart
  storeList('026', '購入店管理'),
  storeDetail('027', '購入店詳細'),
  storeNew('028', '新規購入店'),
  ```
  ※`025`は購入履歴(T3-64)用に予約済みのため使わないこと。
- `lib/routing/screen_registry.dart` に3件のcaseを追加。
- **CLAUDE.md「全マスタータブへの一律適用」規約**により、`MasterSwitcherButton._entries`(`lib/screens/master_template.dart:32`)と `MastersHubScreen`の`entries`(`lib/screens/masters_hub_screen.dart:21`)の**両方**に購入店を追加する。アイコンは `Icons.storefront_outlined`。
- `MasterSwitcherButton._categoryOf` に `storeList`/`storeDetail` → `storeList` のケースを追加する(自分自身の種別をメニューから除外するため)。

### 5.2 026 購入店一覧

`MasterListTemplate<StoreMaster>` をそのまま使う。

| 引数 | 値 |
|---|---|
| `screen` | `AppScreen.storeList` |
| `icon` | `Icons.storefront_outlined` |
| `itemsAsync` | `ref.watch(storeMasterProvider)` |
| `nameOf` | `(s) => s.name` |
| `subtitleOf` | `(s) => [s.prefecture, 業態ラベル].where((e) => e.isNotEmpty).join(' · ')`。業態ラベルは`焙煎所併設`→`'自家焙煎'`、`hasOnlineShop && !hasPhysicalStore`→`'オンラインのみ'` |
| `imageUrlOf` | `(s) => s.imageUrl` |
| `onTapItem` | 027へ`Navigator.push` |
| `createScreenBuilder` | `() => const StoreCreateScreen()` (028) |

絞り込みは**実装しない**(7件しかないためスコープを膨らませない)。

### 5.3 027 購入店詳細

`MasterDetailTemplate` を使う。`extraSections`は**この順**で3つ渡す(テンプレートは`extraSections`を基本情報の直後・「関連する抽出履歴」の直前に描画する)。

1. **基本情報**(`fields`): §2の13項目を上から順に`(ラベル, 値)`で渡す。**空欄の項目は`'-'`**にする(`MockInfoRow`がそのまま表示する)。URL/SNSは文字列表示でよい(リンク化はスコープ外)。
2. **`extraSections[0]` 「この店で買った豆」**: `FormSection(icon: Icons.coffee, title: 'この店で買った豆')`。`beanMasterProvider`から`b.storeId == store.id`で抽出。**T3-69完了までは`storeId`が空のため、`b.storeId.isEmpty && b.store == store.name`のフォールバック一致も併用する**(明暮焙煎所は旧表記`明暮焙煎研`にも一致させる)。行は`MockListRow(imageUrl: b.imageUrl, title: b.name, subtitle: 購入日)`、タップで011へ。
3. **`extraSections[1]` 「この店の購入履歴」**: `FormSection(icon: Icons.receipt_long_outlined, title: 'この店の購入履歴')`。`bean_purchases`(T3-62)から`storeId`一致分を購入日の新しい順に表示。**T3-62が未完了の間はセクションごと非表示にする**(`if (purchasesProviderが存在すれば)`ではなく、T3-68実装時点でT3-62が入っていなければこのセクションを作らない。T3-69で有効化する)。
4. **`extraSections[2]` 「統計」**: `FormSection(icon: Icons.insights_outlined, title: '統計')` に`MockInfoRow`3行。
   - `購入回数`: `bean_purchases`の該当件数。T3-62未完了時は**この店の豆の件数**で代用する。
   - `総購入量`: 該当豆の`initialQuantityGrams`合計(g)。T3-62完了後は購入履歴の購入量合計に切り替える。
   - `平均評価`: この店の豆を使った`CoffeeRecord.scoreOverall`の平均(小数第1位まで)。記録0件なら`'-'`。
5. **`relatedLogFilter`**(テンプレート標準の「関連する抽出履歴」5件): `(log) => この店の豆IDの集合.contains(log.beanId)`。**店→豆→記録の二段フィルタ**になるため、`build`内で先に豆IDのSetを作ってからクロージャに渡すこと(毎行で線形探索しない)。

`onEdit`は028を編集モードで開く(既存の`bean_create_screen.dart`等と同じ「新規画面に既存インスタンスを渡す」流儀に合わせる)。`onDelete`は`deleteStore`。

### 5.4 028 新規購入店 / 編集

`lib/screens/create/store_create_screen.dart` を新設。`dripper_create_screen.dart`と同じ構成(`FormSection` + `TextFormField` + 保存ボタン)を踏襲する。

- 入力: §2の13項目。**必須は`店名`のみ**。
- 業態3つは`SwitchListTile`または`CheckboxListTile`(既存の`isInStock`の流儀に合わせる)。
- 画像は既存の共通部品 `lib/widgets/image_upload_field.dart` をそのまま使う。
- 保存はT3-45の`OptimisticListNotifier`の`addOptimistic`/`updateOptimistic`経由。
- **エラーSnackBarは`SnackBarBehavior.floating` + 下マージン**(保存ボタンと重なる、T3-44の教訓)。

---

## 6. T3-67 / T3-68 / T3-69 への引き渡し

- **T3-67**: §2の列定義で`lib/models/store_master.dart`(+`.g.dart`手書き可)を作り、`gas/Code.gs`の`ALLOWED_SHEETS`に`'store_master'`、`NEW_SHEET_HEADERS`に§2の19列を追加 → `clasp push` + `clasp redeploy`。`DataService`/`SheetsService`にCRUD(keyMap/reverseMap**両方**)、`data_providers.dart`にプロバイダ。最後に §4 の7店を投入する冪等な移行スクリプトを`tools/`に作成して実行(**302リダイレクト手動フォロー必須**、既存`購入店ID`はスキップ)。
- **T3-68**: §5をそのまま実装。
- **T3-69**: `BeanMaster`に`storeId`を追加(`OriginMaster`/`originId`と完全に同じパターン)。既存豆の突合は**§3.2の名寄せ規則どおり**(旧表記`明暮焙煎研`→`store_akekure`、`そら`→`store_sora`、豆名`岬焙煎所…`→`store_misaki`、豆名`Youth …`→`store_youth`)。`ドリップバッグ`/`コロンビア`/`グアテマラ`の3件は**空のまま残す**。

---

## 8. 新規購入店の情報を自動取得する仕組み(T3-70の設計、2026-07-28ユーザー要望)

**要望**: 「今後新しい店で購入した場合、自動で情報を取得する仕組み」。§4の初期データ7店は上位モデルの手作業で埋めたが、**8店目以降はアプリ内で完結させる**。

### 8.1 方式の決定

**Gemini API(既存の`AiAnalysisService`と同じ`google_generative_ai`パッケージ)に店名を渡し、§2の項目をJSONで返させる。** 新しい外部サービス・新しいパッケージ・自前スクレイピングは**採用しない**。理由:

- Flutter Web から任意サイトを直接fetchすると**CORSで確実に失敗する**(店の公式サイトは`Access-Control-Allow-Origin`を返さない)。プロキシを立てるのはこのアプリの構成に対して過剰。
- Gemini API は既にアプリから呼べている(APIキーは`shared_preferences`の`gemini_api_key`、モデル選択は`_modelOrder`のフォールバック順)。**追加インフラがゼロ**。
- T3-35(パッケージ画像から豆情報をAI自動入力)で**「AIが埋めた候補をユーザーが確認して採用する」UXが既に確立している**。同じ流儀に揃えるのが一貫性の面でも実装コストの面でも最良。

**Google検索グラウンディング(`Tool`)は「使えれば使う」**扱いにする。`google_generative_ai`パッケージの現行バージョンが検索グラウンディングに対応しているかは実装時に確認し、**対応していなければ非グラウンディングのまま完成とする**(パッケージの追加・更新は独断で行わず、必要ならユーザーに確認)。グラウンディング無しでもGeminiは有名店の基本情報を知っているため、§8.3の「確信度と出典を必ず併記させる」制約があれば実用に足る。

### 8.2 発動タイミング(2箇所)

1. **028(新規購入店)の店名欄の横に「AIで自動入力」ボタン**を置く。押すと店名(+任意で都道府県)を使って取得し、§8.4の確認ダイアログを出す。配置とアイコンは012の「パッケージ画像から自動入力(AI)」ボタンに合わせる。
2. **T3-69完了後**: 012/011の購入店選択で「新規購入店を追加」した直後、店名が確定した時点で**同じ取得処理を自動起動**する(これが要望の本体=「新しい店で購入したら自動で情報が取れる」)。ユーザーが待たされないよう、取得中はダイアログ内にスピナーを出し、**失敗しても購入店の登録自体は続行できる**こと。

### 8.3 プロンプトの制約(絶対規則)

`AiAnalysisService`に`Future<StoreInfoCandidate> fetchStoreInfo({required String storeName, String? hintPrefecture, required String apiKey, String? preferredModel})`を追加する。`GenerationConfig(responseMimeType: 'application/json')` + JSONスキーマ指定で、既存の`extractBeanInfoFromImage`と同じ形にする。

プロンプトに**必ず**含める制約:

- 返すのは §2 の項目のみ(`formalName`/`url`/`prefecture`/`address`/`hasOnlineShop`/`hasPhysicalStore`/`hasRoastery`/`beanTendency`/`snsUrl`/`businessHours`/`closedDays`/`phone`/`openedYear`)+ `sourceUrls`(配列)+ 項目ごとの`confidence`(`high`/`medium`/`low`)。
- **確信が持てない項目は必ず空文字/nullで返すこと。推測で埋めてはならない。**
- **同名の別店舗が複数存在する場合は、勝手に1つを選ばず`ambiguous: true`と候補一覧を返すこと**(§4でNavy・SORAが実際にこれに該当した)。
- 出力は日本語。住所は郵便番号を含めてよい。

`confidence`が`low`の項目は§8.4で**既定チェックOFF**にする。

### 8.4 確認ダイアログ(自動保存はしない)

取得結果は**必ずユーザーの確認を通してから保存する**。無条件保存は禁止(誤情報が本番Sheetsに入るため)。

- 項目ごとに1行: `[✓] 項目名  取得値`。`confidence: high/medium`は既定ON、`low`と**既に値が入っている項目**は既定OFF(上書き事故の防止)。
- 末尾に**出典URLを一覧表示**する。
- `ambiguous: true`のときは先に候補選択のステップを挟み、選ばれなければ何も反映せず閉じる。
- 「反映」を押すとチェック済み項目だけを`StoreMaster`に入れ、あわせて`sourceUrl`(改行区切り)と`infoFetchedAt`(現在時刻)を設定する。
- APIキー未設定・取得失敗・JSONパース失敗はいずれも日本語のSnackBar(`SnackBarBehavior.floating`+下マージン)で通知し、**手入力に落とせること**。ログは`[Antigravity] Action: 購入店情報のAI取得 …`。

### 8.5 スコープ外(やらないこと)

- 既存7店の情報の自動再取得・定期更新(手動で027から実行できれば十分)。
- 店舗画像の自動取得(著作権・CORSの両面でリスクがあるため、画像は従来どおりユーザーがアップロードする)。
- 豆マスタ以外への展開(産地マスタ等への同種機能は今回の要望に含まれない)。

---

## 9. 未解決(ユーザー確認待ち)

1. **`SORA`の同定**(§4 store_sora)。候補3件のどれか、あるいは別の店か。
2. **`Navy`の同定**。明石の`Navy Coffee Roaster`で合っているか。
3. **`神戸珈琲物語`のどの店舗で購入したか**(直営10店舗)。住所・電話は暫定で上池田本店を入れてある。
4. **`Youth Coffee`の詳細**(住所・営業時間・焙煎所併設の有無)。公式ストアが403で取得できず二次情報のみ。
5. **`ドリップバッグ`/`コロンビア`/`グアテマラ`と入力された豆3件の実際の購入店**。マスタ化せず空欄にしてあるため、027の一覧からは辿れない。
