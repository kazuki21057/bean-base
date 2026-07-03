# 検証ルール (Verification Rules)

コードを提出(commit)する前に、必ず以下の検証を順に実施する。

## 必須検証フロー

1. **静的解析**: `flutter analyze` — 新規のエラー・警告をすべて解消する(既存 issue はスコープ外)。
2. **自動テスト**: `flutter test` — 全件パス。ロジックを追加した場合は対応する単体テストも追加する。
3. **実行時検証**: `flutter run -d chrome` で以下を確認する。
   - **安定性**: クラッシュせず起動し、コンソールに `Exception`/`Error` ログが出ない。
   - **UI**: Overflow 警告(黄黒ストライプ)が出ない。
   - **外部サービス(重要)**: Google Sheets(GAS Web App)・Google Drive(画像)・Gemini API との通信が成功する。認証・データ送受信・パースを確認し、タイムアウトやエラーが握りつぶされていないこと。
4. **視覚検証**: コードを読むだけでなく、ブラウザ(必要なら Playwright)で実際の挙動を確認する(例: 画像アップロードボタンが実際にクリックできるか)。Playwright の snapshot・スクリーンショットはコスト抑制のため要所のみ。

## コーディング規約

- **ロギング**: 主要アクションと外部サービス連携には `[Antigravity]` prefix で明示的にログを出す。
  ```dart
  debugPrint('[Antigravity] Action: Sync to Google Sheets started');
  try { ... } catch (e) { debugPrint('[Antigravity] Error: $e'); }
  ```
- **マスター系の変更は全種別へ**: マスターの UI・機能を追加・修正する際は、Bean だけでなく Grinder / Dripper / Filter(該当すれば Method も)すべてに漏れなく適用する。共通部品化できる場合は共通化を優先する。

## 教訓 (Lessons Learned)

- **ID 型キャスト**: Sheets 等の外部データは数値 ID を int/double で返すことがある。モデルの `fromJson` では String 想定の ID を必ず `.toString()` で明示キャストする(`type 'int' is not a subtype of type 'String?'` 対策)。空 ID はガードする。
- **GAS デプロイ URL**: GAS スクリプトを更新すると新しいデプロイ URL が発行される。`kGoogleSheetsApiUrl` の更新を忘れない。
- **サンドボックス制限**: エージェントのサンドボックス環境は外部 API(GAS/Drive/Firebase)への通信をブロックすることがある。その場合、最終疎通確認はユーザーがローカルで `flutter run` して行う。
- **Firestore はレガシー**: `FirestoreService` 系に触る指示があった場合のみ、`flutterfire configure` で `firebase_options.dart` を実値に再生成してから作業する。
