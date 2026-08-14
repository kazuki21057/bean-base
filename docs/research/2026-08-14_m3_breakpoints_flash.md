# Material 3 レスポンシブ・ブレークポイントおよび Flutter ナビゲーション切り替え調査レポート

- 調査日: 2026-08-14
- 調査目的: Material Design 3 (M3) が定義するレスポンシブ・レイアウトのブレークポイント区分・境界値(幅dp)、および Flutter で Material 3 のブレークポイント・ナビゲーションを扱う際の公式推奨手法の調査（BeanBase 2.0 Phase 1 における NavigationRail / NavigationBar の切り替え幅 640px の妥当性確認）
- 調査範囲: Material Design 3 公式ガイドライン、Android Developers 公式ドキュメント（Window Size Classes）、Flutter 公式ドキュメント、Google Developers Codelabs、Flutter 公式パッケージ（flutter_adaptive_scaffold）

---

## 確認済みの事実

### 1. Material Design 3 におけるブレークポイント (Window Size Classes) の区分と幅の境界値
- [C1] Material Design 3 の Window size classes は、compact, medium, expanded などの幅・高さ区分によりレスポンシブおよびアダプティブなレイアウトを設計・開発・テストするためのブレークポイントである (出典: Android Developers)。
- [C2] Material 3 の標準的な幅 (Width) ブレークポイント区分および境界値は以下の5段階で定義されている (出典: flutter_adaptive_scaffold, Android Developers)。
  - **Compact (コンパクト / small)**: 幅 < 600dp (0 〜 599dp) — 主にスマートフォンの縦向き画面
  - **Medium (ミディアム)**: 幅 600dp 〜 839dp (600 ≤ width < 840) — タブレットの縦向き、折りたたみ端末
  - **Expanded / MediumLarge (エクスパンデッド / ミディアムラージ)**: 幅 840dp 〜 1199dp (840 ≤ width < 1200) — タブレットの横向き、小型デスクトップ
  - **Large (ラージ)**: 幅 1200dp 〜 1599dp (1200 ≤ width < 1600) — デスクトップ
  - **Extra-large (エクストララージ)**: 幅 ≥ 1600dp (1600dp 〜) — 大画面デスクトップ、ウルトラワイドモニター

### 2. NavigationBar と NavigationRail の切り替え境界値
- [C6] Material Design 3 ガイドラインにおいて、Navigation rail は中規模端末（mid-sized devices）での UI 切り替え用途として定義されている (出典: Material Design 3 ガイドライン)。
- [C7] 一方、Navigation bar は小型端末（smaller devices）や携帯端末（handheld screens）での UI 切り替え用途として定義されている (出典: Material Design 3 ガイドライン)。
- [C3] Flutter の公式実装仕様（`flutter_adaptive_scaffold`）では、画面幅 0 〜 600dp は NavigationBar (ボトムナビゲーション) の適用領域とされ、600dp 以上で NavigationRail (レールナビゲーション) へ切り替えることが標準設定となっている (出典: flutter_adaptive_scaffold)。

### 3. Flutter 公式における推奨実装方法
- [C8] Flutter 公式のアダプティブ・レスポンシブデザインガイドでは、端末モデルの個別判別ではなく、画面サイズや向きの変化（利用可能な幅）に応じて UI を適応させることが推奨されている (出典: docs.flutter.dev)。
- [C4] Flutter の `NavigationRail` 公式 API ドキュメントでは、NavigationRail はデスクトップ Web やタブレット横画面などの広いビューポート向けであり、モバイル縦画面のような狭いレイアウトでは BottomNavigationBar (または NavigationBar) を使用すべきと明記されている (出典: api.flutter.dev)。
- [C5] Google 公式 Codelab「Build an animated responsive app layout with Material 3」の実装例では、`MediaQuery.of(context).size.width` を用いて画面幅を取得し、閾値 `width > 600` を境界として NavigationBar と NavigationRail のアニメーション遷移を切り替えている (出典: Google Codelabs)。

---

## 推測・未確認

- **BeanBase 現行実装 (640px) と M3 標準 (600dp) の差異**: 現行の 640px は tailwind などの一般的な `sm` ブレークポイントに由来すると推測されるが、純粋な Material Design 3 の標準仕様に合わせる場合は **600dp** を閾値とするのが公式準拠となる。

---

## 変動しうる情報への注記

- `flutter_adaptive_scaffold` パッケージは現在 pub.dev 上で discontinued 状態となっており、公式は代替パッケージや自前実装（`LayoutBuilder` / `MediaQuery`）への移行を推奨している（Material 3 のブレークポイント仕様そのものは 600dp / 840dp / 1200dp / 1600dp で一貫している）。

---

## 積み残し・判断が必要な点

- BeanBase 2.0 の Phase 1 で NavigationRail と NavigationBar の切り替え幅を現行の 640px のまま維持するか、Material 3 標準の 600px (600dp) に統一するか、上位設計での決定が必要。

---

## 出典一覧

| # | 主張ID | URL | HTTPステータス | 取得日 | 裏付け引用(原文ママ) |
|---|---|---|---|---|---|
| 1 | C1 | https://developer.android.com/develop/ui/compose/layouts/adaptive/window-size-classes | 200 | 2026-08-14 | Window size classes are opinionated viewport breakpoints that help design, develop, and test responsive and adaptive layouts |
| 2 | C2 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | const Breakpoint.small({this.andUp = false, this.platform})<br>    : beginWidth = 0,<br>      endWidth = 600, |
| 3 | C3 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | Primary navigation config has nothing from 0 to 600 dp screen width, |
| 4 | C4 | https://api.flutter.dev/flutter/material/NavigationRail-class.html | 200 | 2026-08-14 | The navigation rail is meant for layouts with wide viewports, such as a<br>desktop web or tablet landscape layout. |
| 5 | C5 | https://codelabs.developers.google.com/codelabs/flutter-animated-responsive-layout | 200 | 2026-08-14 | _controller.value = width > 600 ? 1 : 0; |
| 6 | C6 | https://m3.material.io/components/navigation-rail/guidelines | 200 | 2026-08-14 | Navigation rails let people switch between UI views on mid-sized devices. |
| 7 | C7 | https://m3.material.io/components/navigation-bar/guidelines | 200 | 2026-08-14 | Navigation bars let people switch between UI views on smaller devices. |
| 8 | C8 | https://docs.flutter.dev/ui/adaptive-responsive.md | 200 | 2026-08-14 | It's important to create an app, whether for mobile or web, that responds to size and orientation changes |
