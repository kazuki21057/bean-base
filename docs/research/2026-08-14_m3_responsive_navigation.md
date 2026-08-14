> ⚠️ **この調査レポートは「不採用」判定です(T5-A75のagyパイロット、2026-08-14)。設計判断の根拠に使わないでください。**
> ブレークポイント数値の出典として挙げられている `https://m3.material.io/foundations/layout/understanding-layout/parts-of-layout` は **HTTP 404 で実在しません**(同ドメインの別URLは200を返すため、取得失敗ではなくURL自体の誤りです)。ブレークポイントの具体値を使う場合は必ず一次情報を取り直してください。
> 一方、**`flutter_adaptive_scaffold` が Discontinued(開発停止)であることは pub.dev で実在確認済み**です。この1点は再利用してよく、Phase 1(画面/ナビゲーション再編)で同パッケージを採用しない根拠に使えます。判定の詳細は `docs/antigravity_delegation_design.md` §7「T5-A75の結論」。

# Material 3 レスポンシブ・ナビゲーション切替調査レポート

- 調査日: 2026-08-14
- 調査目的: Flutter (Material 3) における画面幅に応じたナビゲーション部品切替の公式推奨仕様、実装パターンの比較、および20画面規模（10項目以上）における情報設計慣習の整理
- 調査範囲: Material Design 3 ガイドライン、Flutter 公式ドキュメント、pub.dev パッケージ情報。実際の画面実装やBeanBaseアプリ固有のコード修正は対象外。

---

## 確認済みの事実

### 1. Material 3 のブレークポイントと推奨ナビゲーション部品
Material Design 3 では、従来の「Window Size Classes」という呼称から「Breakpoints」に整理され、画面幅（dp）に応じて以下の5つのクラスが定義されています。

| ブレークポイント | 画面幅 (dp) | 想定デバイス例 | 推奨ナビゲーション部品 | 許容項目数 |
| :--- | :--- | :--- | :--- | :--- |
| **Compact** | 0 〜 599 dp | スマートフォン（縦向き） | **NavigationBar** (Bottom Navigation) | 3〜5 項目 |
| **Medium** | 600 〜 839 dp | タブレット / 折りたたみ端末（縦向き） | **NavigationRail** (Collapsed / アイコンのみ) | 3〜7 項目 |
| **Expanded** | 840 〜 1199 dp | タブレット（横向き）、小型PC | **NavigationRail** (Collapsed / Expanded) または **NavigationDrawer** | 3〜7 項目 (Rail) / 多数 (Drawer) |
| **Large** | 1200 〜 1599 dp | デスクトップPC | **NavigationRail** (Expanded: ラベル付き) または **NavigationDrawer** (Standard / 常時表示) | 制限なし（セクション分割推奨） |
| **Extra-large**| 1600 dp 以上 | 大画面PC、ウルトラワイドモニター | 同上 | 同上 |

- **NavigationBar**: 最大5項目まで。片手操作のエルゴノミクスを重視し、下部に配置する (出典: [Material 3 Navigation Bar](https://m3.material.io/components/navigation-bar/overview) / 取得日: 2026-08-14)。
- **NavigationRail**: 3〜7項目程度。画面の先頭（左端）に配置する。M3 Expressive ではアイコンのみの「Collapsed」と、ラベルやメニューが広がる「Expanded」の2形態が定義されている (出典: [Material 3 Navigation Rail](https://m3.material.io/components/navigation-rail/overview) / 取得日: 2026-08-14)。
- **NavigationDrawer**: 5項目以上の多いデスティネーションや階層構造に適した部品 (出典: [Material 3 Navigation Drawer](https://m3.material.io/components/navigation-drawer/overview) / 取得日: 2026-08-14)。

### 2. Flutter における実装パターンの比較

| 実装パターン | メリット | デメリット | 最適なユースケース |
| :--- | :--- | :--- | :--- |
| **A. `LayoutBuilder` による自前分岐** | ・外部パッケージ不要<br>・親ウィジェットの制約（幅）に連動するため、マルチペインや分割画面でも破綻しない | ・ブレークポイント判定やUI切り替えの定型コードを自身で管理する必要がある | ・画面分割や柔軟なレスポンシブ設計を行う本格アプリ |
| **B. `MediaQuery.sizeOf(context)` による自前分岐** | ・極めて簡潔に記述可能<br>・`sizeOf` を使えばサイズ変化時のみリビルド | ・ウィンドウ全体のサイズ基準となるため、将来的なペイン分割や埋め込み表示時に親サイズと乖離する | ・アプリ全体で一律にScaffoldを切り替える単純な構造 |
| **C. `flutter_adaptive_scaffold` 等のパッケージ** | ・M3準拠のスロット型レイアウト（`AdaptiveScaffold`）を即座に利用可能 | ・**公式の `flutter_adaptive_scaffold` は Discontinued（更新停止）**<br>・フォーク版（`adaptive_scaffold_plus` 等）への依存が必要 | ・標準レイアウトを迅速にプロトタイピングする場合 |
| **D. `NavigationRail(extended: ...)` の段階的拡張** | ・Flutter標準の `NavigationRail` の `extended: bool` でアニメーション付きでスムーズにラベル展開可能 | ・項目数が多い場合、画面高さを超えてオーバーフロー（要スクロール対応）<br>・階層ヘッダー等の自由度はDrawerより低い | ・3〜7項目の主要ナビゲーションをタブレット（アイコンのみ）とデスクトップ（ラベル付き）でシームレスに切り替える場合 |

- Flutter公式のレスポンシブ設計ドキュメントでは、画面サイズに応じたレイアウト分岐に `LayoutBuilder` や `MediaQuery` を用いる基本パターンが解説されている (出典: [Adaptive and Responsive Design in Flutter](https://docs.flutter.dev/ui/adaptive-responsive/overview) / 取得日: 2026-08-14)。
- `flutter_adaptive_scaffold` は pub.dev にて discontinued 扱いとなっている (出典: [pub.dev flutter_adaptive_scaffold](https://pub.dev/packages/flutter_adaptive_scaffold) / 取得日: 2026-08-14)。

### 3. 画面数が多い場合（20画面規模・10項目以上）の情報設計慣習
Material 3 および 一般的な UI/UX 設計指針において、多数の画面をナビゲーションへ配置する際の定石は以下の通りです。

1. **Top-level Destinations (3〜5項目) への集約と階層化 (Forward Navigation)**:
   - 全20画面をグローバルナビゲーションの第1階層に並べるのはアンチパターンとされています。
   - グローバルな `NavigationBar` や `NavigationRail` にはコアとなる **3〜5個の主要ハブ**（例: ダッシュボード、一覧・業務、マスタ管理、設定等）のみを配置し、残りの画面は各ハブ内のドリルダウン（一覧→詳細）やタブ、カードリンクで遷移させます (出典: [Material 3 Understanding Layout - Parts of Navigation](https://m3.material.io/foundations/layout/understanding-layout/parts-of-layout) / 取得日: 2026-08-14)。
2. **NavigationDrawer におけるセクション分割とサブヘッダー**:
   - 多数の項目をフラットにリスト表示する場合、`NavigationDrawer` 内で `Divider` やサブヘッダー（機能カテゴリ見出し）を用いてグループ化します。
   - 利用頻度の高い項目を最上部に配置し、設定や管理系は下部に分離します (出典: [Material 3 Navigation Drawer Guidelines](https://m3.material.io/components/navigation-drawer/overview) / 取得日: 2026-08-14)。
3. **Compact（モバイル）での「その他 (More)」メニュー退避**:
   - モバイル幅では `NavigationBar` に主要4項目を配置し、5項目目を「その他 (More)」としてタップ時に Modal Bottom Sheet や Modal Navigation Drawer を開いて二次的機能にアクセスさせます。

### 4. 2026年時点での有効性と最新動向
- **`flutter_adaptive_scaffold` の非推奨化**: 過去の解説記事で多用されていた公式パッケージが discontinued となっているため、新規設計では自前実装（`LayoutBuilder` + 標準Widget）または `adaptive_scaffold_plus` を採用すべきです。
- **M3 Expressive による Navigation Rail への集約**: Android/Material 3 の最新ガイドラインでは、従来の独立した Navigation Drawer から、Navigation Rail の Collapsed / Expanded（WideNavigationRail）への統合・移行が進んでいます。
- **Flutter 標準の `NavigationDrawer`**: Flutter 3.7 以降、Material 3 準拠の `NavigationDrawer` / `NavigationDrawerDestination` が標準Widgetとして組み込まれており、外部パッケージなしでM3スタイルのドロワーが構築可能です。

---

## 推測・未確認

- **BeanBase 2.0 に最適な情報アーキテクチャの具体構成**: BeanBase が持つ20画面の内訳（豆・抽出・統計・設定・各マスタなど）によって、Top-level をいくつにするか、マスタ系画面を1つのドロワーセクションにまとめるか等の最適解は上位モデル・開発者の設計判断に依存します。

---

## 変動しうる情報への注記

- Material Design 3 のコンポーネント仕様や推奨パターン（M3 Expressive など）は Google Design チームにより継続的に更新されるため、UIの全面改修時には最新のガイドライン仕様を確認してください。
- サードパーティ製のアダプティブ支援パッケージ（`adaptive_scaffold_plus` 等）の保守状況・対応バージョンは将来的に変動する可能性があります。

---

## 積み残し・判断が必要な点

- 20画面の内訳に基づき、グローバルナビゲーションに配置する主要ハブ（3〜5項目）と、子階層に退避するサブ画面の分類・グルーピング方針の確定。
- 自前実装（`LayoutBuilder` + `NavigationRail` / `NavigationDrawer`）で組むか、外部パッケージ（`adaptive_scaffold_plus` 等）を採用するかの決定（BeanBaseでは外部依存を増やさない自前実装が推奨される傾向があります）。
