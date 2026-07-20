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
- **`MockScreenScaffold`(`ListView`ベース)を使う画面のwidgetテストでは、ビューポート外のウィジェットは遅延ビルドのため`find`で見つからない**: 旧`SingleChildScrollView`+`Column`版(全ウィジェットを即座にビルド)と異なり、`ListView`は`SliverChildListDelegate`により表示領域外を遅延構築する。テストでは`tester.drag(find.byType(ListView), Offset(0, -N))`等で対象を表示領域内に入れてから`find`する必要がある。さらに、一度下にスクロールした後に`dragUntilVisible`等で上へ戻そうとすると、行き過ぎてオフスクリーン座標でのタップがヒットテストエラーになることがあるため、**下方向に一方向でのみスクロールする**構成にすると安定する。`CreateFormScaffold`も同じ`ListView`ベースのため同様の注意が必要。`tester.ensureVisible(finder)`は対象がキャッシュ範囲内で既にマウント済みの場合のみ有効(`finder.evaluate().single`が先に成立する必要があるため)で、フィールド追加等でレイアウトが伸びて対象がボトムナビ等の下に隠れているケースでは同じ座標のままタップがヒットテスト失敗することがある。確実なのは`tester.drag(find.byType(ListView), Offset(0, -N))`で明示的にスクロールする方法(T3-17で031に入力欄を追加した際、既存の`tester.tap(...DropdownButtonFormField...)`が突然ヒットテスト失敗するようになり、`ensureVisible`を挟んでも解決せず、`drag`に置き換えて解決した)。
- **widgetテストで、SnackBar表示直後に`pumpAndSettle()`を使うと、既定4秒の表示〜自動消滅タイマーまで仮想時間が進みきってしまい、直後の`find.text`アサーションが不安定になることがある(特に同一テスト内で2回目のSnackBarを検証する場合)**: `pumpAndSettle()`の代わりに`pump()`+`pump(Duration(milliseconds: 500))`のように短い固定時間だけ進めると、表示直後の状態を安定して検証できる。
- **「テーマ切り替え」「メインカラー設定」のような全体配色機能を実装する前に、既存UIがどれだけハードコードされたパレット定数(本プロジェクトでは`create_form_widgets.dart`の`kEspresso`等)に依存しているかを必ず確認する**: 本プロジェクトは黒板風テーマ含め大半の画面がconst色定数を直書きしており、`MaterialApp`の`ThemeData`を動的に染め替えても実際の見た目はほとんど変わらない(NavigationRail等の標準Materialウィジェットにしか反映されない)。全画面に反映される機能として実装しようとすると影響範囲が大きすぎるため、着手前にスコープを「Material標準UIのみ反映」等へ現実的に絞り、その制約をUI上にも明記するのが安全(T2-7で採用した方針)。
- **`claude-in-chrome`拡張が未接続(「Browser extension is not connected」)のことがある**: その場合はPlaywright MCP(`mcp__playwright__browser_navigate`等)で代替できる。ローカルの`flutter build web`成果物を`python -m http.server`で配信してのstandalone表示確認や、デプロイ済みの本番URL(Firebase Hosting等)への直接アクセスによる実データ接続確認にも問題なく使えた(T3-10・T3-11で採用)。
- **`.playwright-mcp/`・`.firebase/`のような、ツール実行のたびに生成される作業ディレクトリは、毎回手動で片付けるのではなく`.gitignore`に追記して恒久的に無視する**: 手動`Remove-Item`や個別コミットでの削除は、次回セッションでまた同じファイルが未追跡/誤追跡状態で現れる原因になる(実際に`.playwright-mcp`配下がCycle 19完了コミットで誤って追跡されていた)。生成物と判明した時点でgitignore側に足すほうが再発しない。
- **Firebase Hosting等、Firebase CLIを使うタスクで「初回ログインはユーザー操作」と見積もっていても、別の目的(例: Cycle 18のFirestore設定)で過去に`firebase login`済みなら認証情報が端末に残っており、そのまま使えることがある**: 着手前に`firebase projects:list`(または`firebase login:list`)を実行し、対象プロジェクトにアクセスできるか確認してから、本当にユーザーへログインを依頼する必要があるか判断する。
- **`ref.read(xxxProvider).value`(`FutureProvider`)は、そのProviderが一度もfetch完了していない場合nullを返す**: widgetの`build`外(サービスクラス等)で一回きりの読み取りをする際に`.value ?? []`のようなフォールバックを書くと、未fetch時に「データが空」と誤認する静かなバグになる(実例: `ImageService.importMasterImages`が、設定画面に直接遷移し該当マスター一覧を一度も開いていない場合に画像を常に「Skipped」判定していた)。確実にデータを待つ必要がある一回性の読み取りは`await ref.read(xxxProvider.future)`を使う。
- **Flutter Webは`flutter_service_worker.js`のキャッシュにより、`flutter build web`で再ビルドしてもブラウザが古い`main.dart.js`を実行し続けることがある**: 「コードを直したのに動作が変わらない」と感じたら、まずconsoleで`(await navigator.serviceWorker.getRegistrations()).forEach(r=>r.unregister())`+`(await caches.keys()).forEach(k=>caches.delete(k))`を実行してから再読み込みし、疑いを晴らす。
- **`file_picker`(Web)が開くOSネイティブのファイル選択ダイアログは、`computer`ツールでのクリックでは自動操作できない(ダイアログ自体を認識・操作できず、`pickFiles()`が即座に「キャンセルされた」扱いで返る)**: 検証したい場合は、`HTMLInputElement.prototype.click`を一時的にオーバーライドしてhidden `<input type=file>`への参照を捕捉し(ネイティブダイアログは開かせない)、`DataTransfer`で合成した`File`オブジェクトを`input.files`にセットして`change`イベントを`dispatchEvent`する方法で、実際のダイアログを介さずファイル選択を再現できる。
- **GAS Web Appは複数の「デプロイ」が並存でき、片方だけを編集・再デプロイしても、コードが実際に指しているURL(例: `kGoogleSheetsApiUrl`)が別のデプロイのままだと修正が反映されない**: 権限やコード変更の反映を確認する際は、思い込みで判断せず、実際にアプリが使っている正確なURLに対して直接curl等で疎通確認する。複数デプロイが生まれた経緯があるなら、どちらが「本物」かをデプロイIDの比較で必ず確認する。
- **このサンドボックスでは`flutter run -d chrome`のデバッグ接続(DDC/ホットリロード用WebSocket)が不安定で、別途ブラウザタブから同じポートに手動でnavigateしても正しく描画されない(Dartは動くがcanvasが一切生成されない)ことがある**: この場合は`flutter build web`→`python -m http.server <port>`で静的配信し、そのURLにアクセスする方が確実(`flutter run`のライブリロードは失うが、目視・自動操作の検証には十分)。
- **Phase 4の数値基盤(`lib/services/math/`等)・サービス層タスクは、既存画面への結線(差し替え)が別タスクに分離されている限り`flutter run`でのブラウザ確認対象にならない**(T4-0a実施時の判断): 設計書のタスク分解では「新規ファイル実装」と「既存呼び出し元の差し替え(例: T4-3aでの`_jacobiEigenvalueAlgorithm`→`eigenSymmetric`)」が別タスクになっていることが多く、実装タスク単体では画面上の見た目・挙動が一切変わらない。この場合は無理にブラウザ確認を試みず、`flutter analyze`+`flutter test`(新規ロジックの単体テスト追加)のみで検証完了とし、その旨をNEXT_SESSION.md/マスタープランに明記する。逆に、結線タスク(差し替え本体)に着手する際は通常通りブラウザ確認が必須。
- **設計書§12②の「Python検証をスクリプト化」運用は、固定数値の期待値がある場合は有効だが、`Random(シード)`を使うテストケースの検証には使えない**(T4-0a実施時の判断): DartとPythonのPRNGはアルゴリズムが異なり同じシードでも同じ乱数列にならないため、`test/math/eigen_test.dart`のケース3(`Random(42)`の6x6ランダム対称行列)のような性質ベースのテストは、Python側で別シード・別乱数の行列を使って同じ性質(直交性・固有方程式・trace保存等)が成り立つことを確認する形にとどまる(Dart側の具体的な行列要素と1対1で突き合わせることはできない)。固定の解析的期待値(2x2・対角行列等)は数値まで完全に突き合わせ可能。
- **GAS Web AppへのPOSTで`Content-Type: application/json`を指定すると、実ブラウザからは`fetch`のCORSプリフライト(OPTIONS)がGAS側で処理されず`TypeError: Failed to fetch`になるが、`curl`はプリフライトをしないため同じリクエストが問題なく成功してしまう**: `curl`だけで疎通確認して「バックエンドは正常」と判断すると、実ブラウザ限定の不具合を見逃す(実例: `image_service.dart`の`uploadImage`/`deleteImage`が終始このパターンで失敗し、`sheets_service.dart`の`_postData`に既にあった同種の対策コメント「text/plainでプリフライトを回避」が横展開されていなかった)。GASの`doPost`は`Content-Type`ヘッダの値に関わらず`e.postData.contents`を`JSON.parse`するため、送信側ヘッダを`text/plain`にしても実害はない。GAS Web Appへの新規POST処理を書く際は必ず`text/plain`を使う。ブラウザ限定の不具合を疑う場合は、`curl`ではなく実ブラウザの`javascript_tool`で`fetch(url, {headers:{'Content-Type':...}})`を直接実行して`TypeError`の有無を比較すると、プリフライト起因かどうかを`curl`より確実に切り分けられる。
- **Dartのファイル間循環import(A.dartがB.dartをimportし、B.dartもA.dartをimportする)は、両者がクラス定義のみでトップレベルの循環初期化(const同士の相互参照等)を伴わない限り、`flutter analyze`・ビルドとも問題なく解決できる**(T3-19で`master_template.dart`が5つのマスター一覧画面をimportし、うち4つは元々`master_template.dart`をimportしていた実例で確認)。ただし可読性・保守性の観点では避けられるなら避けたほうがよく、既存コードにこのパターンが無いか事前に不安に思う必要はないが、意図的に導入する場合は一言コメントで理由を残すとよい。
