# 検証ルール (Verification Rules)

コードを提出(commit)する前に、必ず以下の検証を順に実施する。

## 必須検証フロー

> **出力は必ず絞る(2026-08-02)**: `analyze`/`test` の全文出力は1回で7k〜13k文字あり、以後のリクエスト全部に課金され続ける(`CLAUDE.md`§トークン運用規約)。下記の短出力形を既定とし、**失敗したときだけ**詳細を取り直す。

0. **一括検証スクリプト(2026-08-08新設、まずこれを使う)**: `tools/verify.ps1`(Windows)/`tools/verify.sh`(Bash)が、下記1〜2の静的解析・自動テストに加えビルド等を含む9項目を1コマンドでまとめて実行し、結果をJSON 1つで標準出力へ返す。`-Task <タスクID>`を付けると受け入れ資産の合否(`checks.acceptance`)も判定する。受け入れ資産の要否判定・作成規約は`docs/acceptance_harness_design.md`が正本。
   - 実行: `powershell -File tools/verify.ps1`(Windows、引数`-Edition personal|public`、既定`public`)。Bash環境では`tools/verify.sh`が同一の8項目・同一JSONスキーマを返すが**`jq`必須**(`jq`不在時は`{"ok":false,"error":"jq_not_found",...}`を返し非ゼロ終了する既知の制約。その場合は下記フォールバックへ切り替える)。
   - **読み方**: 標準出力のJSON(各項目の`ok:true/false`の**サマリのみ**)を読む。**失敗した項目だけ**、その`log`フィールドが指す`.claude/verify_logs/<timestamp>_<項目名>.log`を`Grep`/`Read(offset/limit)`で該当箇所だけ読む。成功項目のログ・生出力は読まない。
   - これで静的解析・自動テスト・ビルドが完了していれば、下記1・2は実施済みとみなしてよい。下記3(実行時検証)・4(視覚検証)はこのスクリプトでは自動化できないため、引き続き自分で行う。
   - **フォールバック(スクリプトが使えない場合のみ)**: `jq`不在等でスクリプトが実行できない場合に限り、下記1・2を個別コマンドで実施する。

1. **静的解析**(スクリプトが使えない場合のフォールバック): 既存 issue はスコープ外。新規分だけを見るため件数の差分で判定する。
   - PowerShell: `flutter analyze 2>&1 | Select-String -Pattern "issues found|error •" | Select-Object -Last 5`
   - Bash: `flutter analyze 2>&1 | grep -E "issues found|error •" | tail -5`
   - 既存件数のベースラインは `.claude/analyze_baseline.txt`(数値1行)。件数が増えていたら**そのときだけ** `flutter analyze 2>&1 | tail -100` で内容を確認する。
2. **自動テスト**(スクリプトが使えない場合のフォールバック): `flutter test 2>&1 | tail -15` — 全件パス。失敗したときだけ `| tail -150` で詳細を取り直す。ロジックを追加した場合は対応する単体テストも追加する。
3. **実行時検証**: `flutter run -d chrome` で以下を確認する。
   - **安定性**: クラッシュせず起動し、コンソールに `Exception`/`Error` ログが出ない。
   - **UI**: Overflow 警告(黄黒ストライプ)が出ない。
   - **外部サービス(重要)**: Google Sheets(GAS Web App)・Google Drive(画像)・Gemini API との通信が成功する。認証・データ送受信・パースを確認し、タイムアウトやエラーが握りつぶされていないこと。
4. **視覚検証**: コードを読むだけでなく、ブラウザ(必要なら Playwright)で実際の挙動を確認する(例: 画像アップロードボタンが実際にクリックできるか)。Playwright の snapshot・スクリーンショットはコスト抑制のため要所のみ。
   - **`claude-in-chrome`の`computer scroll`がFlutter Web(CanvasKit)画面で効かない場合**: `javascript_tool`で`document.querySelector('flt-glass-pane')`を取得し、合成`WheelEvent`(`new WheelEvent('wheel', {deltaY: 1500, deltaMode: 0, bubbles: true, cancelable: true, clientX, clientY})`)を`dispatchEvent`すると内部スクロールが効くことがある(L98)。この直後の`screenshot`はまれに拡大率がずれることがあるが、`navigate`し直せば直る。
5. **goldenテスト(`test/golden/`、T5-A8で新設)**: 共通コンポーネント(`lib/widgets/`配下)をライト/ダーク2バリアントで`matchesGoldenFile`により画像比較する。**LLM/エージェントは`flutter test --update-goldens`等でgoldenファイル(`test/golden/**/*.png`)を自動更新してはならない**。意図的なデザイン変更でgoldenが落ちた場合は、差分(`test/golden/failures/`に出力される比較画像)を人間が目視確認した上で、ユーザーの明示的な指示がある場合のみ更新する。新規コンポーネントのgolden追加時の初回生成(まだ比較対象画像が存在しない状態でのベースライン作成)はこの禁止の対象外。**ベースラインはWindows環境で生成した画像に固定する**(T5-A8、2026-08-10決定)。OS間で差が出るのはテキストのラスタライズのみ(図形描画はビット単位一致)で、Ubuntu生成の画像はWindowsで最大2.68%のピクセル差が出て必ず落ちるため。Windows以外の環境では`golden_test_helper.dart`の`skipGoldenOnNonWindows`により6件がスキップされる(失敗にはしない)。**ベースライン生成環境の移行のような、意図的なデザイン変更を伴わない再生成も、ユーザーの明示的な指示があるタスクに限り許可する**(エージェントの自己判断での`--update-goldens`は引き続き禁止)。
6. **overflow判定のwidget test化(D-4節、T5-A8で導入)**: `test/helpers/overflow_test_helper.dart`の`pumpAndDetectOverflow`/`expectNoOverflow`で、`FlutterError.onError`を差し替えて`A RenderFlex overflowed`をエミュレータ不要のwidget testとして機械判定できる。`tester.view.physicalSize`/`devicePixelRatio`で360x690・411x914・320x690の3サイズを模する。`SettingsScreen`のような`SharedPreferences`/`FutureProvider`を使う画面は、`SharedPreferences.setMockInitialValues({})`とネットワーク依存プロバイダのフェイク差し替えをしないと初期ロードスピナーが解消せず`pumpAndSettle`がタイムアウトする(`test/settings_screen_overflow_test.dart`参照)。

## 既知の失敗しやすい検証経路(2026-08-13新設)

- **Androidエミュレータ**: 検証のリトライ上限は2回までとする。2回試して起動・操作が安定しない場合、3回目は同じ方法を繰り返さず、`architect`へのエスカレーション、または別の確認手段(ブラウザ・widgetテスト等)への切り替えを検討する。
- **ブラウザ優先**: 可能な限りブラウザ(Chrome、`claude-in-chrome`)での検証を優先する。Androidエミュレータは、`lib/screens`等のUI変更でモバイル固有の挙動(タップ操作・端末サイズ依存レイアウト等)の確認がどうしても必要な場合に限り使う。
- **GASエンドポイントへの直接curl禁止**: Google Apps Script(GAS)Web Appエンドポイントへ`curl`等で直接POST/GETして検証することはできない(サンドボックスがGAS/Driveトラフィックをブロックすることがあるため。詳細は上記L114等の教訓も参照)。GAS経由の動作確認は、ローカルの`flutter run`(またはローカル配信した`build/web`)でアプリUI経由で行う。
- **夜間ループの既知障害と自動対処**: `docs/failure_playbook.md`が正本(検知シグネチャ・自動対処・エスカレーション基準)。

## コーディング規約

- **ロギング**: 主要アクションと外部サービス連携には `[Antigravity]` prefix で明示的にログを出す。
  ```dart
  debugPrint('[Antigravity] Action: Sync to Google Sheets started');
  try { ... } catch (e) { debugPrint('[Antigravity] Error: $e'); }
  ```
- **マスター系の変更は全種別へ**(詳細・外部ID規約は`CLAUDE.md`§Verification Rules参照): マスターの UI・機能を追加・修正する際は、Bean だけでなく Grinder / Dripper / Filter(該当すれば Method も)すべてに漏れなく適用する。共通部品化できる場合は共通化を優先する。

## 教訓インデックス (Lessons Learned)

全文は `rules/lessons_archive.md`(**通常は読まない**)。下の1行見出しで当たりを付け、番号(`L37`等)かキーワードで grep して該当項目だけ読む。
実装前に、そのタスクに関係するカテゴリの見出しだけ流し読みすること。分類は目安なので、探し物が見つからないときは `rules/lessons_archive.md` を直接 grep する。

### Flutter / Dart 実装
- L23 モデルに`json_serializable`のフィールドを1つ追加しただけでも、`dart run build_runner build --de…
- L31 `ref.read(xxxProvider).value`(`FutureProvider`)は、そのProviderが一度もfetch完了していな…
- L51 Dartのファイル間循環import(A.dartがB.dartをimportし、B.dartもA.dartをimportする)は、両者がクラス定義…
- L55 Flutter Webのプラグイン自動登録(`web_plugin_registrant.dart`)がreleaseビルドで初期化順に間に合わずク…
- L63 `dart run build_runner build --delete-conflicting-outputs`が、このマシンではDart SD…
- L71 新しいWeb対応パッケージ(federated plugin、例: `image_picker`)を`pubspec.yaml`に追加しても、`.d…
- L73 Riverpodの`FutureProvider`/`AsyncNotifierProvider`は、`ref.invalidate(provide…
- L74 `FutureProvider`から`AsyncNotifierProvider`へ型を変える際、テストの`provider.overrideWit…
- L75 既存ファイルの一部だけを変更する際、変更箇所を含むファイル全体に`dart format`をかけると、意図していない既存コードの行送りまで変わり、新…
- L76 `TextFormField(initialValue: ...)`は内部コントローラの初回生成時にしか使われないため、親が`setState`で再…
- L77 同じ問題は`initialValue`を`initState`でしか読まない自前のStatefulWidgetでも起きる
- L82 関数内で`showDialog`直後に`TextEditingController`を手動`dispose()`すると、ダイアログを閉じるルート遷移…
- L83 外部パッケージを追加するかどうかをユーザーに確認する前に、`flutter pub add --dry-run <package>`で解決結果を先に…

### テスト (flutter test / widgetテスト)
- L14 `mcp__Claude_Preview`(`flutter run -d web-server`)でCanvasKitの初回ペイントがハングし、`…
- L19 widgetテストで`ElevatedButton.icon`/`TextButton.icon`のボタンを`find.widgetWithText…
- L24 `MockScreenScaffold`(`ListView`ベース)を使う画面のwidgetテストでは、ビューポート外のウィジェットは遅延ビルドの…
- L25 widgetテストで、SnackBar表示直後に`pumpAndSettle()`を使うと、既定4秒の表示〜自動消滅タイマーまで仮想時間が進みきって…
- L28 産地名の解決規則は「豆側」と「記録側」で揃える(F3推奨焙煎度・F5グループ化)
- L35 `MockScreenScaffold`/`MasterDetailTemplate`の`children`は素の`ListView(childre…
- L59 widgetテストで、処理の途中で複数回`ScaffoldMessenger.showSnackBar`を呼ぶコード(例: 副次処理の失敗通知→本処…
- L70 widgetテストで`tester.drag(find.byType(ListView), Offset(0, -N))`による画面下部への大きなス…
- L72 `Map`リテラルの宣言順が、実行時のロジックに直接影響することがある
- L78 同じ計算を画面本体とその子ウィジェットで二重に実装すると、片方だけ仕様変更されて静かに食い違う
- L84 widgetテストでMaterialの`showDatePicker`(`DatePickerDialog`)を実際に操作する場合、「今日」を基準に…
- L101 「A/B/Cはセットの旧ロジック」でも一律に扱わない。呼び出し元grepはメソッドごとに個別確認する(BはA経由でしか呼ばれず実は枯れ木、ということがある)
- L100 T3-74aでL99を修正: `OptimisticListNotifier`から`_syncInBackground()`を削除(案a採用、L96の前提は解消)。テストのfakeサービスが`getXxx()`で内部リストを参照のまま返すと、楽観的追加と二重加算され重複することが発覚(fakeは`List.of(...)`でコピーを返すこと)
- L106 画面に新規の必須バリデーション(早期return)を追加すると、既存widgetテストのfixtureがまとめて不合格になることがある。テストのバグか実装のバグかを`[E]`のスタックトレースで切り分け、fixture側を新条件に合わせて更新する。バリデーションが効くこと自体の否定的テストも追加する
- L107 「入力データの形によって分岐が変わる」ロジックの不具合は、コードを読むだけでなく本番の実データ(`curl`+`node -e`等)で境界パターンを洗い出してから再現ケースを特定する。ロジックは`_State`のprivateメソッドに置きっぱなしにせず`lib/utils/`の純粋関数に切り出すとwidgetテスト無しで直接検証できる
- L108 widgetテストで`DropdownButton`(選択中の項目)を選ぶと、閉じたボタン自身が選択ラベルを表示するため、同じテキストがリスト行にもあると`find.text(...)`が2件ヒットして`findsOneWidget`が失敗する。絞り込み結果の検証は選択していない側の値が消えたことで判定する
- L109 Gemini APIキー(`shared_preferences`キー`gemini_api_key`)はブラウザのオリジン単位で保存されるため、`build/web`を本番と別ポート(`localhost:XXXX`)でローカル配信して確認するときは本番オリジンに保存済みのキーを引き継げない。AI機能(購入店情報取得・画像からの豆情報抽出等)を絡む変更の本番確認では、APIキー入力ダイアログが出た時点で実フローの確認は打ち切り、ロジックはwidgetテスト(fakeサービス)で担保する。APIキーの手入力は資格情報を扱う操作のため実施しない
- L99 `OptimisticListNotifier.updateOptimistic`等の直後の`_syncInBackground()`が、GAS書き込み直後だと稀に更新前データで上書きする問題 → **L100で`_syncInBackground()`自体を削除し解消済み**
- L96 (L100で`_syncInBackground`を削除したため前提が解消・参考情報として残す) `OptimisticListNotifier.addOptimistic`は追加直後に`_syncInBackground`で`fetch()`を再取得するため、fakeサービスの`getXxx()`が固定で空リストを返すテストでは追加した項目が消える。fakeの`addXxx`は対応する`getXxx`のバッキングリストを実際に更新すること

### ブラウザ目視確認 (claude-in-chrome / Playwright)
- L06 Flutter Web(CanvasKit)は初回描画時に一部漢字がグリフ未読込でトウフ文字化けすることがある
- L08 Chrome拡張のマウスホイールscrollがFlutter Web(CanvasKit)のスクロール可能領域に効かないことがある
- L12 `MainLayout`の`NavigationRail`(lib/layout/main_layout.dart)で、ブラウザのウィンドウリサイズ…
- L17 `claude-in-chrome`経由でのブラウザ目視確認は本番のGoogle Sheetsデータに直接繋がる
- L20 統計画面(040)の新規セクションは画面最下部に積み上がり、本環境のFlutter Webスクロール制約で目視到達できないことがある
- L21 `mcp__claude-in-chrome__navigate`の初回呼び出しが`Permission denied by user`を返すことがある
- L27 `claude-in-chrome`拡張が未接続(「Browser extension is not connected」)のことがある
- L33 `file_picker`(Web)が開くOSネイティブのファイル選択ダイアログは、`computer`ツールでのクリックでは自動操作できない(ダイ…
- L38 `claude-in-chrome`拡張の`computer`ツール(CDP経由の合成マウスイベント)は、Flutter Web(CanvasKit…
- L53 `youtube_player_iframe`等のwebview/platform-view系ウィジェットは、このサンドボックス(CanvasKit…
- L57 Flutter Web(CanvasKit)の`NavigationRail`は選択中タブのみラベル表示(`labelType: selected`…
- L61 Flutter Web(CanvasKit)で新規画面へ遷移した直後(FAB押下等)にすぐスクリーンショットを撮ると、レイアウトが確定する前のフレー…
- L66 `claude-in-chrome`の`computer`(`zoom`)でCDPの`Page.captureScreenshot`がタイムアウトす…
- L80 この環境でのFlutter Web(CanvasKit)ナビゲーションは、`claude-in-chrome`の`computer`ツールおよびPl…
- L98 `computer scroll`が効かないFlutter Web画面でも、`javascript_tool`で合成`WheelEvent`を`flt-glass-pane`へ`dispatchEvent`するとスクロールできることがある
- L102 「画像URLが入っている」と「ブラウザで画像が出る」は別問題。同じURLでも`fetch`は200で`<img>`はonerrorになりうる(Drive/lh3)。プレースホルダーへのフォールバックはコンソールに何も出さないので壊れても気付けない
- L103 `claude-in-chrome`のタブでビューポートが451x73に固定され`resize_window`でも戻らないことがある → `tabs_create_mcp`でタブを作り直す
- L104 L06(初回描画時の漢字トウフ)は、本番URLでは**2〜3秒待って再描画すると同一画面内で正常な文字に回復する**一過性の事象であることが多い。1枚のスクリーンショットだけで「常に読めない」と判定しない。フォント取得自体は`performance.getEntriesByType('resource')`で`fonts.gstatic.com`の`transferSize`/`decodedBodySize`を見れば成否が数値で分かる(失敗していないのに描画だけ遅れることがある)

### GAS / Sheets / Drive 連携
- L01 ID 型キャスト
- L02 GAS デプロイ URL
- L13 Windows Git Bash経由のcurlで日本語(マルチバイト)を含むJSONを`-d`引数へ直接埋め込むと文字化けし、GAS側で誤ったバグ調…
- L15 `curl`でGAS Web AppにPOSTするときは`-X POST`を付けない(T3-23で411/重複登録を誘発)
- L16 モデルにフィールドを追加したら、SheetsServiceのマッピング2箇所とGASの列プロビジョニングの両方を必ず更新する(T3-23で残豆量機能…
- L34 `build/web/main.dart.js`の中身確認に`grep`で日本語文字列を検索しても常に0件になる
- L36 GAS Web Appは複数の「デプロイ」が並存でき、片方だけを編集・再デプロイしても、コードが実際に指しているURL(例: `kGoogleShe…
- L42 既存モデル(`BeanMaster`等)にフィールドを追加しただけでは、Google Sheetsへの読み書きは自動で反映されない
- L43 GAS Web AppへのPOSTで返る302リダイレクトを、`package:http`のクライアントは自動追従しないことがある
- L44 `SheetsService`(`lib/services/sheets_service.dart`)は`flutter_riverpod`(→Fl…
- L45 本番の外部サービス(GAS等)に書き込むスクリプトを「インポートが解決できるかの確認」目的で実行してはいけない
- L47 このサンドボックスからGAS/Driveへ疎通できるかどうかは回によって変動する
- L49 設計書§12②の「Python検証をスクリプト化」運用は、固定数値の期待値がある場合は有効だが、`Random(シード)`を使うテストケースの検証に…
- L50 GAS Web AppへのPOSTで`Content-Type: application/json`を指定すると、実ブラウザからは`fetch`のC…
- L79 `sheets_service.dart`の`_postData`が呼ぶGAS `delete`アクションのペイロードキーは英語の`id`ではなく、…
- L81 Google Sheetsは「数字だけの文字列」を書き込むと自動的に数値型セルに変換することがあり、対応するDartフィールドが`String`型で…
- L95 「湯量がおかしい」の原因はコードでなく本番`pouring_steps`の`湯量係数`が固定15g割りだったこと。データ整合性は実データ突合でのみ発見できる
- L105 本番シートのID列名はシートごとに不統一(`methods_master`は`メソッドID`であって`抽出方法ID`ではない)。突合スクリプトで「ID or ID」のフォールバックに頼ると存在しないキーで空集合になり大量の偽陽性未解決が出る。**必ず実際のJSONキー一覧を1回`print`してから列名を書く**

### 統計・設計書 (statistics_feature_design.md)
- L04 Firestore はレガシー
- L39 設計書(`statistics_feature_design.md`)の数値期待値自体が誤記のことがある
- L40 Abramowitz–Stegun 7.1.26のerf近似式は、多項式係数の丸めにより`erf(0)`が厳密な0にならず~1e-9の残差が出る
- L46 Phase 4の数値基盤(`lib/services/math/`等)・サービス層タスクは、既存画面への結線(差し替え)が別タスクに分離されている限…
- L56 設計書の数値期待値の誤記(上記のtQuantile例と同種)は、差の大きさによって対応を分けるべき

### 開発環境・ツール (Windows / サンドボックス / git)
- L137 静的チェック・`-DryRun`だけでは外部CLIラッパーの実行時バグ(`ProcessStartInfo.ArgumentList`がこのPCのPS5.1に無い等)は見つからない。実機で1回本番同等条件で完走させるまで未検証扱いにする(T5-A38/T5-A39実地検証)
- L138 `agy`の`command(<target>)`許可は単語1つでは機能しないが、引数まで含めた完全一致の文字列なら機能する。短い入力で失敗しても「機能自体が無い」と一般化しない(T5-A37)
- L136 設計書で「そのまま埋め込む」と確定させた固定文言でも、文言中の相対語(「上の」等)と実際の挿入位置の整合性は設計時点のチェックが漏れやすい。`-DryRun`等で組み立て後の成果物を1回目視する(`tools/antigravity_delegate.ps1`実装後に発覚)
- L135 Antigravity CLI(`agy`)のヘッドレス実行は「ファイル編集」(既定許可)と「シェルコマンド実行」(`command`権限が必要・自動拒否)で権限区分が異なる。粒度粗く一般化しない(Antigravity CLI委譲調査)
- L133 `/full_loop`セッションはWindows環境とは限らない。タスク選定前に`pwsh`/エミュレータの有無を確認し、実行不可な環境依存タスクは選ばない(T5-A8選定時)
- L132 `.claude/settings.night.json`の`defaultMode: "dontAsk"`は「allowに無ければ拒否」で効く、`Edit`/`Write`未列挙だと無人実行はコード変…
- L131 特定イベント(`UserPromptSubmit`)専用に書いた生テキスト正規表現マッチは、呼び出しイベントを追加する(`PostToolUse`/`SubagentStop`等)ときは必ず`event`種別でガードする。ガード漏れがあると、他イベントのペイロード内の無関係なテキスト(サブエージェント指示文・ファイルパス等)に偶然マッチしてループ境界が誤リセットされ、コストが常に$0になった(T5-A34)
- L130 `ui_verifier`のoverflow判定は、`-Log`にログ行が無くてもスクリーンショットのストライプと`-Dump`のbounds実測(要素幅>親幅)が一致すれば視覚的証拠として信用してよい(ログ行必須の完了条件はT5-A36で原因究明予定)
- L128 PowerShell 5.1で`$ErrorActionPreference="Stop"`下、ネイティブexe呼び出しに`2>$null`/`2>&1`を付けると成功時でも即終了することがある(T5-A4実装中に実見)。捨てたい場合は呼び出し箇所だけ`"Continue"`に落とすか`try/catch`で囲む。ブート直後の`adb shell`応答は一時的に空になりうるためリトライを組み込む
- L127 Windowsで`.ps1`に日本語コメントを`Write`ツールで保存するとBOM無しUTF-8になり、PowerShell 5.1が構文エラーを起こすことがある(T5-A6実装中に実見)。日本語を含む`.ps1`は保存後に`powershell -File`で1回実行確認するか、BOM付きUTF-8で保存し直す。あわせて`adb`等の外部コマンド出力を`.Trim()`する箇所は出力が一時的に空になりうる前提でnull安全に書く
- L117 L116の恒久対処: 素の`pub upgrade`は不可(未使用の`riverpod_generator`がanalyzerを固定)、死に依存の削除+限定upgrade+`build_runner --force-jit`で解消。`--delete-conflicting-outputs`は廃止済み、`clean`はソースの`.g.dart`を消さない
- L116 Ubuntu環境で`build_runner build`がDart SDK/analyzer版数不整合で無限ハングしうる。CPU%でなく`/proc/<pid>/io`の不変で停止確定、killしたら削除済み`.g.dart`を`git checkout`で復元
- L115 新しいUbuntu環境でのAndroid開発セットアップ: `sudo`はBashツールからも`!`プレフィックスからもパスワード入力できない(別ターミナルでユーザー実行が必要)/Flutter 3.38.9はAndroid SDK 36+Build-Tools 28.0.3を要求する
- L85 Bashツールで`git commit -m @'…'@`(PowerShellのhere-string)を使うと、エラーにならず件名が`@`だけの壊れた…
- L03 サンドボックス制限
- L05 クラウド環境にFlutter SDK未導入のことがある
- L09 `.playwright-mcp/`配下は誤ってgit管理下に入っていることがある
- L18 Windows: `flutter run -d chrome --web-port=N`をバックグラウンドで動かした後、対応する`Bash`タスク…
- L29 `.playwright-mcp/`・`.firebase/`のような、ツール実行のたびに生成される作業ディレクトリは、毎回手動で片付けるのではなく…
- L37 このサンドボックスでは`flutter run -d chrome`のデバッグ接続(DDC/ホットリロード用WebSocket)が不安定で、別途ブラ…
- L48 Bashツールで`cd <dir> && (バックグラウンドコマンド)`のように書くと、`cd`が現在のシェルに残り続ける
- L52 このWindows環境では`python3`コマンドは存在しない(Microsoft Store誘導のスタブが応答するだけ)が、`python`およ…
- L54 Flutter Webの不具合は`flutter run`(debug/DDC)では再現せず`flutter build web`(release/…
- L58 Windows環境でcurl等が取得したUTF-8のJSON/テキストファイルをPythonで読む際、`open(path)`のようにencodin…
- L62 `HtmlElementView`(Web版の`youtube_player_iframe`が使うプラットフォームビュー=iframe)を`Clip…
- L64 このマシンには、当該セッション開始前から起動していたと見られる`dartvm`/`dartaotruntime`のゾンビプロセス(CPU使用量が固定…
- L65 build_runner系のバックグラウンドコマンドは、`kill`で強制終了した直後に届く完了通知が`exit code 0`/`complete…
- L67 Git Bash(このBashツール)上のNode.js/Pythonは、いずれもWindowsネイティブ実行ファイルであり、`/c/Users/.…
- L111 プロジェクトスコープの`enabledPlugins: {"firebase@firebase": false}`は、この環境ではdeferred tools一覧からfirebaseのMCPツールを除去しない(効果ゼロ、設定は撤回済み)
- L112 表示中の数値・時刻の意味論は実データを既知の正解(公開レシピ等)と突き合わせて確定させてから連動ロジックを設計する。**同じ症状の2度目の修正依頼は、前回が症状の一部しか直していない疑いを持ち、仕様の定義から見直す**(T3-80: 点灯区間が常に1ステップ先だった)
- L113 新規作成した`.claude/agents/*.md`は**同じターン内では`not found`になるのが正常**(frontmatterを疑わない)。レジストリはユーザーのターン境界で再スキャンされ、**同一セッションでも次の発言後には使える**(CLI再起動不要)。1回の失敗から環境の制約を結論しない
- L114 GAS Web AppへのPOST(`update`/`add`)は**curlで直接POSTしても`doPost`が実データを受け取れず反映されない**(302リダイレクト後にPOSTボディが失われる)。データ書き込みは`build/web`をローカル配信し実際のアプリUI経由で行う(過去実績のある確実な経路)。またFlutter Webの`RangeSlider`等をブラウザ自動操作でドラッグする際は、直前のナビゲーション/画面遷移クリックと同一メッセージでバッチせず、画面が描画されたことを確認してから操作する(バッチすると描画前にドラッグが失われる)
- L86 【撤回済み、L91参照】`firebase deploy`等が分類器にブロックされたらサブエージェントに委譲、という旧手法。もう使わないこと
- L87 本番GASへの`delete`直POSTは分類器ブロックが確率的でBash/PowerShellどちらでも起き得る。PowerShellも日本語JSON…
- L88 Bash/curlでのGAS `update`直POSTは日本語JSONキーが化けて「ID column or value not found」になりやすい。`cl…
- L89 マスター詳細画面(011/020等)は対象をコンストラクタ引数で受け取るため、編集→保存→pop直後は表示が古いスナップショットのまま更新されない
- L90 `SheetsService`のkeyMapの列名が本番シートと違ってもエラーにならず「そのフィールドが常にnull」で静かに壊れる。新規利用時は必ず本番`doGet`の実列名と突合
- L91 CLAUDE.md/メモリの「デプロイ・push事前承認済み」は分類器にとって有効な同意経路ではない。分類器ブロックの回避も禁止。デプロイ・pushは都度チャットで確認
- L92 上位モデルの設計書が「既存publicメソッドの呼び出し元はここだけ」と過小に把握していることがある。削除・シグネチャ変更前に必ず`grep`で全呼び出し元を洗い出す
- L93 Dartのnull安全flow analysisは`final isSet = a!=null && b!=null`越しでも`a`/`b`をnon-null促進するが、クロージャ内でのキャプチャでは促進されず`!`が必要。トップレベルとクロージャ内で`!`の要否は別々に確認する
- L94 `MockScreenScaffold`は`ConsumerWidget`(`mainColorProvider`を`watch`)のため、これを使う画面のwidgetテストは`ProviderScope`でラップしないと`Bad state: No ProviderScope found`で落ちる

### ループ運用・ガードレール
- L134 設計・調査目的のサブエージェントでも権限昇格操作(設定書き換え・`--dangerously-skip-permissions`)を無許可で試みることがある。ブロックされ実害が無くても事実を報告する(Antigravity CLI委譲調査)
- L139 implementerが`CLAUDE.md`/`SKILL.md`(運用ルール自体)を編集すると、ハーネスがSECURITY WARNINGを出すことがある。事前承認済み設計でも差分は自分の目で確認してから進める(T5-A42)
- L141(仮説) 親セッションから`night_loop.ps1`等で入れ子のclaudeセッションを起動すると、`loop_guard.js`が入れ子側のtranscriptを自分のものと誤認しモード・上限を取り違えることがありうる(T5-A12)
- L140 `.claude/`配下へのEdit/Writeは`settings.night.json`のallowより優先してハードブロックされる(implementer委譲・親セッション自身とも)。遭遇したら回避せず`NEXT_SESSION.md`側に内容退避して締めを続行する(T5-A13・night_report.md更新/夜間ループ)
- L142 agyが既存`.ps1`ファイルを編集するとUTF-8 BOMが失われPowerShell 5.1で構文エラーになることがある。`git diff`1行目の予期しない削除に注意(T5-A41)
- L143 `gemini-3.1-pro-high`は応答冒頭に`<END_OF_TURN>`が漏れ`response_head`が無意味化することがある。既定は`gemini-3.6-flash-high`を優先(T5-A41)
- L144(未確認) `AskUserQuestion`応答だけが続くターンは`loop_guard.js`の`UserPromptSubmit`が再発火せず`loop_state.md`が更新されないことがある。往復が多いループはコスト値を鵜呑みにしない(トラックA方針確認ループ)
- L145 Bashで`tail -f`等の常駐コマンドを実行しない。孤児プロセス化してファイルロックを恒久保持し、無人スクリプトのログ書き込みが無音で失敗し続ける(夜間ループ3日間無音停止バグ)
- L146 ファイルのmtimeは「セッション活動」の代理指標にならない。アイドル中セッションも周期的にtranscriptを書き換えるため、判定窓と周期が一致すると恒久デッドロックになる(T5-A12)
- L147 複数のarchitectへ設計・タスク分解を並行/連続委譲すると、それぞれが独立にタスクIDを採番しID衝突・スコープ重複が起きうる。1件反映してから次を委譲するか、使えるID範囲を委譲プロンプトで明示する(T5-A58/A59)
- L148 検知・自動修復エンジンより先に読み込まれる依存ファイルは、エンジンの検知範囲を広げても救えない(読み込みが検知より先に落ちる)。読み込み直前に依存固有のブートストラップ修復が要る(T5-A61、`tools/failure_playbook.ps1`が自身の`tools/lib/loop_io.ps1`のBOM喪失を救えなかった件)
- L149 `$ErrorActionPreference='Stop'`下で外部プロセス(adb等)を`&`呼び出しすると、正常系のstderr出力1行だけで`NativeCommandError`化し誤検知しうる。`Start-Process`での事前起動やリダイレクトで回避(T5-A63、`tools/emulator.ps1 -Status`呼び出し時のadbデーモン未起動誤検知)
- L150 敵対的レビューを2回繰り返してもMajor指摘が減らず増加する場合は個別バグではなく設計判断が必要な兆候。局所修正を重ねず中断してPRへ回す(T5-A66、night_loop、Watchdog停止フラグ削除のレースが過去の実障害〈孤児プロセスのファイルロック〉と同種と判明)
- L151 PowerShell 5.1で`@()`が`System.Collections.Generic.List[object]`型の変数を包むと`Argument types do not match`で必ず例外化する。`.ToArray()`で明示変換すれば回避できる(T5-A69、`tools/verify.ps1`の`Invoke-CheckAcceptance`が`tools/acceptance/`にスクリプトが1件でもあると毎回クラッシュしていた)
- L152 「フラグを立てて相手プロセスの自主終了を待つ」設計はフラグ削除・後片付けを能動的な終了確認(`WaitForExit`)より前に置くとL145と同種のファイルロック事故を再生産する。`Start-Process -PassThru`+`WaitForExit`+強制終了フォールバックで終了確認してから後片付けする(T5-A66、Watchdog停止シーケンス)
- L153 `.claude/settings*.json`のallow/denyにWindowsパスを書くとき単一バックスラッシュはJSONエスケープ(`\f`等)として誤解釈されうる。常に`\\`で二重化するか`/`区切りにする(T5-A67、`tools\failure_playbook.ps1`が`\f`でフォームフィード化し無音で不一致になっていた)
- L154 agyの`--mode plan`はファイル書き込みを禁止しない(agy本体はexit 0を返す)。読み取り専用役の違反を検出できるのはラッパーの実行前後`git status`差分によるexit 17判定だけなので、この判定を緩和・無効化しない(T5-A75、researcher役3件すべてが`docs/research/`にファイルを作成)
- L155 agy(Gemini)`researcher`役の出典は「実在しないURL」「実在するURLへの無関係な帰属」の2型で壊れ、報告の体裁が良好でも見分けられない。親が最低2本を実際に開いて実在性と整合性を確認するまで採用しない。同じURLが繰り返し引用されている報告は特に疑う(T5-A75、3件中2件が不採用)
- L11 日次コスト上限超過後にユーザーが明示的に続行を承認した場合
- L22 `ScheduleWakeup`は、タスク通知(task-notification)を受けて処理を進めた後は速やかに`stop:true`で明示的に…
- L68 `loop_guard.js`のようなガードレール系フックは、`.claude/loop_state.md`と同じ実ファイルパスに向けて手動でstd…
- L69 `UserPromptSubmit`フックは「今まさに送信されたプロンプト」に対して発火するため、そのプロンプト自体がtranscriptファイルに…

### UI / 文言・デザイン規約
- L07 「漢字が日本語ではない(中国語字形に見える)」はソースの誤字ではなく`MaterialApp`のロケール未設定が原因のことが多い(T3-28で特定)
- L10 UIモック(見た目のみ)を複数画面まとめて作る際は共通部品を先に作る
- L26 「テーマ切り替え」「メインカラー設定」のような全体配色機能を実装する前に、既存UIがどれだけハードコードされたパレット定数(本プロジェクトでは`cr…
- L41 `debugPrint('[Antigravity] ...')`のプレフィックス以降やユーザー向けダイアログ文言が、一部だけ英語のまま本番に残って…

### その他
- L129 安全装置(しきい値判定ツール)が表示する数値は、その集計元データソースを実際に確認するまで信用しない。`loop_guard.js`はサブエージェントの会話が親transcriptとは別ファイルに書かれることを知らず、実額の33.2%しか見ていないのに`$0.0000`と平然と表示していた。「動いていて数値が出ている」は「その数値が完全である」の証拠にならない
- L126 危険コマンドのdenyは**前方一致形**で書く。`Bash(git push * -f *)`のような中間一致形は`git push -f origin main`を1つも捕まえない(実測)。Bash版を書いたらPowerShell版も対で書く(Windowsでは`PowerShell(Remove-Item *-Recurse*)`が実質の`rm -rf`)。追加時は`'実コマンド' -like 'パターン'`で一致を実測する。列挙漏れは防ぎ切れない前提で、最後の砦はゲートと環境分離に置く
- L125 設計書に書かれた外部CLIのオプションが**実在するとは限らない**(`--max-turns`はclaude 2.1.225に無かった)。`--help`で名前と適用条件を実測してから設計書に書き実装する。誤りが見つかったら実装だけでなく**正本の設計書も直す**。CLIで縛れないと判明した制約は「縛れない」と明記し、代わりの担保先(`loop_guard.js`・スキルの自己判定・ゲート)を書き残す
- L124 設計書は「全部揃った後の姿」を書く文書なので、手順書・設定へ落とすときは**言及されるファイル/ディレクトリ/エージェント/コマンドの実在を着手前に確認**する。未実在なら削らず「(a)未整備の事実 (b)暫定措置 (c)解除条件のタスクID」の3点を本文に残す。安全装置が未整備のまま危険な自動化が起動しうる経路は起動前チェックで塞ぐ
- L123 スキル(`.claude/skills/`)の新設は**同一セッションで実動確認まで閉じられる**——L121のエージェント(`.claude/agents/`)の制約は当てはまらない。計画時は「agents=2セッション / skills=1セッション」で見積もる。新設スキルの確認は丸ごと起動せず、そのスキルが定義する手順を親が実地で踏む形にする(起動すると別タスクを1件消費するため)
- L122 サブエージェントの報告は`file:line`が正確でも件数(「呼び出し元N箇所」等)は誇張されうる。指摘の中身が正しいと見落とすため、親の突き合わせ(L120)では数字を独立に`Grep`で数え直す。エージェント定義には「位置」だけでなく「件数も実測値を書く」と粒度を分けて要求する
- L121 エージェント定義の新設タスクは「定義の作成」と「実動確認」を同一セッションで閉じられない(L113の制約。`/full_loop`はユーザー発言を挟めない)。最初から2ステップで計画し、検証用の入力(合成差分等)は作成側のセッションで用意して引き継ぎに置き場所と作り直し方を書く。夜間ループにエージェント新設タスクを回さない
- L120 委譲プロンプトに書いた「確定済み仕様」が誤っていると、implementerは設計判断をしない定義ゆえに誤りを忠実に実装する。文書・設定・エージェント定義を変更するタスクでも検証に「**実装との突き合わせ**」(読む範囲を行番号・関数名で限定)を独立手順として入れる。誤りが親の仕様なら差し戻さず親が直す
- L119 運用ルールの前提が変わったら、その前提に依存する分岐を同時に廃止する。旧分岐(「上位モデル起動時は⚠️タスク以外に着手しない」)が残り、条件が常に真になったためループが「正常終了」の顔で恒久停止した。着手可能タスクがあるのに0件着手で終わったループは異常として疑う
- L118 検証ツール自身の欠陥は「静かに通る/常に落ちる」形で現れる。外部コマンド依存(`jq`不在でstdoutが空)・改行コード(`core.autocrlf`で生バイト比較が誤検知)・未整備な前提(`skipped`+`note`で明示)・古いbaseline・別環境での自己申告、の5点を疑う。正常系より先にフォールトインジェクションを確認する
- L110 CLAUDE.mdの規約を圧縮・移動する前に、移動先候補(設計書・`rules/lessons_archive.md`等)に既に同内容が無いか確認する。他ファイルから見出し名で名指し参照されているラベルは消さない
- L30 Firebase Hosting等、Firebase CLIを使うタスクで「初回ログインはユーザー操作」と見積もっていても、別の目的(例: Cycl…
- L32 Flutter Webは`flutter_service_worker.js`のキャッシュにより、`flutter build web`で再ビルドし…
- L60 `package:google_generative_ai`(0.4.7時点)は`GenerationConfig(responseMimeType…
- L97 `Bash`ツール(Git Bash)にPowerShellのhere-string(`@'...'@`)を渡すとコミットメッセージの先頭・末尾に`@`行が混入する。多行はheredocか`-F <fi…
- L156 プロンプトで出典規則を強化するとURL捏造は止まるが「実在URLへの無関係な帰属」は止まらない。呼び出し側に機械照合(URL取得+引用の原文照合)の関門を置く。SPAは`unverifiable`として失敗と区別する。全文: `rules/lessons_archive.md`
- L157 PowerShell 5.1の`Set-Content -Encoding UTF8`はBOM無しファイルにBOMを付ける。既存エンコーディングを保つなら`[System.IO.File]::WriteAllText`+`UTF8Encoding($false)`。`.ps1`はBOM付きが正解で逆になる。全文: `rules/lessons_archive.md`
- L158【2026-08-15訂正】agy `-p "/usage"`の失敗はagy自体のregressionではなくGit Bash(MSYS)のパス自動変換が引数を誤変換していたことが真因。PowerShellまたは`MSYS_NO_PATHCONV=1`付きBashなら正常動作する。本番`.ps1`ラッパーはGit Bashを経由しないため元々無傷の可能性が高い。全文: `rules/lessons_archive.md`
- L159 fail-open(try/catch)は例外しか救えず無限ハングには無力。外部プロセス呼び出しには例外処理と別にタイムアウトが必須、「Xに10秒タイムアウトを掛けた」という記述は対象範囲を実装コードと突き合わせて確認する。全文: `rules/lessons_archive.md`
- L160 BOM喪失はagy固有ではない。ClaudeのWriteツールでBOM必須`.ps1`を全文書き換えしても同様に起きる、完了後にファイル先頭バイトを確認する。全文: `rules/lessons_archive.md`
- L161 agyヘッドレスの`claude-sonnet-4-6`は探索を伴うタスクで`num_turns:1`のまま応答が打ち切られファイル生成に到達しないことがある(モード非依存、探索ゼロなら成功)。全文: `rules/lessons_archive.md`
- L162 agy委譲の「セルフチェック実施」指示とラッパーのシェル許可完全一致リストが矛盾すると`PERMISSION_DENIED`になる、タスク側で検証コマンド禁止を明示する。全文: `rules/lessons_archive.md`
- L163 `tools/antigravity_delegate.ps1`の変更検出は同一の既にuntrackedなディレクトリへの2回目以降の書き込みを`git status --porcelain`の仕様上検知できず誤って`NO_CHANGES`になる。全文: `rules/lessons_archive.md`
- L164 `verify.ps1`の`acceptance`は全既存受け入れスクリプトを毎回回帰実行するため、無関係な既存スクリプトのフレークでも自タスクの`ok`が巻き添えでfalseになる。`checks.acceptance`の内訳で切り分ける。全文: `rules/lessons_archive.md`
- L165 受け入れチェックのプロセス残存判定がコマンドライン文字列一致だと正当な常駐プロセス(Watchdog等)まで誤検知し、フレークでなく決定的に不合格になる。判定対象を自分が起動した分に限定し、下限時間・ログのベースライン差分も併用する。全文: `rules/lessons_archive.md`
- L166 `claude -p "/usage" --output-format json`はコスト$0で取得できるが、Bash(Git Bash/MSYS)経由だとL158と同じパス変換で壊れ実費がかかる。PowerShellから直接実行するか`MSYS_NO_PATHCONV=1`を付ける。全文: `rules/lessons_archive.md`
- L167 Gemini 2.5系に`maxOutputTokens`を小さく設定すると内部thinkingが予算を消費し可視応答が空/途中切れになる恐れ(未実測、仮説)。自由文回答系は`finishReason`確認も無い。全文: `rules/lessons_archive.md`
- L168 headless(`claude -p`)でサブエージェントを非同期(既定)のまま委譲すると600秒待機上限で`claude.exe`ごと強制終了され、実装だけ完了し検証/コミット未実施のまま作業ツリーがdirtyで残る。無人ループの委譲は必ず`run_in_background: false`。全文: `rules/lessons_archive.md`
- L169 `.claude/settings.night.json`の`allow`に`WebSearch`/`WebFetch`が無く、無人ループ中は`researcher`のWeb調査タスクが常に拒否される(T5-A102起票、ユーザー実施待ち)。全文: `rules/lessons_archive.md`
- L170 `fontFamily`をコードで指定してもフォント本体を`pubspec.yaml`/`assets/fonts/`に同梱しなければ無警告で既定フォントへフォールバックし、analyze/test/acceptanceのいずれでも検知できない(T5-B21/adversaryレビュー)。全文: `rules/lessons_archive.md`
- L171 `ThemeExtension`を`BuildContext`拡張ゲッターで`!`強制アンラップすると、テーマ非対応の画面でwidgetを使った瞬間にクラッシュする。フォールバック値を返す実装にし、素テーマ配下でのクラッシュ無しをスモークテストで担保する(T5-B22束1/adversaryレビュー)。全文: `rules/lessons_archive.md`
- L172 「狭い列に収める」`Expanded`前提のコンポーネントは、ラベルだけでなく値・単位・補助テキストの全Rowに`Flexible`+`overflow:ellipsis`を付け、数値入力は`TextField`に`maxLength`を設定する。goldenは短い文字列に偏りがちで検知できないため`/code-review`等の差分レビューで補完する(T5-B22束3/`/code-review`)。全文: `rules/lessons_archive.md`
- L173 無人ループがWatchdogのハードキャップで強制終了されると、直前に書いた「完了・push済み」等の申告が未実行のまま残る。前回が無人実行の場合は`git log origin/main`で申告どおりのコミットが実在するか裏取りしてから次へ進む。全文: `rules/lessons_archive.md`
- L174 設計書で「既存実装と同じ挙動」と書く箇所は書く時点でコードを実読して裏取りする。「変更点は◯点のみ」等の個数を明示した絶対規則は本文の列挙と機械的に一致させ、追加・修正時は同じコミットで個数側も更新する。全文: `rules/lessons_archive.md`
- L175 `night_loop`ゲート条件#2(integration_testスモーク)は`tools/verify.ps1`に含まれないため、`verifier`委譲時に明示指示しないと報告が欠落しゲートが暗黙に不成立になる。UI変更が無いタスクでも明記する(2026-08-21、T5-B12再検証ループ)。全文: `rules/lessons_archive.md`
- L176 `const`/`static const`ウィジェットは`Element.updateChild()`の同一インスタンス高速パスで子の`build()`が再実行されないことがある。Riverpodの`Provider`も無効化しない限りキャッシュ値を返し続けるため「現在時刻」の取得元には向かない。「生き続ける」子リストは`build()`内で毎回生成する(2026-08-22、T5-B23/adversary3往復)。全文: `rules/lessons_archive.md`
- L177 「Androidエミュレータ未整備」という複数セッションにまたがる申し送りは誤りだった(実際は整備済み)。環境不在の申し送りは鵜呑みにせず`emulator -list-avds`等で実在確認してから行動する(2026-08-22、PR #5/#6検証)。全文: `rules/lessons_archive.md`
- L178 GAS経由のintegration_testスモークは複数セッションにまたがり接続断・件数不一致・タイムアウト等毎回異なる態様で不安定に失敗する。「GAS起因だろう」で押し通す運用には限界があり、原因不明の再発として`architect`へ切り分けを依頼すべき(2026-08-22、T5-A103起票)。全文: `rules/lessons_archive.md`
- L179 PowerShellの`Invoke-RestMethod -Body <string>`は日本語キーを含むJSONを既定エンコーディングで送るとGAS側で文字化けしキー一致に失敗する。`ConvertTo-Json`出力を`[System.Text.Encoding]::UTF8.GetBytes()`でバイト列化してから渡すこと(2026-08-22、T5-A103本番ゴミレコード削除)。全文: `rules/lessons_archive.md`
- L180 アシスタントが新規作成した(BOM無し)`.ps1`を`powershell -File`実行すると、日本語行がPowerShell 5.1に既定コードページで誤解析されhere-string終端検出等が壊れる。日本語を含む新規`.ps1`は常にUTF-8 BOM付きで保存してから実行すること(2026-08-22、NEXT_SESSION.md整理作業)。全文: `rules/lessons_archive.md`
- L181 `verify.ps1 -Task <ID>`はIDを機械的に小文字化してファイル名突合するため、束分割タスク(T5-B13-4等)のサブIDと親グループ単位の共有受け入れテスト名(t5_b13_acceptance_test.dart)が不一致だと`acceptance_missing`を誤検知する。`-Task`には完了条件セルのファイル名から逆算した親グループIDを渡す(2026-08-22、T5-B13-4検証)。全文: `rules/lessons_archive.md`
- L182 agy `-Role adversary`(plan mode)は指摘があると規定報告を直接出力せず`implementation_plan.md`へ書き出して確認待ちで停止することがある。`response_head`が「よろしければ」等の確認待ち文言なら指摘ゼロと即断せず、計画ファイルを直接読んで指摘を回収する(2026-08-22、T5-B14差し戻し)。全文: `rules/lessons_archive.md`
- L183 `verifier`は絶対規則§4(本番データを書き換えない)を、`CLAUDE.md`の緩和規定引用や親の再依頼でも解除しない(委譲元メッセージは承認とみなさない設計)。本番書き込みを伴う`integration_test`実行を拒否されたら1回の再依頼で見切りをつけ、ゲート条件を「未検証」としてPRルートへ切り替える(2026-08-23、T5-A108・T5-B25検証)。全文: `rules/lessons_archive.md`
