# CLAUDE.md 追記用: 統計解析機能

(このセクションを既存 CLAUDE.md の末尾に貼り付ける)

## 統計解析・予測機能の実装ルール

正本は `statistics_feature_design.md`。本節と食い違う場合は設計書が優先。

### 絶対規則

- 数値計算 (回帰・PCA・GP・EI・検定) は Dart ローカル実装。Gemini に計算させない。Gemini は計算済み数値の日本語解釈のみ (プロンプトは設計書 §8 のテンプレート固定)。
- 設計書に無いフィールド名・シート名・クラス名を発明しない。不明点は実装を止めてユーザーに質問。
- Phase 順 (設計書 §10) を厳守: 0 数値基盤 → 1 データ基盤(F6) → 2 回帰(F1) → 3 PCA拡張(F2) → 4 好み(F5) → 5 提案(F3) → 6 GP(F4)。各 Phase はテスト全パスまで次に進まない。
- 統計量は必ず点推定+不確実性 (SE/CI/予測区間) をセット表示。

### 構成マップ

- 数値基盤: `lib/services/math/` — eigen.dart (Jacobi 書き直し版 `eigenSymmetric`、旧 `_jacobiEigenvalueAlgorithm` は削除), linear_solve.dart (Cholesky), distributions.dart (erf/t分布CDF/分位点), design_matrix.dart
- サービス: regression_service.dart / preference_service.dart / suggestion_service.dart / gp_service.dart / migration_service.dart。statistics_service.dart は PCA を相関行列ベースに改修
- モデル追加: origin_master.dart / analysis_snapshot.dart / recipe_suggestion.dart。BeanMaster に originId・roastDate、CoffeeRecord に originId と `brewRatio` getter (保存しない)
- シート追加: origin_master / analysis_history / recipe_suggestions。GAS は `gas/Code.gs` としてリポジトリ管理 (clasp)、シート名ホワイトリスト `ALLOWED_SHEETS` 必須
- UI: 統計画面に regression_section / pca_detail_panel / preference_section / gp_explorer_section を追加。F3 のみダッシュボード (recipe_suggestion_card)

### データ規則

- 産地は OriginMaster (選択式) が正。自由入力 origin は後方互換のため残すが新規参照は originId 経由
- 焙煎度は `roastOrdinalMap` (encoding.dart) で順序値 1–5 に変換。未知値は欠測として行除外+件数表示
- F5 プロファイルは抽出記録の保存成功のたび自動再計算し analysis_history に保存 (失敗しても記録保存は妨げない)
- 最小データ条件 (設計書 §1.3) を下回るときは計算せず固定文言の案内を表示

### テスト

- 数値テストの期待値・許容誤差は設計書 §9 の値をそのまま使う (例: eigen `[[2,1],[1,2]]`→{3,1}、回帰10行データの β/SE/R²、t分位点)
- 既存69テストのパス維持。PCA 相関行列化で期待値が変わる場合のみ理由コメント付きで更新可
