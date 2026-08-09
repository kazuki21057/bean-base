# AGENTS.md — BeanBase 2.0

- 回答・コメント・UI文言・ログ本文はすべて**日本語**で書く(例外: コード上の識別子、ライブラリ/API等の固有名詞、`[Antigravity]`プレフィックス)。
- スタックはFlutter Web + Riverpod。永続化はGoogle Sheets(GAS Web App経由、`lib/services/sheets_service.dart`)。
- Firestore関連(`firestore_service.dart`・`firestore_migrator.dart`・`firebase_options.dart`)は**レガシーで未使用**。指示が無い限り触らない。
- 外部から来る数値ID(Sheetsはint/doubleを返す)は`fromJson`で必ず`.toString()`する。空IDはガードする。
- 主要アクション・外部呼び出しは`debugPrint('[Antigravity] ...')`でログする。外部呼び出しはtry/catchで包み、エラーも同形式でログする。
- マスター系の変更は**5マスタすべて**(豆・グラインダー・ドリッパー・フィルター・メソッド)へ一律に適用する。豆だけ直して終わらせない。
- `lib/models/`を変更したら`dart run build_runner build --force-jit`で`*.g.dart`を再生成する(`--delete-conflicting-outputs`は使わない)。
- 統計解析・予測機能は`statistics_feature_design.md`が正本。数値計算(回帰・PCA・GP・EI・検定)はDartローカル実装で行い、LLMに計算させない。
- 秘密情報(Gemini APIキー等)をコード・ドキュメント・コミットに含めない。
- `git commit`/`git push`/`firebase deploy`/`clasp push`/本番データの削除は行わない。
- 指示に無い仕様(フィールド名・シート列名・画面ID・UI文言)を発明しない。判断が要る点は実装せず質問として報告する。
- 委譲の仕組みと役割ごとの規約は`docs/antigravity_delegation_design.md` §9を参照。
