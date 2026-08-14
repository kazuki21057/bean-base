# Material Design 3 レスポンシブ・レイアウトのブレークポイントとFlutterでの推奨実装 調査レポート

- 調査日: 2026-08-14
- 調査目的: Material 3が定義するレスポンシブ・レイアウトのブレークポイント区分と幅(dp)の境界値、およびFlutterでの推奨実装方法を調査する。
- 調査範囲: Flutter公式が提供するドキュメントおよびパッケージ(`flutter_adaptive_scaffold`)に基づくブレークポイントの境界値と実装状況。

## 確認済みの事実

- [C1] Flutter公式が提供するパッケージ `flutter_adaptive_scaffold` は、Material Design 3の基本的なビジュアルレイアウト構造を実装したものである。
- [C2] しかし、このパッケージは現在開発が終了(Discontinued)しており、コミュニティでの代替パッケージの議論が案内されている状況である。
- [C3] パッケージ内で定義されている小画面(Small)向けのブレークポイントは、幅 0 〜 600 dp (未満) である。
- [C4] 中画面(Medium)向けのブレークポイントは、幅 600 〜 840 dp (未満) である。
- [C5] 中大画面(MediumLarge)向けのブレークポイントは、幅 840 〜 1200 dp (未満) である。
- [C6] 大画面(Large)向けのブレークポイントは、幅 1200 〜 1600 dp (未満) である。
- [C7] 特大画面(ExtraLarge)向けのブレークポイントは、幅 1600 dp 以上 である。

## 推測・未確認

- Material 3公式の一般的なデザインガイドライン上での呼称は「Compact / Medium / Expanded / Large / Extra-large」とされるが、Flutterの公式実装(`flutter_adaptive_scaffold`)では対応する変数名として「Small / Medium / MediumLarge / Large / ExtraLarge」が用いられている。今回はM3公式のガイドラインページ本文の直接取得ができなかったため、Flutter実装の数値を基準として報告している。
- `flutter_adaptive_scaffold` がDiscontinuedとなったため、今後のFlutterにおける公式推奨アプローチは標準ウィジェット(LayoutBuilder等)を用いた自前実装、または新たなコミュニティパッケージへ移行していくと推測される。

## 変動しうる情報への注記

- Flutter公式の推奨アプローチは現在過渡期にあり、今後の公式ドキュメント更新や新しい標準パッケージの登場によって推奨される実装方法が変わる可能性があるため、実装直前に最新のFlutter公式情報を再確認することが望ましい。

## 積み残し・判断が必要な点

- 既存のBeanBase 2.0での「640pxでのNavigationRail切り替え」を「600dp(Material 3標準のMedium開始位置)」に変更するかどうかは、UI要件に合わせて上位モデル・implementerでの判断が必要となる。
- Discontinuedとなった `flutter_adaptive_scaffold` パッケージを導入するか、LayoutBuilderを用いて自前でブレークポイント処理を実装するかのアーキテクチャ判断が必要。

## 出典一覧

| # | 主張ID | URL | HTTPステータス | 取得日 | 裏付け引用(原文ママ) |
|---|---|---|---|---|---|
| 1 | C1 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | implements the basic visual layout structure for Material |
| 2 | C2 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | &lt;strong&gt;This project has been discontinued&lt;/strong&gt; |
| 3 | C3 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | /// Returns a [Breakpoint] with the given constraints for a small screen. |
| 4 | C4 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | /// Returns a [Breakpoint] with the given constraints for a medium screen. |
| 5 | C5 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | /// Returns a [Breakpoint] with the given constraints for a mediumLarge screen. |
| 6 | C6 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | /// Returns a [Breakpoint] with the given constraints for a large screen. |
| 7 | C7 | https://pub.dev/packages/flutter_adaptive_scaffold | 200 | 2026-08-14 | /// Returns a [Breakpoint] with the given constraints for an extraLarge screen. |
