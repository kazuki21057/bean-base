# BeanBase 統計解析・予測機能 設計書

- 版: 1.3 (2026-07-21) — §12⑤追記(設計書とPython検証値の食い違いはPython側を採用)。§9.4/§9.3/§9.6の誤記訂正を反映(版1.2までの変更履歴: 1.1でUI配置決定§1.2.1、F4配置先を統計画面から抽出画面へ変更。1.2で§12運用方針①〜④追記)
- 対象リポジトリ: BeanBase (Flutter Web PWA / Riverpod / Google Sheets via GAS)
- 実装者: Claude Code (Sonnet)。本書は推論の余地を残さないことを目的に、ファイル名・クラス名・メソッドシグネチャ・数式・テスト期待値まで指定する。
- 本書の根拠: `統計解析機能_事前調査票.md`(コード調査済み回答)およびユーザー決定事項(Q-A〜Q-H)。

## 0. 実装者への絶対規則

1. 数値計算(回帰・PCA・ガウス過程・EI)はすべて Dart ローカル実装とする。Gemini API に計算をさせてはならない。Gemini の役割は「計算済み数値の自然言語解釈」のみ。
2. 本書に記載のないフィールド名・シート列名・クラス名を新規に発明しない。不明点が生じたら実装を止めてユーザーに質問する。
3. 既存の `_jacobiEigenvalueAlgorithm()` (`lib/services/statistics_service.dart:215-334`) は本書 §4.1 の新実装で置き換える。旧実装のコードを流用しない。
4. 各 Phase (§10) の完了条件は「該当テストが全パスすること」。テストを書かずに次 Phase に進まない。
5. 統計量の表示では点推定と不確実性(SE・信頼区間・予測区間)を必ずセットで表示する。点推定のみの表示 UI を作らない。

---

## 1. システム概要

### 1.1 機能一覧と分類

| ID | 機能 | 分類 | Phase |
|----|------|------|-------|
| F0 | 数値計算基盤 (行列演算・固有値分解の書き直し・t分布CDF) | 基盤 | 0 |
| F6 | データ基盤拡張 (産地マスタ化・焙煎日・brew ratio・GAS改修) | 基盤 | 1 |
| F1 | 重回帰分析 (総合評価 ~ 抽出条件+産地ダミー+交互作用、VIF/調整R²/AIC 付き) | 解析(振り返り) | 2 |
| F2 | 味覚6軸 PCA の拡張 (寄与率・負荷量表示の強化、Gemini 深掘り解釈) | 解析(拡張) | 3 |
| F5 | 豆の好みプロファイル (産地×焙煎度の層別統計+検定、記録保存のたび自動更新、履歴保存) | 予測 | 4 |
| F3 | レシピ提案 (ダッシュボードで在庫豆に対し提案、提案履歴を記録) | 予測系の布石 | 5 |
| F4 | 属性ベースレシピ推薦 (ガウス過程回帰+期待改善量 EI によるベイズ最適化) | 予測 | 6 |

### 1.2 アーキテクチャ原則

- 計算層: `lib/services/math/` (純粋 Dart、Flutter 非依存、全関数ユニットテスト対象)
- ドメイン層: `lib/services/*_service.dart` (既存 `StatisticsService` パターンを踏襲、Riverpod Provider 提供)
- 永続化: 既存 `DataService` インターフェース (`lib/services/data_service.dart`) にメソッド追加 → `SheetsService` に実装 → GAS 側シート追加 (§3.4)
- UI: 機能ごとに配置画面を分ける (決定事項、§1.2.1 参照)。F1/F2/F5 は統計画面 (040)、F3 はダッシュボード (001)、F4 は抽出画面 (030) に配置する。
- 表示スコアの丸め: 統計量は小数第2位まで表示 (`toStringAsFixed(2)`)。p 値のみ `p < 0.001` 形式の下限打ち切り表示。

#### 1.2.1 機能ごとのUI配置 (決定事項)

| 機能 | 配置画面 | 配置箇所 | 新規ウィジェット |
|---|---|---|---|
| F1 重回帰分析 | 統計画面 (040, `lib/screens/statistics_screen.dart`) | 既存セクション列 (Filter→KPI→Radar→PCA→Ranking) の後ろに追加 (§5.2) | `lib/widgets/statistics/regression_section.dart` |
| F2 PCA拡張 | 統計画面 (040) | 既存 `pca_scatter_plot.dart` の周辺に追加 (§6.2) | `lib/widgets/statistics/pca_detail_panel.dart` |
| F5 好みプロファイル | 統計画面 (040) | 回帰セクションの後ろに追加 (§7.3) | `lib/widgets/statistics/preference_section.dart` |
| F3 レシピ提案 | ダッシュボード (001, `AppScreen.dashboard`) | 既存の残豆量・直近5件カードとは別枠の新規カード (§7.4) | `lib/widgets/dashboard/recipe_suggestion_card.dart` |
| F4 GP推薦 (レシピ探索) | **抽出画面 (030, `lib/screens/brew_recipe_screen.dart`)** | Pouring Steps 表示の下に「レシピ探索」セクションとして追加 (§7.5)。豆量・メソッドを選んだ流れのまま湯温・比率を探索できる導線を優先し、統計画面ではなく抽出画面に置く | `lib/widgets/brew/gp_explorer_section.dart` |

F1/F2/F5 は「振り返り・分析」目的のため統計画面に集約し、F3/F4 は「今から淹れる」意思決定を助ける目的のため、それぞれの利用文脈に近い画面 (ダッシュボード / 抽出画面) に配置する。

### 1.3 データ規模前提

現在約140件。以下の最小データ条件を各機能に設ける (満たさない場合は計算せず案内文を表示):

| 機能 | 最小条件 | 案内文 (固定文言) |
|------|---------|------------------|
| F1 | n ≥ 30 かつ n ≥ 5×(説明変数の数) | 「データが不足しています (必要: {required}件, 現在: {n}件)」 |
| F2 | n ≥ 3 (既存踏襲) | 既存実装のまま |
| F5 | グループ n ≥ 3 で統計量表示、n ≥ 5 で検定実施 | グループごとに「n不足」バッジ表示 |
| F4 | **メソッドごとに** 重み付き有効サンプル数 n_eff ≥ 6.0 かつ 生データ行数 n ≥ 8 (T3-52 改訂) | 「この豆に近い記録が十分に集まっているメソッドがまだありません。」 |

> **F4 の閾値は T3-52 で改訂した (旧: プールして n_eff ≥ 10)。** メソッド別に GP を分割フィットする方式に変わったため旧閾値では 1〜2 メソッドしか成立せず機能が破綻する。改訂の根拠(本番実測値)と GP が自己正則化する性質については **`docs/gp_multidim_design.md` §4.2** を参照。

---

## 2. 統計理論編 (学習用)

本章は実装仕様であると同時にユーザーの学習資料である。実装者はコード内 doc コメントに本章の式番号 (T-1 等) を引用すること。

### 2.1 重回帰分析 (F1)

#### 2.1.1 モデルと最小二乗推定

n 件の観測、p 個の説明変数。計画行列 X は n×(p+1) (第1列は切片の1)。

```
y = Xβ + ε,  ε ~ N(0, σ²I)                                (T-1)
β̂ = (XᵀX)⁻¹ Xᵀy                                           (T-2)
```

数値計算上は逆行列を直接計算せず、正規方程式 `(XᵀX)β̂ = Xᵀy` を Cholesky 分解で解く (§4.2)。XᵀX は正定値対称であり Cholesky が適用可能。ランク落ち (ダミー変数の多重共線性完全一致など) の場合 Cholesky が失敗するので、その場合はエラーメッセージ「説明変数が線形従属です」を返す。

#### 2.1.2 分散推定と検定

```
残差: e = y − Xβ̂,  RSS = eᵀe
σ̂² = RSS / (n − p − 1)                                     (T-3)
Var(β̂) = σ̂² (XᵀX)⁻¹  →  SE(β̂ⱼ) = √[σ̂² ((XᵀX)⁻¹)ⱼⱼ]      (T-4)
tⱼ = β̂ⱼ / SE(β̂ⱼ)  ~  t(n−p−1)  (帰無仮説 βⱼ=0 の下)       (T-5)
p値 = 2 × (1 − F_t(|tⱼ|; n−p−1))                            (T-6)
```

F_t は t 分布の CDF。実装は正則化不完全ベータ関数による (§4.3)。

#### 2.1.3 適合度・モデル選択・診断

```
R² = 1 − RSS/TSS,  TSS = Σ(yᵢ − ȳ)²                        (T-7)
調整済みR² = 1 − (1−R²)(n−1)/(n−p−1)                        (T-8)
AIC = n·ln(RSS/n) + 2(p+2)                                  (T-9)
VIFⱼ = 1 / (1 − Rⱼ²)                                        (T-10)
```

- (T-9) は正規線形モデルの AIC (定数項 n·ln(2π)+n を省略した形)。比較は同一データ内でのみ有効。推定パラメータ数は係数 p+1 個+σ² の計 p+2。
- (T-10) の Rⱼ² は「変数 j を他の説明変数で回帰したときの決定係数」。VIF > 10 で深刻な多重共線性、> 5 で注意。UI にはしきい値超えの変数に警告バッジを表示する。
- 残差診断: 残差 vs 予測値の散布図 (等分散性の目視確認用) を fl_chart で表示。正規Q-Qプロットは Phase 2 では実装しない (スコープ外と明記)。

#### 2.1.4 カテゴリ変数と交互作用

- k 水準のカテゴリはダミー変数 k−1 個で表現 (基準水準は係数0)。基準水準は最多頻度の水準とする。係数 β̂ⱼ の解釈は「他条件一定のとき、基準水準に対する期待スコア差」。
- 交互作用項 `x₁·x₂` を含める場合、主効果を必ず両方含める (階層原則)。
- 連続変数は中心化 (平均を引く) してから交互作用を作る。中心化しないと主効果の解釈が「相手変数=0のときの効果」となり、湯温0℃のような無意味な条件になるため。

#### 2.1.5 本データ固有の注意 (UI の注記文として表示する)

1. スコア (0–10 整数) は順序尺度を間隔尺度として扱う近似である。
2. 観測データであり無作為化されていないため、係数は因果効果ではなく関連の記述である。
3. `scoreOverall` の入力デフォルトが 7 のため、未編集保存によるバイアスがあり得る (§5.1 の前処理で検出)。

### 2.2 主成分分析 (F2)

#### 2.2.1 定式化

変数を標準化 (平均0, 分散1) した行列 Z に対し、相関行列 R = ZᵀZ/(n−1) の固有値分解:

```
R = VΛVᵀ,  Λ = diag(λ₁ ≥ λ₂ ≥ … ≥ λ_m ≥ 0)               (T-11)
第i主成分スコア: tᵢ = Z vᵢ                                  (T-12)
寄与率: λᵢ / m   (相関行列では Σλ = m = 変数数)             (T-13)
累積寄与率: Σᵢ₌₁..k λᵢ / m                                  (T-14)
負荷量 (loading): Lⱼᵢ = vⱼᵢ √λᵢ                              (T-15)
```

(T-15) の負荷量は「元変数 j と主成分 i の相関係数」に一致する (相関行列ベースの場合)。既存実装 (statistics_service.dart:161-164) は共分散行列を使っているが、味覚6軸はすべて 0–10 の同一尺度なので共分散/相関の差は小さい。ただし F2 では**相関行列ベースに統一**する (分散の大きい軸への支配を避け、負荷量=相関の解釈を成立させるため)。これは既存動作の変更であり、§6.2 に明記。

#### 2.2.2 解釈の統計的根拠

- 採用成分数: 固有値 ≥ 1 (Kaiser 基準) と累積寄与率 ≥ 70% を UI に併記し、判断材料として提示 (自動判定はせず PC1/PC2 表示は維持)。
- 負荷量の絶対値 ≥ 0.5 の変数を「主要変数」として Gemini 解釈プロンプトに渡す (§8.2)。

### 2.3 ガウス過程回帰 (F4)

#### 2.3.1 モデル

訓練入力 X (n×d)、出力 y (n)。カーネルは ARD なしの RBF + ノイズ:

```
k(x, x') = σ_f² exp(− ||x − x'||² / (2ℓ²))                  (T-16)
K = [k(xᵢ, xⱼ)] + σ_n² I                                    (T-17)
```

新点 x* の予測分布は条件付き正規分布 (準1級「多変量正規分布の条件付き分布」の直接の応用):

```
μ(x*) = k*ᵀ K⁻¹ y                                           (T-18)
σ²(x*) = k(x*,x*) − k*ᵀ K⁻¹ k*                              (T-19)
k* = [k(x*, x₁), …, k(x*, x_n)]ᵀ
```

実装は K の Cholesky 分解 `K = LLᵀ` を用い、`α = K⁻¹y` を前進・後退代入で解く (逆行列は作らない)。

- 入力 **d=4: 湯温(℃), brew ratio, 総抽出時間(秒), 正規化粒度 gNorm** (T3-52 で 3→4 に拡張)。各次元を訓練データの平均・標準偏差で標準化してからカーネルに入れる。
  - `gNorm = クリック数 / そのミルの挽き目調整段階数` ∈ (0,1]。ミルごとに目盛りのスケールが違う (Timemore c3 pro=20 / Kingrinder K6=180) ため生値は投入できない。正規化規則・ミル間比較可能性の限界・ミル不一致の重み係数は **`docs/gp_multidim_design.md` §3** を参照。
  - **メソッドはカテゴリ変数のため連続次元に入れない。** メソッドごとに別々の GP をフィットし、最良予測 μ を横断比較して「有望なメソッド」を提示する (同 §4)。
- y は scoreOverall をそのまま使う (平均を引いた残差を GP に、平均を μ に足し戻す「ゼロ平均 GP + 定数平均」方式)。

#### 2.3.2 ハイパーパラメータ

勾配法は実装しない。以下の固定グリッドで対数周辺尤度 (T-20) 最大の組を選ぶ:

```
log p(y|X,θ) = −½ yᵀK⁻¹y − ½ log|K| − (n/2) log 2π          (T-20)
グリッド: ℓ ∈ {0.5, 1.0, 2.0}, σ_f ∈ {0.5, 1.0, 2.0}, σ_n ∈ {0.5, 1.0, 1.5}
```

log|K| は Cholesky の対角要素から `2·Σ log Lᵢᵢ` で計算。27 通り×n≤300 程度なら Web でも即時計算可能。

#### 2.3.3 ベイズ最適化: 期待改善量 (EI)

現在の最良観測値 f* = max(y)。候補点 x の EI:

```
z = (μ(x) − f* − ξ) / σ(x),  ξ = 0.01
EI(x) = (μ(x) − f* − ξ) Φ(z) + σ(x) φ(z)   (σ(x)>0)         (T-21)
EI(x) = max(μ(x) − f* − ξ, 0)              (σ(x)=0)
```

Φ, φ は標準正規の CDF/PDF (§4.3)。EI は「活用 (μ が高い) と探索 (σ が大きい) のバランス」を取る獲得関数であり、σ→0 の極限で貪欲な活用に一致する。

候補点グリッド (**T3-52 で 2 段階探索に改訂**): 4 次元の全探索は 1 メソッドあたり約 1.9 万点になり Web で数秒フリーズするため、**粗グリッド 750 点 (ランキング用) → μ 最大点の周囲 ±1 粗ステップを細刻みで再探索 (最大 1575 点)** の 2 段階にする。刻み幅の一覧は **`docs/gp_multidim_design.md` §5.4** を参照。全評価点で μ, σ, EI を求め、(a) μ 最大点を「おすすめ」、(b) EI 最大点を「試してみる価値がある条件」として2種類提示する。

> 旧仕様 (d=3、湯温17×比率9×時間9=1377点の全探索) は T3-52 で置き換えられた。

### 2.4 層別統計と平均差の検定 (F5)

グループ g (産地×焙煎度) の統計量: n_g, 平均 x̄_g, 不偏標準偏差 s_g, 平均の95%信頼区間:

```
CI = x̄_g ± t_{0.975, n_g−1} · s_g/√n_g                      (T-22)
```

「好み傾向」の判定は Welch の t 検定 (等分散を仮定しない):

```
t = (x̄_g − x̄_rest) / √(s_g²/n_g + s_rest²/n_rest)           (T-23)
自由度 ν: Welch–Satterthwaite 近似
ν = (s_g²/n_g + s_rest²/n_rest)² / [ (s_g²/n_g)²/(n_g−1) + (s_rest²/n_rest)²/(n_rest−1) ]  (T-24)
```

x̄_rest はグループ g を除いた全レコードの平均。**多重比較の注意**: グループ数 m 個を同時検定するため、Bonferroni 補正 α' = 0.05/m を適用した判定を「有意」バッジに使う。未補正 p 値も併記する (学習目的)。

### 2.5 信頼区間と予測区間の区別 (全機能共通の表示原則)

- 信頼区間: パラメータ (平均や係数) の不確実性。データが増えれば狭くなる。
- 予測区間: 次の1回の観測値の不確実性。データが増えても σ の分だけは残る。

F1 の予測表示では予測区間 (T-25) を使う:

```
ŷ* ± t_{0.975, n−p−1} · σ̂ √(1 + x*ᵀ(XᵀX)⁻¹x*)              (T-25)
```

F4 の GP では (T-19) の σ(x*) に σ_n² を加えた √(σ²(x*) + σ_n²) を予測区間の幅として使う。

---

## 3. データモデル・永続化の変更 (F6)

### 3.1 新規モデル: OriginMaster (産地マスタ、名寄せ方針=案A)

新規ファイル `lib/models/origin_master.dart`。既存 `BeanMaster` の json_serializable パターンを踏襲。

```dart
@JsonSerializable()
class OriginMaster {
  final String id;          // 'origin_' + タイムスタンプ (既存ID採番規約に合わせる)
  final String countryCode; // ISO 3166-1 alpha-2 (例 'ET')
  final String nameJa;      // 例 'エチオピア'  (表示名・名寄せの正)
  final String nameEn;      // 例 'Ethiopia'
  final String region;      // 'アフリカ' | '中南米' | 'アジア・太平洋' | 'その他'
}
```

初期データ (シートに投入する固定行): エチオピア ET/アフリカ、ケニア KE/アフリカ、タンザニア TZ/アフリカ、ルワンダ RW/アフリカ、ブラジル BR/中南米、コロンビア CO/中南米、グアテマラ GT/中南米、コスタリカ CR/中南米、ホンジュラス HN/中南米、ペルー PE/中南米、インドネシア ID/アジア・太平洋、ベトナム VN/アジア・太平洋、インド IN/アジア・太平洋、イエメン YE/その他、ブレンド XX/その他。ユーザーは設定画面から追加可能とする。

### 3.2 既存モデルの変更

`lib/models/bean_master.dart`:

- 追加: `String originId` (デフォルト '')。`origin` (自由入力文字列) は後方互換のため**残す** (削除しない)。保存時は選択された OriginMaster の `nameJa` を `origin` に同時コピーし、既存の `CoffeeRecord.origin` コピー処理 (brew_evaluation_screen.dart:193) を壊さない。
- 追加: `DateTime? roastDate` (焙煎日、null 許容。JsonKey で既存 `_parseDateTime` を再利用)。

`lib/models/coffee_record.dart`:

- 追加: `String originId` (デフォルト ''。保存時に BeanMaster.originId をコピー。既存 origin コピーの隣、brew_evaluation_screen.dart:193 と同じ箇所に追記)。
- 追加: `int? ageDays` は**持たない**。豆鮮度 (経過日数) は表示・計算時に `brewedAt.difference(bean.roastDate).inDays` で導出する (二重保存によるデータ不整合を避ける)。
- brew ratio も**保存しない**。導出プロパティとして追加:

```dart
/// 湯量/豆量の比。豆量0または欠測時は null (T-注: 統計処理では欠測行として除外)
double? get brewRatio => beanWeight > 0 ? totalWater / beanWeight : null;
```

UI 変更: 豆登録画面 (`bean_create_screen.dart`) の産地テキストフィールド (150-154行) を OriginMaster 選択ドロップダウン+「新規産地追加」ボタンに置換。焙煎日入力 (DatePicker, 任意入力) を追加。

### 3.3 既存データの移行 (名寄せ)

新規ファイル `lib/services/migration_service.dart` + 設定画面に「データ移行」セクションを追加。

処理: (1) `bean_master` 全件取得 → (2) `origin` 文字列を正規化辞書で OriginMaster に突合 → (3) 一致した豆の `originId` を更新 → (4) 突合できなかった origin 文字列の一覧を画面表示し、ユーザーが手動でマスタを選択して確定。正規化辞書 (完全一致、前後空白除去・大文字小文字無視):

```dart
const originAliasMap = {
  'エチオピア': 'ET', 'ethiopia': 'ET', 'ケニア': 'KE', 'kenya': 'KE',
  'ブラジル': 'BR', 'brazil': 'BR', 'コロンビア': 'CO', 'colombia': 'CO',
  'グアテマラ': 'GT', 'guatemala': 'GT', 'コスタリカ': 'CR',
  'ホンジュラス': 'HN', 'ペルー': 'PE', 'タンザニア': 'TZ',
  'ルワンダ': 'RW', 'インドネシア': 'ID', 'マンデリン': 'ID',
  'ベトナム': 'VN', 'インド': 'IN', 'イエメン': 'YE', 'ブレンド': 'XX',
};
```

移行は冪等 (originId が既に入っている豆はスキップ) とし、何度実行しても安全にする。

### 3.4 新規シートと GAS 改修

#### 3.4.1 新規シート定義

| シート名 | 列 (1行目ヘッダー、日本語) | 用途 |
|---------|---------------------------|------|
| `origin_master` | 産地ID / 国コード / 産地名 / 産地名(英) / 地域 | §3.1 |
| `analysis_history` | 履歴ID / 作成日時 / 種別 / データ件数 / 本文JSON | F5・F1 のスナップショット (§7.3) |
| `recipe_suggestions` | 提案ID / 作成日時 / 豆ID / 産地ID / 焙煎度 / 湯温 / 湯豆比 / 抽出時間 / 提案根拠 / 採否 / 結果記録ID | F3 (§7.4) |

`本文JSON` 列には Dart 側で `jsonEncode` した結果オブジェクトを1セルに格納する (Sheets のセル上限 50,000 文字以内。超過時は保存を中止しエラー表示)。

#### 3.4.2 GAS ソースのリポジトリ内管理 (決定事項、§12④で clasp CLI 完全自動化を採用)

GAS ソースをリポジトリに取り込み、`clasp` で Claude Code から直接同期する(ユーザーの手作業を初回のみに限定する):

1. リポジトリ直下に `gas/` ディレクトリを新設: `gas/Code.gs`, `gas/appsscript.json`, `gas/.clasp.json` (scriptId はユーザーが記入)。
2. **初回のみユーザー作業**: (a) 現行 GAS エディタの内容を `gas/Code.gs` に手動コピー (Claude Code はコピー後の内容を正とする、以後の同期はコード側が正)。(b) `clasp login` (ブラウザでの Google アカウント認可。OAuth フローのため Claude Code は代行できず、ユーザーが1回だけ実施)。**これ以降のコード変更・反映・デプロイは全て Claude Code が担当する**(§12③)。
3. デプロイ手順を `gas/README.md` に記載: `npm i -g @google/clasp` → (初回のみ)`clasp login` → 以降は Claude Code が Bash から `clasp push`(コード反映)→`clasp deploy --deploymentId <既存デプロイID>`(URL を変えずに既存デプロイを更新)を直接実行する。GAS エディタを開いての手動デプロイ操作は不要にする。
4. `Code.gs` の要求仕様: シート名ホワイトリスト配列 `const ALLOWED_SHEETS = [...]` を1箇所に定義し、既存7シート+新規3シートを列挙。doGet (`?sheet=`) と doPost の両方でこの配列を検証。**注意: 現行 GAS が汎用処理かホワイトリスト式かは調査票の範囲外。実装時に `gas/Code.gs` の実物を確認し、汎用処理ならホワイトリスト化も同時に行う (セキュリティ改善)。**
5. **新規シートの自動生成 (決定事項)**: `origin_master`/`analysis_history`/`recipe_suggestions` の3シートをユーザーがスプレッドシート上で手動作成する必要はない。`Code.gs` に冪等な `ensureSheet_(name, headers)` ヘルパーを実装し (`SpreadsheetApp` で該当シートが無ければ `insertSheet` + ヘッダー行書き込み、既にあれば何もしない)、doGet/doPost の先頭、または該当シートへの初回アクセス時に呼び出す。

#### 3.4.3 DataService 追加メソッド

`lib/services/data_service.dart` の抽象クラスに追加し、`SheetsService` に実装 (`FirestoreService` は未使用のため `UnimplementedError` で可):

```dart
Future<List<OriginMaster>> fetchOriginMasters();
Future<void> saveOriginMaster(OriginMaster origin);
Future<List<AnalysisSnapshot>> fetchAnalysisSnapshots({String? type});
Future<void> saveAnalysisSnapshot(AnalysisSnapshot snapshot);
Future<List<RecipeSuggestion>> fetchRecipeSuggestions();
Future<void> saveRecipeSuggestion(RecipeSuggestion suggestion);
Future<void> updateRecipeSuggestion(RecipeSuggestion suggestion); // 採否・結果記録IDの追記用
```

### 3.5 焙煎度の正規化 (F1/F4/F5 の前提)

`CoffeeRecord.roastLevel` は String。以下の順序尺度マップを `lib/services/math/encoding.dart` に定数定義:

```dart
const roastOrdinalMap = {
  '浅煎り': 1.0, 'ライト': 1.0, 'シナモン': 1.0,
  '中浅煎り': 2.0, 'ミディアムライト': 2.0,
  '中煎り': 3.0, 'ミディアム': 3.0, 'ハイ': 3.0,
  '中深煎り': 4.0, 'シティ': 4.0, 'フルシティ': 4.0,
  '深煎り': 5.0, 'フレンチ': 5.0, 'イタリアン': 5.0,
};
```

マップに無い値は欠測扱い (該当行を除外し、除外件数を UI に表示)。実データの roastLevel の実際の値集合は実装時に `original-data/coffee_data - coffee_data.csv` で確認し、必要ならマップに追記する (追記した場合は本書も更新)。

---

## 4. 数値計算基盤 (F0)

新規ディレクトリ `lib/services/math/`。全ファイル Flutter 非依存 (import は `dart:math` と `ml_linalg` のみ許可)。

### 4.1 対称行列の固有値分解 (Jacobi 法の書き直し)

新規ファイル `lib/services/math/eigen.dart`。

```dart
class EigenResult {
  final List<double> eigenvalues;        // 降順ソート済み
  final List<List<double>> eigenvectors; // eigenvectors[i] が eigenvalues[i] に対応する単位ベクトル
}

/// 実対称行列の固有値分解 (巡回 Jacobi 法)
/// [a] は対称行列 (対称性はチェックし、非対称なら ArgumentError)
EigenResult eigenSymmetric(List<List<double>> a,
    {int maxSweeps = 50, double tol = 1e-12});
```

アルゴリズム仕様 (Golub & Van Loan, *Matrix Computations* 4th ed., §8.5 の古典的巡回 Jacobi):

1. A をコピー、V = I で初期化。
2. 1スイープ = 全ての上三角要素 (p<q) を順に処理。off(A) = √(Σ_{p<q} a_pq²) が `tol × ||A||_F` 未満になったら収束。
3. 各 (p,q) について a_pq ≠ 0 なら回転角を数値安定な式で計算:

```
θ = (a_qq − a_pp) / (2 a_pq)
t = sign(θ) / (|θ| + √(θ² + 1))     // tan
c = 1 / √(t² + 1),  s = t·c          // cos, sin
```

4. A ← JᵀAJ, V ← VJ (J は (p,q) 平面の Givens 回転)。更新は該当行・列のみを陽に書き換える (旧実装のような全行列積を取らない)。
5. 収束後、対角成分を固有値として固有ベクトル (V の列) と組にし、固有値降順でソートして返す。maxSweeps 到達で未収束なら `StateError('Jacobi法が収束しませんでした')`。

`StatisticsService.calculatePca()` 内の `_jacobiEigenvalueAlgorithm()` 呼び出しを `eigenSymmetric()` に差し替え、旧関数 (215-334行) を削除する。

### 4.2 線形ソルバ

新規ファイル `lib/services/math/linear_solve.dart`。

```dart
/// 正定値対称行列の Cholesky 分解 A = L·Lᵀ。失敗時 StateError('行列が正定値ではありません')
List<List<double>> cholesky(List<List<double>> a);
/// L·Lᵀ x = b を前進・後退代入で解く
List<double> choleskySolve(List<List<double>> l, List<double> b);
/// 対称正定値 A について A⁻¹ を返す (F1 の SE 計算用。列ごとに choleskySolve)
List<List<double>> choleskyInverse(List<List<double>> l);
/// log|A| = 2 Σ log(Lᵢᵢ)  (F4 の周辺尤度用)
double choleskyLogDet(List<List<double>> l);
```

対角に `1e-10` のジッター加算は cholesky 内では行わない (F4 の K 構築側で σ_n² が担う。F1 で失敗した場合は共線性エラーとしてユーザーに見せるのが正しい挙動)。

### 4.3 確率分布関数

新規ファイル `lib/services/math/distributions.dart`。

```dart
double normalPdf(double z);                       // φ(z) = exp(−z²/2)/√(2π)
double normalCdf(double z);                       // Φ(z)。erf 経由: Φ(z)=0.5·(1+erf(z/√2))
double erf(double x);                             // Abramowitz–Stegun 7.1.26 近似 (|誤差|<1.5e-7)
double studentTCdf(double t, double df);          // 正則化不完全ベータ関数経由
double regularizedIncompleteBeta(double a, double b, double x); // 連分数展開 (Lentz 法, 最大200項, tol 1e-12)
double tQuantile(double p, double df);            // studentTCdf の二分法逆関数 (区間 [-50,50], tol 1e-9)
```

t 分布 CDF の恒等式 (実装式): `t ≥ 0 のとき F_t(t; ν) = 1 − ½·I_{ν/(ν+t²)}(ν/2, ½)`、t<0 は対称性で処理。I は正則化不完全ベータ。

### 4.4 計画行列ビルダ

新規ファイル `lib/services/math/design_matrix.dart`。

```dart
class DesignMatrixResult {
  final List<List<double>> x;      // n×(p+1)、第1列=1 (切片)
  final List<double> y;
  final List<String> columnNames;  // ['切片', '湯温(中心化)', ...] 表示用
  final int excludedRows;          // 欠測等で除外した行数
  final Map<String, int> categoryCounts; // 産地ダミーの水準別件数
}

DesignMatrixResult buildRegressionMatrix(List<CoffeeRecord> records,
    Map<String, OriginMaster> originById);
```

構築ルール (F1 用、この順で列を作る):

1. 行フィルタ: `scoreOverall` 記録済み・`brewRatio != null`・`temperature > 0`・`totalTime > 0`・roastLevel がマップ解決可・originId 解決可、の全条件を満たす行のみ採用。除外行数を記録。
2. 連続変数 (すべて採用行の平均で中心化): 湯温、brewRatio、totalTime/60 (分に変換)、焙煎順序値 (roastOrdinalMap)。`roastDate` の記録率が採用行の 70% 以上の場合のみ「経過日数」列を追加 (未満なら列を作らず UI に「焙煎日の記録が増えると鮮度分析が追加されます ({rate}%)」と表示)。
3. 産地ダミー: originId ごとの件数を数え、n < 5 の産地は地域 (`OriginMaster.region`) に統合、それでも n < 5 なら水準「その他」に統合。最多水準を基準 (ダミー無し) とし、残り各水準に1列。
4. 交互作用: `焙煎順序値(中心化) × 湯温(中心化)` の1列のみ (v1 の固定仕様。追加はユーザー承認後)。
5. 列数チェック: p+1 > n/5 なら構築を中止し §1.3 の案内文を返す。

---

## 5. F1: 重回帰分析

### 5.1 サービス

新規ファイル `lib/services/regression_service.dart`。

```dart
class RegressionCoefficient {
  final String name; final double beta; final double se;
  final double tValue; final double pValue; final double vif; // 切片の vif は double.nan
}
class RegressionResult {
  final List<RegressionCoefficient> coefficients;
  final int n; final int p;
  final double r2; final double adjR2; final double aic; final double sigmaHat;
  final List<double> fitted; final List<double> residuals;
  final int excludedRows; final int defaultScoreCount; // §2.1.5(3) scoreOverall==7 の件数
  final DesignMatrixResult design;
}

class RegressionService {
  RegressionResult? fit(List<CoffeeRecord> records, Map<String, OriginMaster> originById);
  /// 条件を与えて予測値と95%予測区間 (T-25) を返す
  ({double point, double lower, double upper}) predict(
      RegressionResult model, {required double temperature, required double brewRatio,
      required double totalTimeMin, required double roastOrdinal, required String originLevel});
}
final regressionServiceProvider = Provider((ref) => RegressionService());
```

計算手順: buildRegressionMatrix → XᵀX を組む → cholesky → choleskySolve で β̂ → 残差/RSS → (T-3)〜(T-10)。VIF は各説明変数を残りで回帰して算出 (切片除く)。データ不足・共線性エラー時は null を返し、UI が案内文を表示。

### 5.2 UI

新規ファイル `lib/widgets/statistics/regression_section.dart`。statistics_screen.dart の Ranking セクションの後に追加。構成:

1. ヘッダ「回帰分析: 何が総合評価を動かすか」+ 情報アイコン (タップで §2.1.5 の注意3点をダイアログ表示)。
2. モデルサマリ行: n / 調整済みR² / AIC / 除外行数 / デフォルトスコア件数警告 (defaultScoreCount が n の30%超なら黄色警告)。
3. 係数テーブル: 変数名 / β̂ / SE / t / p / VIF。p < 0.05/(検定数) で太字+「*」、VIF>5 で警告バッジ。0–10 スコアに対する係数の実感を持たせるため、各行に「+1単位あたり {beta} 点」の副文を表示。
4. 残差 vs 予測値 散布図 (fl_chart ScatterChart)。
5. 「AIで解釈」ボタン → §8.1 のプロンプトで Gemini 呼び出し (既存 `AiAnalysisService` パターン)。
6. 「このモデルで予測」ミニフォーム: 湯温/比率/時間/焙煎度/産地を入力 → predict() の点推定+95%予測区間を表示。

---

## 6. F2: PCA 拡張

### 6.1 変更点

`lib/services/statistics_service.dart` の `calculatePca()` を次のとおり改修:

1. 固有値分解を `eigenSymmetric()` に差し替え (§4.1)。
2. 共分散行列 → 相関行列に変更 (§2.2.1 の理由)。実装: 中心化後に各列を標準偏差で割ってから C を計算。標準偏差 0 の列 (全件同値) は除外し、除外した軸名を結果に含める。
3. `PcaComponent` に追加フィールド: `double eigenvalue`, `double contributionRatio` (T-13), `double cumulativeRatio` (T-14)。負荷量は (T-15) で再定義。
4. 全成分 (最大6) の固有値・寄与率を保持し、表示は従来どおり PC1/PC2。

### 6.2 UI 拡張

`lib/widgets/statistics/pca_scatter_plot.dart` の周辺に追加 (別ウィジェット `pca_detail_panel.dart`):

1. 寄与率バー: PC1〜PC6 の寄与率と累積寄与率の棒グラフ+Kaiser 基準線 (固有値1 ⇔ 寄与率 1/6 ≈ 16.7%)。
2. 負荷量テーブル: 6軸 × PC1/PC2、|L| ≥ 0.5 をハイライト。
3. 「AIで深掘り解釈」ボタン: §8.2 の新プロンプト (従来より入力情報を増強) で呼び出し。既存動作変更 (相関行列化) により散布図の座標が従来と変わることをリリースノート的に UI 内に一行表示: 「v1.1: 分析方法を相関行列ベースに改善しました」。

---

## 7. F5 / F3 / F4: 予測系

### 7.1 F5: 好みプロファイル

新規ファイル `lib/services/preference_service.dart`。

```dart
class PreferenceGroupStat {
  final String originLevel;   // 産地名 (統合後の水準名)
  final String roastLabel;    // '浅煎り' 等 (順序値から逆引きした代表ラベル)
  final int n; final double mean; final double sd;
  final double ciLower; final double ciUpper;      // (T-22)
  final double? welchT; final double? welchP;      // n>=5 のみ (T-23,24)
  final bool significant;                          // Bonferroni 補正後 p < 0.05/m
}
class PreferenceProfile {
  final DateTime createdAt; final int totalRecords;
  final List<PreferenceGroupStat> groups;          // mean 降順
  final List<String> statements;                   // 例 '「エチオピア×浅煎り」を高評価する傾向 (平均8.2, 全体+1.4, p=0.003)'
}
class PreferenceService {
  PreferenceProfile build(List<CoffeeRecord> records, Map<String, OriginMaster> originById);
}
```

statements 生成規則 (固定テンプレート、Gemini 不使用): significant なグループについて `「{origin}×{roast}」を{高|低}評価する傾向 (平均{mean}, 全体{±diff}, p={p})`。significant なグループが無い場合は `現時点で統計的に明確な好みの偏りは検出されていません (データ蓄積中)`。

自動更新 (Q-B): 抽出記録の保存成功後 (brew_evaluation_screen.dart の保存処理完了直後) に build() を実行し、`AnalysisSnapshot(type: 'preference')` として保存する。保存失敗は記録本体の保存を妨げない (try-catch で握り、SnackBar で通知のみ)。

### 7.2 履歴モデル

新規ファイル `lib/models/analysis_snapshot.dart`。

```dart
@JsonSerializable()
class AnalysisSnapshot {
  final String id;            // 'snap_' + epoch millis
  final DateTime createdAt;
  final String type;          // 'preference' | 'regression'
  final int dataCount;
  final String payloadJson;   // PreferenceProfile または RegressionResult の要約を jsonEncode
}
```

regression 型は F1 画面の「スナップショット保存」ボタン押下時のみ保存 (自動ではない)。payloadJson には係数テーブルとサマリのみ入れ、fitted/residuals は含めない (サイズ削減)。

### 7.3 F5 UI

新規ファイル `lib/widgets/statistics/preference_section.dart` (statistics_screen に追加):

1. 最新プロファイルの statements をカード表示。
2. グループ統計テーブル: 産地×焙煎 / n / 平均 [95%CI] / p / 有意バッジ。n<5 は「n不足」バッジ。
3. 履歴タブ: analysis_history から type='preference' を取得し、「特定グループの平均の推移」を折れ線 (fl_chart LineChart, x=作成日時, y=mean, CI を半透明帯で表示)。表示グループはドロップダウンで選択。

### 7.4 F3: レシピ提案 (ダッシュボード)

前提確認: 在庫概念は既存 (bean_stock_calculator_test.dart の存在から在庫計算ロジックあり)。実装時に在庫残量の取得 API を実コードで特定し、「残量 > 0 の豆」を対象とする。特定できない場合は「全豆マスタのうち直近30日に抽出記録がある豆」を代替定義とし、ユーザーに確認する。

新規ファイル `lib/services/suggestion_service.dart`, `lib/models/recipe_suggestion.dart`, `lib/widgets/dashboard/recipe_suggestion_card.dart`。

```dart
@JsonSerializable()
class RecipeSuggestion {
  final String id; final DateTime createdAt;
  final String beanId; final String originId; final String roastLevel;
  final double temperature; final double brewRatio; final int totalTimeSec;
  final String rationale;   // 'gp_mean' | 'gp_ei' | 'group_best'
  final String accepted;    // '' (未回答) | 'yes' | 'no'
  final String resultRecordId; // 提案どおり淹れた記録の id (後から紐付け)
}
```

提案ロジック (SuggestionService.suggestFor(bean)):

1. F4 の GP モデル (§7.5) を豆の (originId, roastOrdinal) で構築。n_eff ≥ 10 なら μ 最大点を提案 (rationale='gp_mean')。週1回 (提案履歴の直近 rationale を見て7件に1件) は EI 最大点を提案 (rationale='gp_ei')し、カードに「実験的な提案です」と表示。
2. n_eff < 10 なら同グループの過去最高スコア記録の条件をそのまま提案 (rationale='group_best')。それも無ければ提案しない。
3. カード表示: 豆名+「今日はこのレシピはいかが?」+ 湯温/比率/時間 + 予測スコアと区間 (GP時のみ) + [この条件で淹れる] [今回はパス] ボタン。
4. [淹れる] → recipe_suggestions に accepted='yes' で保存し、抽出記録フローに条件をプリフィル遷移。記録保存完了時に resultRecordId を updateRecipeSuggestion で書き戻す。[パス] → accepted='no' で保存。カード表示自体は保存しない (表示のたびに行が増えるのを防ぐ)。

推奨焙煎度の表示 (Q-F 後半): カード下部に「この産地は {roast} が高評価です」を F5 の PreferenceProfile から引いて表示 (該当産地で最も mean が高い焙煎水準、n ≥ 3 のもの)。在庫豆の焙煎度がそれと一致する場合カードに「おすすめ焙煎度と一致」バッジ。

### 7.5 F4: GP 推薦エンジン

新規ファイル `lib/services/gp_service.dart`。

**T3-52 (2026-07-30) で 4 次元化・メソッド別フィットに改訂。確定仕様は `docs/gp_multidim_design.md` §5 (API)・§6 (UI) が正本**であり、実装はそちらに従うこと。以下は要約。

```dart
typedef GpPoint = ({double t, double r, int s, double g}); // g = 正規化粒度 (0,1]

class GpModel { /* 標準化パラメータ, L, α, θ, f*, n_eff, nRows, methodId */ }
class GpPrediction { final double mean; final double sd; final double ei; }
class GpService {
  /// [methodId] のメソッドについて (originId, roastOrdinal, targetGrinderId) 向けに
  /// 重み付き学習。重み = 産地/焙煎度の重み (同一1.0 / 同産地・焙煎差1以内0.5 / 他0.2)
  ///        × ミル不一致係数 (目標ミルと同じ 1.0 / 違う 0.5)。
  /// 重みは K の対角ノイズを σ_n²/w にする形で反映。
  GpModel? fitForMethod(List<CoffeeRecord> records, {
    required String methodId, required String originId, required double roastOrdinal,
    required String targetGrinderId, required Map<String, int> grindStepsByGrinderId});
  GpPrediction predict(GpModel model, double temperature, double brewRatio,
      int totalTimeSec, double grindNorm);
  ({GpPrediction best, GpPoint bestX, GpPrediction explore, GpPoint exploreX})
      optimize(GpModel model, {bool refine = true});
}
```

- n_eff = Σwᵢ。**n_eff < 6.0 または nRows < 8 なら fitForMethod は null** (§1.3 の改訂、根拠は `docs/gp_multidim_design.md` §4.2)。旧 3 次元の `fit()` は削除済み。
- 重み付けの実装: 観測 i のノイズ分散を σ_n²/wᵢ とする (信頼度の低いデータほどノイズ大として扱う。heteroscedastic GP の最簡形)。
- optimize は §2.3.3 の 2 段階グリッド。`refine: false` で粗グリッドのみ (メソッド横断ランキング用)。
- **抽出画面 (030、`brew_recipe_screen.dart`) に「レシピ探索」セクション (`lib/widgets/brew/gp_explorer_section.dart`、§1.2.1 決定事項) を置く**。T3-52 で選択項目を **産地×焙煎度 → 豆 + ミル** に変更し (産地・焙煎度は `BeanMaster` から導出)、①メソッド比較表 (予測スコア μ + 95%予測区間 + 確信度バッジ、μ 降順) ②表示中メソッドの推奨条件カード (湯温/比率/時間/**粒度はクリック数に逆変換**) ③湯温×比率ヒートマップ (時間・粒度は推奨値で固定) を表示する。ヒートマップは fl_chart に無いため、`Table`+色付き `Container` (5℃×1.0比率の粗グリッド 4×5 に間引き) で実装する。
- **T3-53 (2026-08-01) で「探索の検証状況」画面 (045) を新設。確定仕様は `docs/exploration_status_design.md` が正本**。GP の学習集合とは別に、豆単位の試行回数・スコア推移・条件分布を可視化する。

---

## 8. Gemini 連携仕様

既存 `AiAnalysisService` (ai_analysis_service.dart) のパターン (モデルフォールバック・apiKey 引数渡し・日本語指示) を踏襲し、メソッドを追加する。プロンプトは以下テンプレートをそのまま使う (数値は Dart 側で埋め込む。Gemini に再計算させる文言を入れない)。

### 8.1 回帰解釈 (`interpretRegression`)

```
あなたはコーヒー抽出と統計学の専門家です。以下は重回帰分析の結果です(計算済み。再計算や数値の変更はしないこと)。
モデル: 総合評価(0-10) ~ 抽出条件 + 産地 + 交互作用 / n={n}, 調整済みR²={adjR2}, AIC={aic}
係数表(変数名, 係数, 標準誤差, p値, VIF):
{coefTableText}
注意事項: 観測データのため因果ではなく関連であること、VIF>5の変数は解釈に注意が必要なこと。
出力: (1)最も影響が大きい要因トップ3とその実務的な意味 (2)有意でない変数から言えること
(3)次に試すべき抽出条件の変更案1つ。各項目2-3文、日本語、断定を避けた表現で。
```

### 8.2 PCA 深掘り解釈 (`analyzeComponentsDeep`)

既存 `_buildPrompt` を置換ではなく別メソッドとして追加:

```
あなたはコーヒーの官能評価と多変量解析の専門家です。味覚6軸(香り/酸味/苦味/甘味/複雑さ/フレーバー)の
主成分分析結果です(相関行列ベース、計算済み)。
PC1: 寄与率{c1}%, 負荷量: {loadings1}
PC2: 寄与率{c2}%, 負荷量: {loadings2}
高PC1スコアの抽出記録の特徴(上位5件の産地/焙煎度/湯温の要約): {topPc1Summary}
低PC1スコア側の同要約: {bottomPc1Summary}
出力: (1)PC1とPC2それぞれの軸の意味を一言で命名し根拠を負荷量から説明
(2)このユーザーの味覚空間の構造について言えること (3)散布図の見方のアドバイス。
日本語、各項目3文以内。負荷量の絶対値0.5未満の変数を主要根拠にしないこと。
```

topPc1Summary は Dart 側で PC1 スコア上位/下位5件の産地・焙煎度・湯温を集計した固定書式文字列 (これが「もう一歩踏み込んだ出力」の実体: 主成分と抽出条件の接続情報を Gemini に与える)。

### 8.3 好みプロファイル講評 (`narratePreference`, F5 画面の任意ボタン)

```
コーヒーの好みに関する層別統計です(計算済み)。有意判定はBonferroni補正済み。
{groupStatsTableText}
検出された傾向: {statements}
出力: この人の好みの全体像を3文で要約し、次に買うと良さそうな豆の属性を1つ、
まだデータが少なく試す価値がある属性を1つ提案。日本語。統計的に有意でない差を断定しないこと。
```

---

## 9. テスト仕様

新規テストファイルと必須ケース。数値期待値は本書の値をそのままアサーションに使う (許容誤差は各項に明記)。

### 9.1 `test/math/eigen_test.dart`

1. `[[2,1],[1,2]]` → 固有値 `[3,1]` (誤差1e-10)、固有値3のベクトルは `[1/√2, 1/√2]` (符号任意、成分絶対値誤差1e-8)。
2. `[[4,0,0],[0,2,0],[0,0,1]]` → `[4,2,1]`、固有ベクトルは単位行列の列 (順序対応)。
3. ランダム対称 6×6 (シード固定 `Random(42)`, 要素一様[-1,1]を対称化) について: (a) 全 i で `||A·vᵢ − λᵢ·vᵢ||∞ < 1e-8`、(b) 固有ベクトル同士の内積 |vᵢ·vⱼ| < 1e-8 (i≠j)、(c) Σλᵢ = trace(A) (誤差1e-8)。
4. 非対称行列入力 → ArgumentError。

### 9.2 `test/math/linear_solve_test.dart`

1. `A=[[4,2],[2,3]]`, `b=[10,8]` → cholesky L=`[[2,0],[1,√2]]`、解 x=`[1.75, 1.5]` (誤差1e-10)。
2. 非正定値 `[[1,2],[2,1]]` → StateError。
3. choleskyLogDet(`[[4,2],[2,3]]` の L) = ln(8) (誤差1e-10)。

### 9.3 `test/math/distributions_test.dart`

(参照値は R/scipy による。誤差はコメントの値まで)

1. normalCdf(0)=0.5 (1e-12), normalCdf(1.959964)=0.975 (1e-6)。
2. studentTCdf(2.0, 10)=0.963306 (1e-5), studentTCdf(-2.0, 10)=0.036694 (1e-5), studentTCdf(1.812461, 10)=0.95 (1e-5)。
3. tQuantile(0.975, 10)=2.228139 (1e-4), tQuantile(0.975, 138)=1.977304 (1e-4)。
   > **2026-07-21 訂正:** 旧版は `tQuantile(0.975, 138)=1.977431` と記載していたが、
   > `tools/verify_distributions.py`(scipy.stats.t.ppfとの突き合わせ)で検証した結果、
   > 1.977431 は df=137 の値であり df=138 用としては誤記と判明。df=138 の正しい値
   > 1.977304 に訂正した(T4-0c実施時に発見、詳細はNEXT_SESSION.md参照)。

### 9.4 `test/regression_service_test.dart`

固定 10 行データ (テスト内リテラルで定義):

```
x1 = [1,2,3,4,5,6,7,8,9,10]
x2 = [2,1,4,3,6,5,8,7,10,9]
y  = [3.1,3.9,6.2,6.8,9.1,9.9,12.2,12.8,15.1,15.9]
モデル: y ~ x1 + x2 (中心化なし・生値)
期待値: β0=1.25000, β1=1.11000, β2=0.39000 /
SE: 0.04049, 0.01880, 0.01880 / R²=0.99987, 調整済みR²=0.99983 /
σ̂=0.058554, AIC(T-9式)=n·ln(RSS/n)+2·4 = 10·ln(0.0024000)+8 = −52.3229
許容誤差: 係数・SE 1e-4, R² 1e-5, AIC 1e-3
```

> **2026-07-21 訂正:** 旧版は `β0=1.02667, β1=1.02667, β2=0.44000`(RSS=1.8109 相当)と
> 記載していたが、`tools/verify_regression.py`(numpy.linalg.lstsqとの突き合わせ、
> Node.jsのガウス消去による独立検証でも同一結果)で検証した結果、このデータの実際の
> 最小二乗解(RSS=0.0240)とは一致しない誤記と判明。上記の正しい値に訂正した
> (T4-2b実施時に発見、詳細はNEXT_SESSION.md参照)。

(実装者への注: T-9 は定数省略形のため R の AIC() の値とは異なる。上の −52.3229 が本書定義での正。) 加えて: y=2x を完全に説明するデータで R²=1・残差全0、x2=2·x1 の完全共線データで「線形従属」エラー、を確認。

### 9.5 `test/gp_service_test.dart`

1. ノイズ σ_n=1e-6 で訓練点上の予測 mean が訓練 y に一致 (誤差1e-3)、sd < 1e-2。
2. 訓練データから十分遠い点 (全次元で標準化後 +10) の sd ≈ σ_f (誤差1e-2)。
3. EI 性質: μ(x)−f*−ξ = 0.5, σ=1e-9 のとき EI ≈ 0.5 (誤差1e-6)。μ−f*−ξ = −0.5, σ=1e-9 のとき EI < 1e-6。σ=1, μ=f*+ξ のとき EI = φ(0) = 0.398942 (誤差1e-4)。

**T3-52 による改訂**: 1・2 は次元に依存しない性質なので、**テストデータ `xs` に 4 列目 (正規化粒度) を足し `predict` を 4 引数に直すだけで、期待値・許容誤差は上記のまま**使う (次元が増えると訓練点間距離が広がり K の条件数はむしろ改善するため σ_n=1e-6 でも Cholesky は安定)。4 列目に使う具体値と、新規追加する 6 件のテスト (grindSteps の解析 / keyMap 修正の型ガード回帰 / fitForMethod の行フィルタ・最小データ条件・ミル不一致の重み / optimize の粗細単調性) は **`docs/gp_multidim_design.md` §8** に定義済み。3 は無変更。

### 9.6 `test/preference_service_test.dart`

グループA: [8,9,8,9,8] (n=5, 平均8.4, 不偏sd=0.547723)、残り: [5,6,5,6,5,6,5,6,5,6] (n=10, 平均5.5, 不偏sd=0.527046) → Welch t=9.788265, ν=7.816449, p=1.17011564e-05 (<0.001)、グループ数 m=1 として significant=true。平均・CI (T-22, t_{0.975,4}=2.776445 → 8.4±0.680087) を誤差1e-4 で確認。

> **2026-07-21 訂正:** 旧版は `Welch t=10.2899, ν≈10.68`、CI `8.4±0.6796` と記載していたが、
> `tools/verify_preference.py`(scipy.stats.ttest_ind(equal_var=False)との突き合わせ)で
> 検証した結果、不偏分散(ddof=1)・母分散(ddof=0)いずれの定義でも旧値とは一致しない
> 誤記と判明。正しい値は t=9.788265, ν=7.816449, p=1.17011564e-05、CI half-width=0.680087
> (scipyの`ttest_ind`と手計算(T-23,T-24)が完全一致)。上記の値に訂正した(p<0.001・
> significant=trueという結論自体は変わらない。T4-4a実施時に発見、詳細はNEXT_SESSION.md参照)。

### 9.7 既存テストの回帰確認

F2 の相関行列化により `test/statistics_service_test.dart` の PCA 期待値が変わる場合は、テストを新仕様の値に更新する (更新理由をテスト内コメントに記載)。それ以外の既存69テストはすべてパスを維持すること。

---

## 10. 実装順序 (Phase 定義)

各 Phase の終了条件: 記載テスト全パス + `flutter analyze` 新規警告ゼロ + 既存テストパス維持。

| Phase | 内容 | 完了条件 |
|-------|------|---------|
| 0 | `lib/services/math/` 4ファイル (eigen/linear_solve/distributions/design_matrix※) 実装 | §9.1〜9.3 パス (design_matrix は Phase 2 でテスト) |
| 1 | F6: OriginMaster+移行画面+BeanMaster拡張 (originId/roastDate)+CoffeeRecord.originId+brewRatio getter+GAS (`gas/` 導入・3シート・ホワイトリスト)+DataService 拡張 | 移行の冪等性を手動確認。ユーザーが実データ移行を実行 |
| 2 | F1: RegressionService+regression_section+予測フォーム | §9.4 パス |
| 3 | F2: eigenSymmetric 差し替え+相関行列化+pca_detail_panel+Gemini 深掘り | §9.7 対応込みで全テストパス |
| 4 | F5: PreferenceService+自動更新フック+preference_section+履歴グラフ | §9.6 パス |
| 5 | F3: SuggestionService+ダッシュボードカード+提案履歴書き戻し | 手動E2E: 提案→淹れる→記録→resultRecordId 紐付け |
| 6 | F4: GpService+optimize+ヒートマップ+F3 のロジックを GP に接続 | §9.5 パス |

Phase 1 完了時点でユーザーの移行作業 (実データの名寄せ確定) が必要 (GAS 側は §3.4.2 決定事項によりユーザー作業は初回の `clasp login`・scriptId 記入のみ)。Claude Code は Phase 1 完了時に作業依頼をユーザーに明示すること。

## 11. 本設計の既知の限界 (実装対象外・将来課題)

1. ~~挽き目 (grindSize) は非構造化文字列のため v1 の全モデルから除外。~~ **T3-52 で F4 (GP) にのみ導入済み** (ミルの挽き目調整段階数で正規化して 4 次元目に追加、`docs/gp_multidim_design.md` §3)。**ただし線形正規化はミル間の物理的な粒径一致を保証しない** — 本番実測では Timemore c3 pro の記録が gNorm 0.65–0.90、Kingrinder K6 が 0.36–0.69 とほとんど重ならず、素朴に混ぜると「別ミル＝別の粗さ」と誤学習する。暫定対処としてミル不一致の記録に重み係数 0.5 を掛けている (同 §3.2)。ミル間の粒径換算表を用意する / ARD カーネルでミルごとに length scale を持たせる、といった本質的な解決は将来課題。F1 (回帰)・F5 では引き続き挽き目を使わない。
2. F5 の逐次検定 (記録のたびに検定を繰り返す) は本来 α エラーが膨らむ。Bonferroni はグループ数のみ補正しており時間方向の多重性は未補正 (学習ノートとして UI の情報ダイアログに記載する)。
3. Gemini API キーのクライアント直持ちは既存構成の踏襲であり、本設計では変更しない。
4. GP はグループごとに毎回学習し直すため、豆数×記録数が増えた場合の計算時間は将来の最適化課題 (現状 n≤300 想定では問題なし)。
5. GAS Web App 層を Google Sheets API v4 直接利用に置き換え、GAS 自体を廃止する案は §12④ で検討したが、既存 `SheetsService`・全7シートのCRUD経路・Drive経由の画像アップロードまで含む大規模なアーキテクチャ変更になり F6 のスコープを大幅に超えるため今回は不採用。GAS 運用の手間(clasp によるデプロイ管理)が将来的に問題になった場合の技術的負債として記録する。

## 12. 運用方針の追加決定事項 (2026-07-20 追記、版1.2)

ユーザー指示によるプロジェクト運用ルールの追加。本節の内容は §1.2.1 の UI配置決定と同様、実装時に必ず遵守する。

1. **画面デザインの新規検討は上位モデルで実施**: §1.2.1 の新規UI (regression_section / pca_detail_panel / preference_section / recipe_suggestion_card / gp_explorer_section) について、レイアウト・ビジュアルデザインの新規検討が必要なタスクは、より高性能なモデル (Opus 等の上位モデル) で行う。Claude Code のセッション内では `/model` で切り替える、または Agent ツールで `model: "opus"` を指定して委譲する。数値計算・ロジック層 (§4〜§7 の Service 層) の実装自体はこの限りではない。
2. **Python検証はスクリプト化してローカル実行**: 数値計算の実装 (固有値分解・回帰・GP・確率分布関数) で参照値の算出やクロスチェックに Python (numpy/scipy 等) が必要な場合、その場限りの対話的実行ではなく検証スクリプトとして `tools/verify_*.py` に保存し、ローカルで実行して結果を確認する運用とする。スクリプトはリポジトリにコミットし、§9 のテスト期待値の再現・更新に再利用できるようにする。
3. **データ基盤拡張 (F6, Phase 1) は全工程 Claude Code が担当**: §3 のモデル追加・シート追加・GAS改修・移行処理は、ユーザーの手作業を最小化し Claude Code が実装する。ユーザーが行うのは初回の `clasp login` (ブラウザOAuth) と `.clasp.json` への scriptId 記入のみ (§3.4.2②)、および Phase 1 完了条件である実データ移行の最終確定 (§3.3、突合できなかった産地の手動選択) に限定する。
4. **GAS運用方式の決定**: 当初案 (ユーザーがGASエディタで都度手動コピー・手動デプロイ) は撤回し、`clasp` CLI によるフル自動化を採用する (詳細は §3.4.2)。検討した代替案:
   - **採用: clasp CLI による自動化**: 初回 `clasp login` のみユーザー作業、以降の `clasp push`/`clasp deploy` は Claude Code が Bash から直接実行する。既存の Sheets+GAS Web App アーキテクチャ (`DataService` 抽象、既存7シートと同じ経路) をそのまま維持でき、変更範囲が F6 に閉じる。
   - **不採用: Google Sheets API v4 の直接利用 (GAS完全撤廃)**: サービスアカウント経由で GAS Web App 層自体を無くす案。ユーザーの手作業はさらに減るが、既存 `SheetsService`・全7シートのCRUD経路・画像アップロードまで含む大規模なアーキテクチャ変更になり F6 のスコープを大幅に超える。CLAUDE.md の既存方針 (「Storage backend is Google Sheets via GAS Web App」) とも矛盾するため今回は不採用 (§11⑤に技術的負債として記録)。
5. **設計書の検証値と Python 検証値が食い違う場合は Python 側を採用 (2026-07-21 追記)**: §9 のテスト期待値の実装前検証 (②の運用方針) で、numpy/scipy 等による独立検証と設計書の記載値が食い違うケースが複数回発生した (tQuantile(df=138)、回帰係数、Welch検定 T-23/T-24 など)。今後同様の食い違いを発見した場合、`AskUserQuestion` で都度ユーザー確認を取る必要はなく、Python 検証値をそのまま採用してよい。設計書側は訂正コメント付きで書き換え、発見の経緯は `NEXT_SESSION.md` に記録する (これまでの運用と同じ訂正フォーマットを維持する)。

---

## 13. 公開版の表示規則 (2026-08-20 追記、T5-B30 の確定仕様)

**位置づけ**: 本節は「公開版 (Android配布版、`lib/**/public/`) で統計解析の結果をどう見せるか」だけを定める。§0〜§12 の計算仕様・personal版UIは一切変更しない。**既存サービス (`RegressionService` / `StatisticsService` / `PreferenceService` / `SuggestionService` / `GpService`) のシグネチャ・挙動を変更してはならない**。公開版は既存サービスを呼ぶだけの**変換層を新規追加**する。

本節が正本となるのは `docs/android_monetization/デザイン方針.md` §14-1 (インサイトカードの中身の変換規則と確信度の定義)。表示層 (色・形・配置) は引き続き同書が正本。

### 13.0 §0-5 との整合 (絶対規則を破らないための4条)

§0-5 「点推定と不確実性を必ずセットで表示。点推定のみの表示UIを作らない」は公開版でも維持する。表現を数値からビジュアル・平易な日本語へ変えるだけで、不確実性の情報自体を落とさない。

1. **点推定を数値で出すカードは、必ず同じ単位の幅を同じ文の中に併記する** (例「およそ8.2点(7.6〜8.8点)」)。幅の出所は §2.5 の区間 (平均のCI / 予測区間 / 係数のCI) で、単位を「点」「℃」等のユーザー単位へ換算したもの。
2. **幅を持たない実測値** (前回の記録との差、過去最高スコアの条件) は推定量ではないので区間を付けない。その代わり確信度を必ず `low` にし、根拠文に「たまたまの可能性があります」の趣旨を含める (13.3 のテンプレートで固定)。
3. **確信度3段階は不確実性の要約表示であり、幅の代替ではない**。1 に該当するカードは幅と確信度の両方を出す。
4. **生の統計量は文言・UIに出さない** (13.1 の禁止語リスト、受入テストで機械チェック)。

### 13.1 表示してよい数値 / 禁止語

| 区分 | 内容 |
|---|---|
| 表示してよい | 総合評価・味覚6軸のスコア (0〜10、小数第1位)、湯温 (℃、整数)、豆量/湯量 (g、整数)、抽出時間 (「◯分◯秒」)、比率 (「1:15.0」)、件数 (整数)、日付 |
| 表示禁止 (語もろとも) | `p値` `有意` `寄与率` `固有値` `負荷量` `決定係数` `R2` `R²` `AIC` `VIF` `t値` `標準誤差` `標準偏差` `回帰係数` `係数` `主成分` `PC1` `PC2` `信頼区間` `予測区間` `自由度` `Bonferroni` `検定` `分散` `相関係数` |

- 幅の表示は「(7.6〜8.8点)」の形にする。**「95%」「信頼区間」等の語は付けない**。
- 受入テスト (`test/acceptance/t5_b31_acceptance_test.dart`) で (a) 生成された全 `InsightCard` の文字列フィールド (b) `lib/screens/public/` `lib/widgets/public/` のソース中の文字列リテラル、の両方に対して上表の禁止語が1件も出現しないことを検証する。

### 13.2 データモデル (新規、T5-B31)

新規ファイル `lib/models/public/insight_card.dart`。**永続化しないので `json_serializable` を使わない** (= `build_runner` 実行は不要)。

```dart
enum InsightKind {
  recipeSuggestion,   // C3 おすすめレシピ (GP)
  conditionEffect,    // C1 条件の効き方 (重回帰)
  tastePreference,    // C2 好みの組み合わせ (層別統計)
  recentChange,       // C5b 最近の伸び (2標本比較)
  tasteAxis,          // C4 味の傾向 (PCA)
  consistency,        // C6 淹れ方の安定度
  lastBrewCompare,    // C5a 前回との比較 (T5-B32)
}

enum InsightConfidence { high, medium, low }

enum InsightActionType { brewPrefill, beanPicker, historyFilter, insightDetail, none }
// brewPrefill → P200 (抽出の準備) を args の値でプリフィル
// beanPicker → P200 の豆選択シートを開く
// historyFilter → P240 (履歴) を args の条件で開く (args 空なら無条件)
// insightDetail → P310 (インサイトの詳細) を、そのカードの detail で開く
// none → タップ不可 (次の一手を文としてだけ見せる)

class InsightAction {
  final String label;                 // 「次の一手」の文言 (24文字以内)
  final InsightActionType type;
  final Map<String, String> args;     // 13.6 のキー表に列挙したキーのみ
}

class InsightRecipe {               // C3 のみ非null。条件行の表示に使う
  final String? methodName;
  final String? beanName;
  final int temperatureC;
  final double brewRatio;           // 15.0 → 「1:15.0」
  final int totalTimeSec;
}

enum InsightDetailKind { estimate, trend, scatter }

class InsightSeriesPoint {
  final String label;
  final double value;
  final double? lower;              // 帯 (chartBand) を描くとき非null
  final double? upper;
}

class InsightDetail {               // P310 用。null 可 (詳細画面を持たないカード)
  final InsightDetailKind kind;
  final String caption;             // 図の説明1文
  final double? point;              // kind==estimate のとき必須
  final double? lower;              // kind==estimate のとき必須
  final double? upper;              // kind==estimate のとき必須
  final String? unitLabel;          // kind==estimate のとき必須 ('点' 等)
  final List<InsightSeriesPoint> series; // kind==trend/scatter のとき非空
}

class InsightCard {
  final String id;                  // 13.5 の安定ID規則
  final InsightKind kind;
  final String headline;            // 所見1文 (40文字以内、句点で終わる)
  final String evidence;            // 根拠1文 (80文字以内、句点で終わる)
  final InsightAction action;       // 次の一手
  final InsightConfidence confidence;
  final String confidenceNote;      // 13.4 の固定文 (P310 最下部で使う)
  final InsightRecipe? recipe;
  final InsightDetail? detail;
  final int priority;               // 昇順ソート (13.5)
}

class UnlockProgress {              // T5-B32
  final String featureLabel;        // 13.7 の解禁ラベル
  final int current;
  final int required;
  int get remaining => (required - current).clamp(0, required);
  double get ratio => required == 0 ? 1.0 : (current / required).clamp(0.0, 1.0);
}

class InsightFeed {
  final List<InsightCard> cards;    // priority 昇順、最大6枚
  final UnlockProgress? progress;   // 全解禁済みなら null
  final int validRecordCount;       // 13.2.1 の有効件数
  final DateTime generatedAt;
}
```

#### 13.2.1 有効件数の定義 (全閾値の分母)

```dart
bool isScored(CoffeeRecord r) => r.scoreOverall >= 1 && r.scoreOverall <= 10;
```

- 公開版 P220 は総合評価の**初期値を入れない** (`デザイン方針.md` §9.4)。**未入力は `scoreOverall = 0` で保存する** — T5-B24 の実装はこの取り決めに従うこと。`0` は欠測であり、インサイトの集計から必ず除外する。
- `validRecords = records.where(isScored).toList()..sort((a,b) => b.brewedAt.compareTo(a.brewedAt))` (新しい順)。本節で「n件」と書いたら常に `validRecords.length` を指す。
- 比率が必要な処理では `r.beanWeight > 0` も条件に加える (`brewRatio = r.totalWater / r.beanWeight`)。

### 13.3 変換規則 (統計サービス出力 → カード)

共通の丸め規則:

| 対象 | 規則 |
|---|---|
| スコア・スコア差 | `(x*10).round()/10` を小数第1位固定で表示 (`8.0` も「8.0」)。0〜10 にクランプ (差分はクランプしない) |
| 湯温 | `round()`、「92℃」 |
| 比率 | 小数第1位、「1:15.0」 |
| 時間 | 5秒単位に丸め、`s%60==0` なら「{m}分」、それ以外は「{m}分{s}秒」 |
| 幅 | 下端・上端とも同じ丸め。スコアの幅は 0.0〜10.0 にクランプ |

名前解決の共通規則: `beanName` は `beans` から `beanId` で引き、引けない・空文字なら「この豆」と表記する。`methodName` は `methods` から引き、引けなければ文からその要素ごと落とす。`originLevel`/`roastLabel` は `PreferenceService` が返した値をそのまま使う。

各カードは個別に `try/catch` で囲み、失敗したカードだけスキップして `debugPrint('[Antigravity] インサイト生成に失敗: <kind> <error>')` を出す。フィード全体は落とさない。

#### C1 conditionEffect — 重回帰 (`RegressionService.fit`)

- **入力**: `fit(validRecords, originById)`。`null` (n<30 または n<5p) ならカード無し。
- **対象係数**: `RegressionResult.coefficients` のうち下表の4つだけ。`切片` / `産地:*` / `焙煎順序×湯温(交互作用)` は**公開版では扱わない** (産地は C2 が担当、交互作用は平易に言い換えられないため)。

| `coefficient.name` | 表示名 | step | β>0 の所見動詞 | β<0 の所見動詞 | action |
|---|---|---|---|---|---|
| `湯温(中心化)` | 湯温 | 3.0 (℃) | 「湯温を少し高くする」 | 「湯温を少し低くする」 | `brewPrefill` (温度を ±3℃) |
| `brewRatio(中心化)` | 湯量の比率 | 1.0 | 「湯を少し多くする」 | 「湯を少し少なくする」 | `brewPrefill` (比率を ±1.0) |
| `総抽出時間分(中心化)` | 抽出時間 | 0.5 (分=30秒) | 「抽出時間を少し長くする」 | 「抽出時間を少し短くする」 | `brewPrefill` (時間を ±30秒) |
| `焙煎順序(中心化)` | 焙煎度 | 1.0 (段階) | 「深めの焙煎を選ぶ」 | 「浅めの焙煎を選ぶ」 | `beanPicker` |

- **採用条件**: `pValue < 0.05` かつ `delta >= 0.15`。ここで `delta = |beta| * step`。満たすものを `delta` 降順に**最大2枚**。
- **幅**: `tCrit = tQuantile(0.975, (n - p - 1).toDouble())` (`lib/services/math/distributions.dart`)、`lo = (|beta| - tCrit*se) * step`、`hi = (|beta| + tCrit*se) * step`。`lo < 0` になった場合は `0.0` にクランプ。
- **文言**:
  - headline: `{動詞}と、総合評価が上がる傾向です。` (β の符号で動詞を選ぶので、常に「上がる」側で書く)
  - evidence: `{表示名}を{stepText}変えると、評価がおよそ{delta}点({lo}〜{hi}点)動きます({n}件の記録から)。`
    - `stepText`: 湯温「3℃」/ 比率「1つぶん(例: 1:15 → 1:16)」/ 時間「30秒」/ 焙煎度「1段階」
  - action.label: 温度/比率/時間は「この条件で淹れる」、焙煎度は β>0「深めの豆を選ぶ」/ β<0「浅めの豆を選ぶ」
- **confidence**: 13.4 の表を参照。
- **detail**: `kind: estimate`, `point = delta`, `lower = lo`, `upper = hi`, `unitLabel = '点'`, `caption = '{表示名}を{stepText}変えたときの、評価の動き方の見込みです。'`

#### C2 tastePreference — 層別統計 (`PreferenceService.build`)

- **入力**: `build(validRecords, originById)` → `PreferenceProfile.groups`。**`PreferenceProfile.statements` は使わない** (personal版向けに p 値を含むため)。
- **対象グループの選び方** (上から順に、最初に見つかった1件):
  1. `significant == true` のうち `|mean - overallMean|` 最大
  2. `welchP != null && welchP! < 0.05` のうち同上
  3. `n >= 3` かつ `|mean - overallMean| >= 1.0` のうち同上
  - `overallMean` = `validRecords` の `scoreOverall` 平均 (Dartローカルで計算)。
  - 3つとも該当が無ければカード無し。**総件数 n < 12 のときはカードを出さない** (13.7 の解禁条件と一致させる)。
- **文言** (`diff = mean - overallMean`):
  - `diff > 0`: headline `{originLevel}の{roastLabel}が、好みに合っています。`
  - `diff < 0`: headline `{originLevel}の{roastLabel}は、好みから外れがちです。`
  - evidence: `この組み合わせの平均はおよそ{mean}点({ciLower}〜{ciUpper}点)、全体の平均は{overallMean}点です({n}件)。`
  - action.label: `diff > 0` は「この組み合わせで淹れる」(`brewPrefill`、`args: {'originLevel':…, 'roastLabel':…}`)、`diff < 0` は「別の組み合わせを試す」(`beanPicker`、args 空)
  - 該当する豆が在庫に無い場合の遷移先フォールバックは `beanPicker` (P200 の豆選択シート)。
- **detail**: `kind: estimate`, `point = mean`, `lower = ciLower`, `upper = ciUpper`, `unitLabel = '点'`, `caption = 'この組み合わせで淹れたときの、平均的な評価の範囲です。'`

#### C3 recipeSuggestion — GP 推薦 (`SuggestionService.suggestWithGp`)

- **対象豆**: (1) `calculateBeanRemainingPercent(bean, records)` (`lib/utils/bean_stock_calculator.dart`。**消費量の計算には有効記録ではなく `records` 全件を渡す**) が 0% 超を返す豆のうち、直近の記録が最も新しいもの。(2) 該当が無ければ「直近30日に記録がある豆」で記録数最多。(3) それも無ければカード無し。
- **入力**: `suggestWithGp(bean, validRecords, originById, methods, grindStepsByGrinderId, explore: SuggestionService.shouldExplore(history))`。`history` は `recipeSuggestionsProvider` の値。`null` ならカード無し。
- **recipe**: `SuggestionResult.suggestion` の条件をそのまま詰める。`methodName` は `methods` から `suggestion.methodId` で引く。`beanName` は `beans` から `suggestion.beanId` で引く。引けなければ `null` にして表示を省く。`temperatureC = suggestion.temperature.round()`、`brewRatio = suggestion.brewRatio`、`totalTimeSec = suggestion.totalTimeSec`。
- **予測値**: `SuggestionResult.predMean` / `predLower` / `predUpper` (§2.5 の予測区間、`group_best` では null) をそのまま使う。GPを再実行しない。
- **文言** (`rationale` で分岐):

| rationale | headline | evidence |
|---|---|---|
| `gp_mean` | `{beanName}は、この条件が良さそうです。` | `これまでの記録からの見込みはおよそ{predMean}点({predLower}〜{predUpper}点)です。` |
| `gp_ei` | `{beanName}で、まだ試していない条件を試す価値がありそうです。` | `ふだんと少し違う条件です。見込みはおよそ{predMean}点({predLower}〜{predUpper}点)と幅があります。` |
| `group_best` | `{beanName}は、この条件がこれまでで一番でした。` | `過去に実際に淹れたときの条件です。まだ見込みを出せるほど記録が集まっていません。` |

- `beanName` を解決できない場合は「この豆」と表記する。
- action.label: `gp_mean`/`gp_ei` は「この条件で淹れる」、`group_best` は「もう一度この条件で淹れる」。いずれも `brewPrefill` で 13.6 のキーを全部埋める。
- **detail**: GP経路のみ `kind: estimate` (`point=predMean`, `lower=predLower`, `upper=predUpper`, `unitLabel='点'`, caption `'この条件で淹れたときに出そうな評価の範囲です。'`)。`group_best` は `detail = null`。

#### C4 tasteAxis — PCA (`StatisticsService.calculatePca`)

- **入力**: `calculatePca(validRecords)`。`components.isEmpty` ならカード無し。
- **前提条件**: `n >= 10` かつ `components[0].contributionRatio >= 0.30` かつ `components[0].contributions` に `|L| >= 0.5` の軸が2つ以上。満たさなければカード無し。
- **軸名の日本語化**: `{'Fragrance':'香り','Acidity':'酸味','Bitterness':'苦味','Sweetness':'甘み','Complexity':'複雑さ','Flavor':'風味'}`。
- **文言**: PC1 の負荷量から、正側最大の軸 `posAxis` と負側最小の軸 `negAxis` を取る。
  - `|L(negAxis)| >= 0.5` を満たす負側の軸がある (= 対立軸型):
    - headline: `あなたの記録は「{posAxis}が立つ杯」と「{negAxis}が立つ杯」に分かれます。`
    - evidence: `{posAxis}が強い記録では、{negAxis}が控えめになりがちです({n}件の記録から)。`
  - 全ての軸が同符号 (= 総合的な強さ型): `|L|` 上位2軸を `a`,`b` として
    - headline: `あなたの記録は「{a}と{b}がそろって出る杯」が中心です。`
    - evidence: `{a}が高い記録は、{b}も高くなりがちです({n}件の記録から)。`
- action.label: 「どの記録がどちら寄りか見る」(`insightDetail`、`args: {}` — P310 の散布図へ)。
- **detail**: `kind: scatter`。散布図は x/y の2値が要るため、`series` の各要素を `InsightSeriesPoint(label: p.label, value: p.x, lower: p.y, upper: null)` と**定義する** (`value` = x、`lower` = y)。この用法は `kind == scatter` のときのみ許可し、`InsightDetail` の doc コメントに明記すること。要素は `PcaResult.points` を最大60件 (新しい順)。caption `'近い位置にある記録どうしは、味の傾向が似ています。'`

#### C5b recentChange — 直近5件 vs その前5件

- **前提**: `n >= 8`。`k = min(5, n ~/ 2)`。`recent = validRecords.take(k)`、`prev = validRecords.skip(k).take(k)`。
- **計算**: 新規 `lib/services/math/two_sample.dart` に Welch 検定 (T-23/T-24) を追加する。

```dart
({double t, double df, double p})? welchTest(List<double> a, List<double> b);  // 各2件未満なら null
```

  - `PreferenceService` 内の同等ロジックは**今回は共通化しない** (personal版の挙動を変えないため)。重複は 13.9 に既知課題として記録。
  - `recent` の平均CI は (T-22) `mean ± tQuantile(0.975, k-1) * sd / sqrt(k)`。
- **文言** (`diff = meanRecent - meanPrev`):
  - `|diff| < 0.3`: headline `最近の評価は落ち着いています。` / evidence `最近{k}杯の平均はおよそ{meanRecent}点({lo}〜{hi}点)、その前の{k}杯は{meanPrev}点です。`
  - `diff >= 0.3`: headline `最近{k}杯は、その前より{diff}点ほど高い評価です。`
  - `diff <= -0.3`: headline `最近{k}杯は、その前より{|diff|}点ほど低い評価です。`
  - evidence は3ケース共通 (上記)。
- action.label: `diff >= 0.3` 「この調子で淹れる」、それ以外は「直近の記録を見返す」(`historyFilter`)。
- **detail**: `kind: trend`, `series` は `validRecords` を古い順に最大20件、`InsightSeriesPoint(label: 'M/d', value: scoreOverall.toDouble())`。caption `'1杯ごとの総合評価の推移です。'`

#### C6 consistency — 安定度

- **対象**: `validRecords` を `beanId` で集計し、件数最多の豆 (同数なら直近の記録が新しい方)。件数 `nb >= 4` が必要。
- **計算**: その豆のスコアの標本標準偏差 `sd` (n-1)、最小 `min`、最大 `max`。
- **文言**:
  - `sd >= 1.2`: headline `{beanName}は、淹れるたびに評価が変わりやすいです。` / action.label 「条件を1つだけ変えて淹れる」(`brewPrefill`、直近の条件をそのまま)
  - `sd < 0.8 && nb >= 6`: headline `{beanName}は、安定して淹れられています。` / action.label 「この条件で淹れる」
  - それ以外 (0.8 ≤ sd < 1.2、または sd<0.8 かつ nb<6): カード無し
  - evidence 共通: `これまでの評価は{min}〜{max}点の間で動いています({nb}件)。`
- **detail**: `kind: trend` (その豆のスコア推移、最大20件)。caption `'この豆の評価の動きです。'`

#### C5a lastBrewCompare — 前回との比較 (T5-B32)

- **前提**: `n >= 2`。`a = validRecords[0]`、`b = validRecords[1]`。
- **文言** (`d = a.scoreOverall - b.scoreOverall`):
  - `d > 0`: headline `前回より{d}点高い評価でした。`
  - `d < 0`: headline `前回より{|d|}点低い評価でした。`
  - `d == 0`: headline `前回と同じ評価でした。`
  - evidence: `直近は{beanName}を{temp}℃・1:{ratio}・{timeText}で淹れた回です。`
    - 解決できない要素 (豆名・比率) は文から落とす。全部落ちる場合は `直近の記録との比較です。`
- action.label: 「同じ条件でもう一度淹れる」(`brewPrefill`、直近記録の条件)。
- **confidence**: 常に `low` (13.0-2)。confidenceNote は 13.4 の `low` の固定文をそのまま使う。
- **detail**: `null`。

### 13.4 確信度3段階

| 値 | ラベル (UI文言) | 点の表示 | confidenceNote (P310 「この見立てはどれくらい確かか」) |
|---|---|---|---|
| `high` | 確かな傾向 | ●●● | `同じ傾向がくり返し出ています。記録が増えても大きくは変わらない見込みです。` |
| `medium` | 見えてきた傾向 | ●●○ | `そう見えていますが、記録が増えると変わることがあります。` |
| `low` | まだ弱い傾向 | ●○○ | `まだ記録が少なく、たまたまの可能性があります。` |

表示 (`lib/widgets/public/bb_confidence_dots.dart`、D8 準拠):

- 直径 8 の点を3つ横並び (間隔 3)。点灯は `BbColors.chartCurrent` の塗り、未点灯は塗り無し + `colorScheme.outlineVariant` 1px の輪郭。**点灯個数 (形) とラベルの二重符号化**なので、色だけに依存しない。
- 右にラベルを `labelSmall` で必ず併記。`Semantics(label: '確信度: {ラベル}')`。
- 新しいカラートークンは追加しない (`デザイン方針.md` §3.2 の既存トークンのみ使用)。

判定基準 (カード種別ごと。上から評価し最初に当たった段階を採る):

| kind | high | medium | low |
|---|---|---|---|
| `conditionEffect` (C1) | `p < 0.05/m` かつ `n >= 50` かつ `vif < 5` (`m` = 判定対象4係数のうち実在する数) | `p < 0.05` かつ `n >= 30` かつ `vif < 5` | 上記以外 (`vif >= 5`、または `defaultScoreCount > n*0.3`) |
| `tastePreference` (C2) | `significant == true` かつ `n_group >= 8` | `significant == true`、または (`welchP < 0.05` かつ `n_group >= 8`) | それ以外 (選定条件3で拾ったケース) |
| `recipeSuggestion` (C3) | `rationale != 'group_best'` かつ 区間幅 `predUpper - predLower <= 2.0` かつ `explore == false` | `rationale != 'group_best'` かつ 幅 `<= 3.0` | `group_best`、または幅 `> 3.0`、または `gp_ei` |
| `tasteAxis` (C4) | `n >= 40` かつ `contributionRatio >= 0.45` かつ `|L| >= 0.6` の軸が2つ以上 | `n >= 20` かつ `contributionRatio >= 0.35` | それ以外 |
| `recentChange` (C5b) | **`high` にしない** | 各群 `k >= 5` かつ `welchTest.p < 0.05` | それ以外 |
| `consistency` (C6) | `nb >= 10` | `nb >= 6` | `nb >= 4` |
| `lastBrewCompare` (C5a) | — | — | 常に `low` |

- `defaultScoreCount` は personal版データ由来の指標 (`scoreOverall == 7` の件数)。公開版は初期値を入れないため通常0だが、移行データを読み込んだ場合に効く。

### 13.5 並び順・表示枚数・ID

- `priority` = 基礎値 + (`confidence == low` なら +25、`medium` なら +10、`high` なら 0)。

| kind | 基礎値 |
|---|---|
| `recipeSuggestion` | 10 |
| `conditionEffect` | 20 |
| `tastePreference` | 30 |
| `recentChange` | 40 |
| `tasteAxis` | 50 |
| `consistency` | 60 |
| `lastBrewCompare` | 70 |

- `cards` は `priority` 昇順。同値なら上表の順。**最大6枚**で切る。`conditionEffect` のみ最大2枚、他の kind は各1枚。
- `id` は再ビルドしても同じカードなら同じ値になるよう次で作る (アニメーションの `Key` と「既読」判定に使う): `'{kind.name}:{識別子}'`。識別子は C1 = 係数名、C2 = `'{originLevel}|{roastLabel}'`、C3 = `beanId`、C4 = `'pc1'`、C5b = `'recent{k}'`、C6 = `beanId`、C5a = `validRecords[0].id`。
- ホーム (P100) の「インサイトの要約カード1枚」は `cards.isEmpty ? null : cards.first` を表示する。

### 13.6 `InsightAction.args` のキー (実装はこの表のキーのみ使う)

| キー | 型 (String化) | 使うカード | 例 |
|---|---|---|---|
| `beanId` | 豆マスタID | C3, C6, C5a | `'b_12'` |
| `originLevel` | 産地の水準名 | C2 | `'エチオピア'` |
| `roastLabel` | 焙煎度ラベル | C2 | `'ミディアム'` |
| `methodId` | メソッドID | C3, C5a | `'m_3'` |
| `temperature` | ℃ (整数文字列) | C1, C3, C6, C5a | `'92'` |
| `brewRatio` | 小数1桁 | C1, C3, C6, C5a | `'15.0'` |
| `totalTimeSec` | 秒 (整数文字列) | C1, C3, C6, C5a | `'150'` |
| `grinderId` | グラインダーID | C5a, C6 | `'g_2'` |
| `grindSize` | 挽き目 (元の文字列) | C5a, C6 | `'12'` |

- **C3 は `grinderId`/`grindSize` を埋めない**。`RecipeSuggestion` (`lib/models/recipe_suggestion.dart`) が持つのは `beanId`/`originId`/`roastLevel`/`methodId`/`temperature`/`brewRatio`/`totalTimeSec` だけで、GP が内部で使う `targetGrinderId`・粒度は返ってこないため。埋めるキーは `beanId`/`methodId`/`temperature`/`brewRatio`/`totalTimeSec` の5つ。**この理由で既存サービスに戻り値を追加する改修はしない** (13.9-5)。

- `brewPrefill` は P200 (抽出の準備) へ遷移し、上記の値を初期値に入れる。埋められないキーは省略し、画面側は既定値のままにする。
- **クランプ**: C1 が条件をずらす場合、`temperature` は 80〜96、`brewRatio` は 10.0〜20.0、`totalTimeSec` は 60〜300 に収める。範囲外に出る場合はその端の値にする。
- `beanPicker` は P200 の豆選択シートを開く。`historyFilter` は P240 (履歴) を `args` の条件で開く。`args` が空なら無条件。

### 13.7 データ不足の閾値と進捗表示 (T5-B32)

新規 `lib/services/public/insight_thresholds.dart` に下表を定数として置く。

| 順 | `featureLabel` | 必要件数 | 数える対象 | 対応するカード / 手法 |
|---|---|---|---|---|
| 1 | 前回との比較 | 2 | 有効件数 `n` | C5a (統計手法なし) |
| 2 | 最近の伸び | 8 | 有効件数 `n` | C5b (Welch 2標本、各4件) |
| 3 | 味の傾向 | 10 | 有効件数 `n` | C4 (PCA。§1.3 の F2 最小3件より厳しくする — 6軸の相関を語るには3件では足りないため) |
| 4 | 好みの組み合わせ | 12 | 有効件数 `n` | C2 (§1.3 の F5「グループ n≥3」に加え、全体12件を条件に足す) |
| 5 | おすすめレシピ | 8 | **最も記録が多いメソッドでの**有効件数 | C3 (§1.3 の F4 = `nRows >= 8` かつ `n_eff >= 6.0`。`n_eff` は実際のフィットで判定するため進捗表示は `nRows` を使う) |
| 6 | 条件の効き方 | 30 | 有効件数 `n` | C1 (§1.3 の F1 = `n >= 30` かつ `n >= 5p`。`5p` 条件は実際のフィットで判定) |

```dart
UnlockProgress? nextUnlock(List<CoffeeRecord> validRecords);
```

- 上表を順に見て、`current < required` の**最初のステップ**を返す。全て満たしていれば `null`。
- 順1〜4,6 の `current` は `validRecords.length`、順5 は `methodId` ごとの件数の最大値。
- 「必要件数を満たす」ことと「カードが出る」ことは別 (有意な傾向が無ければカードは出ない)。進捗カードの文言は「使えます / 見られます」に留め、「◯件でわかります」とは書かない。

表示規則 (`lib/widgets/public/bb_unlock_progress_card.dart`)、4状態:

| 状態 | 条件 | 表示 |
|---|---|---|
| 0件 | `validRecordCount == 0` | 進捗カードを出さず `BbEmptyState`。見出し「まだ記録がありません」/ 説明「1杯淹れると、味の傾向が見えはじめます。」/ ボタン「はじめての抽出を記録する」(`デザイン方針.md` §10) |
| 数件 (カード0枚) | `cards.isEmpty && progress != null` | 画面**最上部**に進捗カード。見出し「あと{remaining}件でインサイトが使えます」/ 説明「{featureLabel}を出すには記録が{required}件必要です。いまは{current}件です。」+ 進捗バー |
| 閾値直前 (カード1枚以上) | `cards.isNotEmpty && progress != null` | カード一覧の**最下部**に小さい進捗カード。見出し「あと{remaining}件で「{featureLabel}」が見られます」/ 説明は同上 + 進捗バー |
| 閾値超え | `progress == null` | 進捗カードを出さない |

- 説明文の書式は `デザイン方針.md` §10「インサイト データ不足」(「味の傾向を出すには記録が◯件必要です。いまは◯件です。」) を一般化したもの。`featureLabel == '味の傾向'` のとき §10 と一字一句一致する。
- 進捗バーは `LinearProgressIndicator(value: progress.ratio)`。`Semantics(label: '{featureLabel}まで あと{remaining}件')`。
- 無料版の広告枠は P300 には出さない (`デザイン方針.md` §11: 一覧系は P240 / P5x0 のみ)。

### 13.8 サービス層と Provider (T5-B31)

- 新規 `lib/services/public/insight_service.dart`

```dart
class InsightService {
  InsightFeed build({
    required List<CoffeeRecord> records,
    required Map<String, OriginMaster> originById,
    required List<BeanMaster> beans,
    required List<MethodMaster> methods,
    required Map<String, int> grindStepsByGrinderId,
    required List<RecipeSuggestion> suggestionHistory,
    DateTime? now,                                   // 未指定なら DateTime.now()。テストのため必須引数化しない
  });
}
final insightServiceProvider = Provider((ref) => InsightService());
```

- 新規 `lib/providers/public/insight_providers.dart`

```dart
final insightFeedProvider = FutureProvider<InsightFeed>((ref) async { /* 上記の依存を watch して build() */ });
```

- `build()` は純粋関数 (I/O なし・`DateTime.now()` は `now` 経由のみ)。同じ入力なら同じ出力になること (テスト要件)。
- ログ: `debugPrint('[Antigravity] インサイト生成: {カード枚数}枚 / 有効{n}件 / 次の解禁={featureLabel}')` を `build()` 末尾で1回。
- 目安性能: 有効300件で 300ms 以内。GP は対象豆1件分のみ実行する。
- **Gemini は使わない**。公開版のカード文言は 100% Dart の固定テンプレート (無料版でAPIコストを出さない・オフラインでも出るため)。§8.1〜8.3 のプロンプトは personal 版と将来の Pro 機能専用で、T5-B31/B32 は §8 に手を入れない。P300 最下部の AI 訴求カードは `デザイン方針.md` §11 の Pro導線 (T5-B48) が担当。

### 13.9 既知の限界 (実装対象外)

1. `welchTest` を新設する一方で `PreferenceService` 内の同等ロジックは残るため、Welch 検定の実装が2箇所になる。personal版の挙動を変えないための意図的な重複。将来 `PreferenceService` を `two_sample.dart` に寄せる。
2. C1 は交互作用項と産地ダミーを公開版に出さないため、「深煎りのときだけ湯温が効く」といった条件付きの傾向は表現できない。
3. C3 は在庫豆1件だけを対象にする。複数豆の比較は将来課題。
4. `scoreOverall == 0` を欠測とする取り決めは、personal版から移行したデータ (初期値7) には効かない。移行データの偏りは `defaultScoreCount` 経由で C1 の確信度にだけ反映される。
5. C3 の「この条件で淹れる」はグラインダーと挽き目をプリフィルできない (`RecipeSuggestion` が返さないため)。既存サービスの戻り値を増やす改修は公開版のために行わない方針なので、挽き目は P200 の既定値のままユーザーが決める。

### 13.10 テスト仕様 (受入)

`test/acceptance/t5_b31_acceptance_test.dart`:

1. **禁止語**: 3種類の入力 (12件 / 40件 / 120件の合成記録) で `build()` した全カードの `headline`/`evidence`/`action.label`/`confidenceNote`/`detail.caption` に 13.1 の禁止語が出現しない。
2. **§0 準拠**: `detail.kind == estimate` のカードは `point`/`lower`/`upper`/`unitLabel` が全て非null、かつ `lower <= point <= upper`。さらに `evidence` に `〜` を含む幅の表記があること (C3 の `group_best`・C5a を除く)。
3. **幅なしカードの確信度**: `group_best` の C3 と C5a は `confidence == InsightConfidence.low`。
4. **枚数・順序**: `cards.length <= 6`、`conditionEffect` は最大2枚、他 kind は各1枚以下、`priority` 昇順。
5. **確信度判定**: C1 で `n=60, p=0.001, vif=2` 相当の合成データ → `high`、`n=35, p=0.03` → `medium`、`vif=8` → `low`。
6. **決定性**: 同じ入力で2回 `build()` した結果の `id`/`headline` 列が一致する。
7. **欠測除外**: `scoreOverall == 0` の記録を10件混ぜても `validRecordCount` が増えず、カード内容が変わらない。

`test/acceptance/t5_b32_acceptance_test.dart`:

1. **4状態**: 有効0件 → `cards.isEmpty && validRecordCount == 0` (UIは `BbEmptyState`)。3件 → `progress!.featureLabel == '最近の伸び'`, `remaining == 5`。11件 → `featureLabel == '好みの組み合わせ'`, `remaining == 1`。全閾値超え (メソッド偏り無しの40件) → `progress == null`。
2. **文言**: 進捗カードの説明文が `'{featureLabel}を出すには記録が{required}件必要です。いまは{current}件です。'` と完全一致。`featureLabel == '味の傾向'` のケースで `デザイン方針.md` §10 の文言と一致。
3. **C5a**: 有効2件で `lastBrewCompare` カードが1枚出る。1件では出ない。
4. **境界**: `remaining` が負にならない (`clamp`)、`ratio` が 0.0〜1.0。
