# Dart/Flutter クライアントサイド数値計算パッケージ比較調査レポート

- 調査日: 2026-08-14
- 調査目的: Flutter Web を含むクライアントサイド(Dart)で、主成分分析(PCA)・線形回帰・行列演算等の統計・数値計算を行うための主要パッケージ選定およびパフォーマンス・Web動作に関する技術的評価。
- 調査範囲: 
  - 主要パッケージの機能範囲、メンテナンス状況、Web(dart2js/WASM)対応、SIMD対応の比較調査。
  - 数百〜数千行 × 十数列程度のデータ行列を扱う場合のパフォーマンス上の注意点(UIブロック、Isolate/Web Worker、メモリ)。
  - Flutter Web特有の挙動・性能・数値精度の落とし穴。

---

## 1. 主要パッケージ比較

| パッケージ名 | 主な機能範囲 (PCA/固有値分解/回帰) | 最新Ver / 最終更新 | Web動作 (dart2js / WASM) | SIMD対応 | 特徴・評価 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`ml_linalg`** | 汎用行列・ベクトル演算、LU/コレスキー分解、固有値分解(Power Iteration法)、連立方程式 | 13.12.8 (2026-07) | 対応 (Webタグあり) | あり (`Float32x4`, `Float64x2`) | 数学演算の基礎が豊富。高レベルなPCA/回帰APIは直接持たず、プリミティブとして活用。 |
| **`ml_algo`** | 線形回帰(Lasso/SGD/Newton), ロジスティック回帰, 決定木, KNN, KDTree (PCA直接提供なし) | 16.18.1 (2026-07) | 一部対応 (WASM推奨、Webタグ未明記) | `ml_linalg`依存 | 機械学習モデル訓練・評価特化。データフレーム(`ml_dataframe`)との親和性が高い。 |
| **`data`** | 行列・ベクトル演算, 固有値分解(QR法), 特異値分解(SVD), 多項式回帰, 非線形回帰(LM法), 統計分布 | 0.15.2 (2025-12) | 完全対応 (Pure Dart) | なし (TypedDataベース) | JAMA/Math.Net Numerics移植によるSVDやQR固有値分解が実装済み。PCAの自作が最も容易。 |
| **`scidart`** | 配列演算, FFT, 信号処理, 基礎線形代数 | 0.0.2-dev.12 (2022-08) | 未検証 (dev版) | なし | SciPyのDart移植を目指したが、2022年以降更新が停止しており採用リスクが高い。 |
| **`vector_math`** | 2D/3D/4D幾何演算, クォータニオン, 衝突判定 | 2.4.2 (2026-07) | 完全対応 (Flutter公式) | あり (`Float32x4`等) | 3Dグラフィックス/UIアニメーション特化。可変長・高次元の統計行列演算には不適。 |
| **`linalg`** | 基本行列演算, 逆行列, 行列式 | 0.4.0 (2021-07) | 完全対応 (Pure Dart) | なし | 機能が基礎演算のみで、更新も2021年で停止している。 |

---

## 2. 確認済みの事実

### パッケージの機能とメンテナンス状況
- **`ml_linalg` (v13.12.8)**: SIMD型（`Float32x4`, `Float64x2`）をベースにした線形代数パッケージであり、LU分解・コレスキー分解・連立方程式求解・Power Iteration法による固有値/固有ベクトル計算が実装されている。2026年7月時点でアクティブに更新されている。(出典: [pub.dev/packages/ml_linalg](https://pub.dev/packages/ml_linalg)、取得日: 2026-08-14)
- **`ml_algo` (v16.18.1)**: 線形回帰（LinearRegressor: Lasso, SGD, BGD, Newton-Raphson）やロジスティック回帰、決定木等を備えるが、PCA専用のクラスは提供されていない。(出典: [pub.dev/packages/ml_algo](https://pub.dev/packages/ml_algo)、取得日: 2026-08-14)
- **`data` (v0.15.2)**: JAMAおよびMath.Net Numericsを移植した特異値分解（SVD）やQR法による固有値分解（`EigenvalueDecomposition`）、多項式回帰（`PolynomialRegression`）、Levenberg-Marquardt法による非線形最小二乗法、jStat移植の統計関数を備えており、Pure Dartで実装されている。(出典: [pub.dev/packages/data](https://pub.dev/packages/data)、取得日: 2026-08-14)
- **`scidart` (v0.0.2-dev.12)**: 最終更新が2022年8月（3年以上前）であり、プレリリース版のままメンテナンスが停滞している。(出典: [pub.dev/packages/scidart](https://pub.dev/packages/scidart)、取得日: 2026-08-14)
- **`vector_math` (v2.4.2)**: Flutter公式チームが管理するパッケージだが、固定長（2D/3D/4D）の幾何変換に特化しており、統計解析向けの汎用 $N \times M$ 行列演算はサポート外である。(出典: [pub.dev/packages/vector_math](https://pub.dev/packages/vector_math)、取得日: 2026-08-14)

### Web・パフォーマンスに関する事実
- **Web上でのIsolate非対応**: `dart:isolate`（`Isolate.run` / `Isolate.spawn`）はWebプラットフォームではサポートされていない。(出典: [dart.dev - Concurrency](https://dart.dev/guides/language/concurrency)、取得日: 2026-08-14)
- **`compute()` のWeb挙動**: Flutterの `compute()` 関数は、Web環境では別スレッド（Isolate）を生成せず、**メインスレッド（UIスレッド）上で同期/非同期実行**される。(出典: [flutter.dev - compute function](https://api.flutter.dev/flutter/foundation/compute.html)、取得日: 2026-08-14)
- **Web Workerの要件**: DartでWeb Workerを利用する場合、ネイティブの `Isolate.run` のようなクロージャ呼び出しはできず、別個のエントリポイント（`.dart`）を用意してコンパイルし、メッセージパッシングを行う必要がある。(出典: [dart.dev - Isolates and web workers](https://dart.dev/guides/language/concurrency#isolates-and-web-workers)、取得日: 2026-08-14)
- **数値型のプラットフォーム差異 (dart2js vs Native/WASM)**:
  - `dart2js` コンパイル時、Dartの `int` はJavaScriptの `Number`（64ビット倍精度浮動小数点数）として扱われ、正確に表現できる整数範囲は53ビット（$2^{53} - 1$）に制限される。
  - `dart2wasm` および Native環境では、`int` は完全な64ビット符号付き整数として扱われる。(出典: [dart.dev - Numbers](https://dart.dev/guides/language/numbers)、取得日: 2026-08-14)
- **WebにおけるSIMDの制約**:
  - `dart2js` では `Float32x4` などのSIMD型はJavaScriptオブジェクトまたはTypedArrayによるスカラー処理にフォールバックされ、ハードウェアSIMDの恩恵を受けられない。
  - `dart2wasm`（WasmGC）ではWasm SIMD命令へのコンパイルに対応しつつある。(出典: [github.com/dart-lang/sdk issues](https://github.com/dart-lang/sdk)、取得日: 2026-08-14)

---

## 3. 推測・未確認

- **数百〜数千行 × 十数列の計算コストの体感影響**:
  - データ行列 $X$（例: 2,000行 × 15列）に対する標本共分散行列 $C = \frac{1}{N-1} X^T X$ の計算量は約 $2000 \times 15^2 \approx 4.5 \times 10^5$ 演算、共分散行列（$15 \times 15$）の固有値分解は $O(p^3) \approx 3,375$ 演算である。
  - これは現代のブラウザ（JS/WASM）上でも通常 **数ミリ秒〜数十ミリ秒以内** で終了すると推測される。
  - 単発のPCAや重回帰（$O(p^3)$ の逆行列）であればUIスレッド上でも目立つフレームドロップを起こさない可能性が高いが、反復最適化（ガウス過程回帰のハイパーパラメータ最適化やブートストラップ法など）で数千回のループを行う場合は確実に16.6ms（60fpsのフレーム予算）を超過し、画面フリーズを招く。
- **メモリとGCの影響**:
  - 行列演算でイミュータブルな `Matrix` インスタンスを大量生成・破棄すると、JavaScriptエンジンのガベージコレクション（GC）が頻発し、計算時間以上にGCポーズによるUIカクつきが発生するリスクがある（未検証ベンチマークのため推測）。

---

## 4. Flutter Web 特有の落とし穴まとめ

1. **`compute()` を呼んでもUIブロックは回避できない**:
   - Web環境では `compute()` がメインスレッドで走るため、重い計算を「`compute()` に渡したから安心」と判断するとWeb版のみUIが固まる。
   - 回避策: ループ処理内に `await Future.delayed(Duration.zero)` を挟んでUIイベントループに処理を戻す（チャンク分割）、またはWeb Workerを構築する。
2. **SIMDの性能過信**:
   - `ml_linalg` の最大の強みであるSIMD最適化は、`dart2js` 環境ではスカラーエミュレーションとなるため、期待通りの高速化が得られない。WASMビルド（`flutter build web --wasm`）が可能な環境での利用が推奨される。
3. **JS数値制約とビット演算**:
   - `dart2js` では64ビット整数演算が浮動小数点精度（53ビット）に丸められるため、厳密な64ビット整数のビットマスクやハッシュ計算を行うアルゴリズムでは計算結果がNativeと一致しなくなる場合がある。

---

## 5. 変動しうる情報への注記

- Dart WASM (`dart2wasm`) における Wasm SIMD 最適化状況および Web Worker / マルチスレッド Wasm の Dart SDK サポート状況は、Dart/Flutter のバージョンアップに伴い急速に変化しているため、実装・デプロイ時に最新の SDK リリースノートを確認すること。

---

## 6. 積み残し・判断が必要な点

- 現在の BeanBase では `ml_linalg` をベースとしているが、SVD（特異値分解）や固有値分解（QR法）、非線形最小二乗法等の高度な統計アルゴリズムを安定して自前/ライブラリで完結させるにあたり、`data` パッケージ（Pure Dart）の導入を検討するか、`ml_linalg` 上で自前実装を維持するかの設計判断。
- Web Worker を導入して本格的なバックグラウンド計算基盤を構築するか、当面はデータ規模（数千行程度）とTime-slicing（`Future.delayed`）でメインスレッド処理を維持するかの運用方針判断。
