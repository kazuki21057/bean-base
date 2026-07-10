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
- **クラウド環境にFlutter SDK未導入のことがある**: `flutter`コマンドが無い場合、`.metadata`のDart SDK制約(`pubspec.yaml`の`environment.sdk`)を満たすstableリリースを`https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`から確認し、スクラッチパッド等に展開してPATHに追加する。古すぎるバージョンだと`pub get`がDart SDKバージョン不一致で失敗するので注意。`flutter pub get`で意図せず`pubspec.lock`の無関係な依存バージョンが更新されることがあるため、タスクに無関係な差分は`git checkout`で戻す。
- **Flutter Web(CanvasKit)は初回描画時に一部漢字がグリフ未読込でトウフ文字化けすることがある**: 再描画(別画面から戻る等)で正しく表示されれば、フォントグリフの遅延読み込みによる一過性の現象でありコードのバグではない。同じ文字が別画面/別データでも一貫して欠落する場合のみ実バグと判断する。
- **Chrome拡張のマウスホイールscrollがFlutter Web(CanvasKit)のスクロール可能領域に効かないことがある**: `computer`ツールの`scroll`/`left_click_drag`が反応しない場合、無理に全項目をスクロール確認せず、同一ロジックの代表的な1項目をクリックして遷移・戻りの仕組みを確認すれば十分(特にリスト全件を検証する必要がある画面一覧系のデバッグ画面で発生)。
- **`.playwright-mcp/`配下は誤ってgit管理下に入っていることがある**: 視覚確認用スクリーンショットの後片付けで`Remove-Item -Recurse -Force ".playwright-mcp"`のようにディレクトリごと消すと、過去に誤コミットされた追跡ファイルまで削除してしまう。片付け後は必ず`git status`で意図しない`D`(削除)が無いか確認し、あれば`git checkout -- <path>`で復元してからstageする。
- **UIモック(見た目のみ)を複数画面まとめて作る際は共通部品を先に作る**: `create_form_widgets.dart`/`mock_scaffold.dart`のようにパレット・セクション・入力部品・リスト行を共通化してから各画面を組み立てると、22画面でも配色・余白が揃い、Phase 2の本テーマ化時の置き換え箇所が1箇所で済む。
- **日次コスト上限超過後にユーザーが明示的に続行を承認した場合**: `AskUserQuestion`で都度(タスク追加のたびに)承認を取り、`NEXT_SESSION.md`に「通常のタスク表とは別枠の依頼で、コスト超過をユーザー承認の上続行した」旨を明記する。マスタープランの該当タスクの状態(⬜/✅)は、実際にそのタスクの終了条件(実データ接続など)を満たすまで変更しない — 先行UIモックが存在してもタスク自体は未完了として扱う。
- **`MainLayout`の`NavigationRail`(lib/layout/main_layout.dart)で、ブラウザのウィンドウリサイズ/一部のスクロール操作をきっかけに`RenderFlex overflowed`(NavigationRail内)がコンソールに出て、その後タブの描画が数十秒〜応答なしになる現象を確認(T1-2a検証時)**: 発生条件を絞り切れておらず、`computer`ツールのマウスホイールscrollやウィンドウリサイズがFlutter Web側に不整合なイベントを送っている可能性がある(既存の「Chrome拡張のマウスホイールがFlutter Webのスクロールに効かない」教訓と関連)。ページを再読み込みすれば復旧し、データ処理自体に影響はない。次にこの画面(030等の縦長画面)を本実装する際は、実データで縦スクロールが発生する状態での`NavigationRail`のレイアウト安定性を軽く確認し、再現するようなら`NavigationRail`側(labelType/高さ制約)の見直しを検討する。
- **`mcp__Claude_Preview`(`flutter run -d web-server`)でCanvasKitの初回ペイントがハングし、`preview_screenshot`がタイムアウトし続けることがある(T1-5a〜c検証時)**: ネットワーク要求(canvaskit.wasm/js含む)はすべて200で成功し、`document.body`に`flt-glass-pane`は生成されるが`<canvas>`要素が最後まで作られず、セマンティクスツリーも空のまま。ページの`location.reload()`で一部改善する場合もあるが再現性は低く、数分待っても解消しないことがある。`flutter analyze`/`flutter test`が正常な場合はコード側の不具合ではなくプレビュー環境固有の制約と判断してよい。この状態で粘るよりも、対象画面をフェイク`DataService`(`overrideWithValue`)で差し替えたwidgetテスト(`flutter test`)を書いて一覧→詳細→編集→保存/削除の導線を検証する方が速く確実。最終的な見た目確認は`NEXT_SESSION.md`にユーザーへの依頼として明記する。
- **`claude-in-chrome`経由でのブラウザ目視確認は本番のGoogle Sheetsデータに直接繋がる**: T1-6a以降、このサンドボックスでも`flutter run -d chrome`のcanvasが正常にペイントされるようになった(以前の教訓と異なりハングしないケースが増えた)。確認できるようになった分、**編集/新規/削除画面で「保存する」「削除」等の書き込み系ボタンを実際に押さない**こと(実データが書き換わる)。プリフィル内容の確認・画面遷移の確認に留め、キャンセルで抜ける。
- **Windows: `flutter run -d chrome --web-port=N`をバックグラウンドで動かした後、対応する`Bash`タスクを`TaskStop`しても配下のdartプロセスがポートを掴んだまま残ることがある**: 同じポートで次回`flutter run`すると`Failed to bind web development server`(errno 10048)で失敗する。`TaskStop`後は`netstat -ano | grep LISTENING | grep ":<port>"`でPIDを確認し、`taskkill //F //PID <pid>`で明示的に終了させてから次を起動する。
- **`mcp__claude-in-chrome__navigate`の初回呼び出しが`Permission denied by user`を返すことがある**: 実際にユーザーが拒否したわけではなく、内部の権限チェックが一度目だけ引っかかる一過性の挙動と見られる。同一の`navigate`呼び出しをそのまま再試行すれば成功する。
- **`ScheduleWakeup`は、タスク通知(task-notification)を受けて処理を進めた後は速やかに`stop:true`で明示的にキャンセルする**: 通知を受けて作業を続行しても、以前設定した`delaySeconds`が経過すると同じ`prompt`文言が後から重複して届くことがある(ユーザーの新規発言と誤認しないよう、文言が過去に自分が設定したプロンプトと一致していないか確認する)。
- **モデルに`json_serializable`のフィールドを1つ追加しただけでも、`dart run build_runner build --delete-conflicting-outputs`は無関係な他モデルの`*.g.dart`まで書き換えることがある**: 中身は変わらずCRLF/LF差分のみのことが多い。コミット前に`git diff --stat`で実差分ゼロのファイルを確認し、それらはstageしない(ノイズの少ないコミットのため)。
