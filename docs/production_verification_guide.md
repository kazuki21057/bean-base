# 本番環境 検証要領(下位モデル向け)

> 2026-08-03 作成(`/full_loop`(Opus)、ユーザー指示「上位モデルで確認するとトークン消費が激しいため、下位モデルで確認するための要領を作成して」)。
> **この文書は Sonnet 5 が単独で本番検証を完走できるように書かれている。** 上から順にそのまま実行すればよい。
> 対象は **本番 https://beanbase-app-2016.web.app** であって `localhost` ではない。両者は同じ `build/web` を配信していても **Origin / Referer が違うため外部リソース(Google Drive画像・CanvasKitのフォントCDN)の挙動が変わる**。2026-08-03の棚卸しは localhost で行ったため、描画系の指摘(T3-75a / T3-75e)は**本番では再現しない可能性がある**。

---

## 0. この検証の目的

1. 本番URLで実際に**画面が正しく描画され**、**画面遷移と操作が意図どおり動く**ことを確認する。
2. 本番Sheetsの**データが正しく表示されている**ことを確認する(データ側の異常は `localhost` でも本番でも同じなので、重い本番ブラウザ確認に頼らず §3 のAPI突合で済ませる)。
3. 見つかった不具合を `docs/改修マスタープラン.md` §3 に起票する。**この検証タスク中はコードを直さない**(直すのは別ループ)。

---

## 1. 大前提: トークンを食わないための鉄則

このアプリは **Flutter Web (CanvasKit)** なので、DOMにテキストが無い。つまり:

- `get_page_text` は **必ず失敗する**(`No text content found`)。呼ぶだけ無駄なので**呼ばない**。
- 画面の内容を知る手段は実質**スクリーンショットだけ**。スクリーンショット1枚は約1.5kトークンで、**以後そのセッションの全リクエストに乗り続ける**。

したがって:

| ルール | 内容 |
|---|---|
| **R1** | スクリーンショットは**1画面につき1枚**。撮り直しは「明らかに描画途中だったとき」だけ。 |
| **R2** | 全画面は撮らない。**§4のチェックリストに挙げた画面だけ**撮る(全部で10枚以内)。 |
| **R3** | 部分確認は `computer zoom`(領域指定)を使う。全画面より小さく済む。 |
| **R4** | 「要素があるか」だけ知りたいときは `find`(テキスト返却・軽い)を使う。 |
| **R5** | 外部リソースの成否など**数値で答が出るもの**は `javascript_tool` で調べる。スクリーンショットで判断しない。 |
| **R6** | `read_console_messages` は**必ず `pattern` を指定**する。無指定だと `sheets_service.dart` のDEBUGログ(全シートの生データ)が数万文字流れ込む(これ自体がT3-75f)。 |
| **R7** | ブラウザツールは1メッセージにまとめて複数呼ぶ(`browser_batch` があるなら使う)。1ツール1リクエストの直列実行がコストの主因。 |
| **R8** | このセッションでは **`flutter analyze` / `flutter test` / `flutter build web` を実行しない**(コードを変えないので不要)。 |

---

## 2. 手順A: 本番URLを開く

### A-1. まず素直に開いてみる

```
mcp__claude-in-chrome__tabs_create_mcp
mcp__claude-in-chrome__navigate  url: https://beanbase-app-2016.web.app
```

`docs/deploy.md` には「`claude-in-chrome` 拡張は `*.web.app` への遷移をブロックする」と書かれているが、**これは2026-07時点の観測であり毎回そうとは限らない**。まず試すこと。

### A-2. ブロックされたら

`Permission denied` / `Blocked` 等が返ったら、**回避策を自分で探さない**(サブエージェント委譲等での回避は禁止、`rules/lessons_archive.md` L91)。以下をユーザーに依頼する。**依頼時は `PushNotification` でも通知する**(`CLAUDE.md`§日次改修ループ運用ルール)。

> 本番URL `https://beanbase-app-2016.web.app` へのアクセスが拡張機能にブロックされました。Chromeの拡張設定でこのドメインを許可していただけますか?(Claude in Chrome の拡張アイコン → サイトへのアクセス許可)

許可が下りたら A-1 をやり直す。**どうしても許可が得られない場合のみ**、`localhost` 配信での代替確認に切り替え、その旨を報告に明記する(「本番URLでは未確認」と書く)。

### A-3. 開けたら最初にやること(Service Workerキャッシュ排除)

古い `main.dart.js` を掴んでいると検証が無意味になる。`javascript_tool` で:

```js
const rs = await navigator.serviceWorker.getRegistrations();
await Promise.all(rs.map(r=>r.unregister()));
const ks = await caches.keys();
await Promise.all(ks.map(k=>caches.delete(k)));
JSON.stringify({unregistered: rs.length, cachesDeleted: ks.length})
```

その後 `navigate` で再読み込みし、**7秒 `wait`** してから最初のスクリーンショットを撮る(CanvasKitの初回描画は遅い)。

### A-4. 配信物が最新か確認(スクリーンショット不要・軽い)

```bash
curl -s https://beanbase-app-2016.web.app/flutter_service_worker.js | grep -o '"main.dart.js": "[^"]*"'
md5sum build/web/main.dart.js
```

一致すれば「本番 = ローカル `build/web`」。**不一致なら未デプロイの差分があるということなので、その事実を報告に書く**(検証結果の解釈が変わる)。

---

## 3. 手順B: データ突合(ブラウザ不要・最優先でここから)

**ブラウザより先にこれをやる。** データの異常はブラウザを開かなくても分かるうえ、圧倒的に安い。

```bash
GAS='https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec'
cd <scratchpad>
for s in coffee_data bean_master methods_master pouring_steps mill_master dripper_master \
         filter_master bean_purchases store_master origin_master analysis_history recipe_suggestions; do
  curl -sL "$GAS?sheet=$s" -o "prod_$s.json"
done
```

> **GAS URLは `lib/services/sheets_service.dart:17` の `kGoogleSheetsApiUrl` が正本**。上の値と違っていたらそちらを使う(GAS再デプロイでURLが変わる、L02/L36)。

取得したJSONは**そのまま `Read` しない**(`coffee_data` だけで125KBある)。必ずPythonで集計して**要約だけ**を出力する。Windowsでは文字化けするので `sys.stdout.reconfigure(encoding='utf-8')` と `PYTHONIOENCODING=utf-8` を必ず付ける(L58)。

チェック項目(2026-08-03に実施済みの内容。差分だけ見ればよい):

| # | 内容 | 2026-08-03時点の結果 |
|---|---|---|
| B1 | `coffee_data` の `ミル`/`ドリッパー`/`フィルター`/`抽出方法`/`産地ID` が各マスターのIDで解決できるか | 未解決0件 ✅ |
| B2 | `coffee_data.豆名`(実体は豆ID)が `bean_master` で解決できるか | **1件未解決**(記録ID `1784633291939` → 豆ID `1784633291938` が存在しない)= T3-75c |
| B3 | 全列が空の行が無いか | **2件あり** = T3-75c |
| B4 | `bean_master` の `産地ID`/`購入店ID` が解決できるか | 未解決0件 ✅(空欄はあるが不正値なし) |
| B5 | 必須項目が欠けた記録が無いか(豆ID空・湯温0など) | **記録ID `1785746695316` が豆ID空・湯温0・蒸らし時間0** = T3-75b |
| B6 | マスターにテストデータが残っていないか | `filter_master` の `Test Filter`(ID `1771594821407`)= T3-75d |
| B7 | 残豆量の分母(`初期購入量(g)` / `在庫基準量(g)`)と使用量合計の整合 | Youth ケニア: 初期35g<使用60g、スイートイエロー: 初期100g<基準135.5g = T3-75g |

**これらはGAS(本番Sheets)を直接見ているので、localhostだろうが本番だろうが結果は同じ。再確認しても新情報は出ない。** 前回から**新しく増えた異常が無いか**だけ見ればよい。

---

## 4. 手順C: 本番ブラウザでの画面・遷移・挙動確認

### C-0. 撮る画面(これで全部。10枚以内)

| # | 画面 | 到達方法 | 見るところ |
|---|---|---|---|
| C1 | 001 ダッシュボード | 初期表示 | おすすめレシピ・残豆量・直近5件が出ているか。**日本語が豆腐(⊠)になっていないか** |
| C2 | 002 抽出履歴(リスト) | 左レール2番目「履歴」 | 件数・並び順・豆名が出ているか |
| C3 | 003 抽出履歴(詳細) | C2の**最上段の行をタップ** | ダッシュボードで豆名が空だった 2026/08/04 の記録。全項目が出るか |
| C4 | マスター管理 | 左レール3番目「マスター」 | 7項目のメニューが出るか |
| C5 | 010 豆管理(カード) | C4→「豆管理」 | **画像が出ているか(最重要)**・残量%・0%切替トグル |
| C6 | 011 豆管理(詳細) | C5の任意カードをタップ | 画像・全情報・関連履歴5件 |
| C7 | 013/016 ドリッパー/フィルター管理 | C4→各項目 | **画像が出ているか**(豆以外のマスターでも要確認) |
| C8 | 040 統計 | 左レール5番目「統計」 | グラフが描画されるか・PCA/回帰セクションが出るか |
| C9 | 030 抽出記録(新規) | ダッシュボード等の＋ | フォームが出るか。**保存はしない** |
| C10 | 090 設定 | 右上の歯車 | 一覧が出るか |

### C-1. 画面遷移・挙動のチェック(スクリーンショット無しでも判定できるものが多い)

| # | 確認内容 | 判定方法 |
|---|---|---|
| D1 | 左レール(デスクトップ≥640px)の5タブが全て切り替わる | 各タブ切替後に1枚ずつではなく、**切替直後に `find` でその画面固有の文言を探す**(例: 統計なら「主成分」)。出ればOK |
| D2 | 一覧→詳細→戻る が正しく動く | 詳細で `find`、戻る(`computer` で左上の←をクリック)後に一覧固有の文言を `find` |
| D3 | ブラウザの戻る/進む(`navigate url:"back"`)でクラッシュしない | `back` 後に `find` で画面が生きているか確認 |
| D4 | 0%表示トグル等のUI操作が即座に反映される | トグル押下後に `find` で件数が変わるか |
| D5 | 例外が出ていないか | `read_console_messages` に **`pattern: "Exception\|Uncaught\|TypeError\|Failed to load"`** を指定(R6) |
| D6 | Overflow警告(黄黒ストライプ)が出ていないか | C1〜C10のスクリーンショットを見るときについでに確認 |

> **押してはいけないもの**: 削除ボタン、保存ボタン(030の記録保存を含む)、「この条件で淹れる」。本番データが増減する。**読み取り専用で回す**。閲覧のみなら本番書き込みは発生しない。
> ナビゲーションは `computer` のクリックが効かないことがある(L80)。効かないときは**同じ操作を2回まで試し、それでも駄目なら「この画面は未確認」と報告して次へ進む**。粘らない。

### C-2. T3-75a(画像)の本番判定 — ここが今回の主目的

**localhost では画像が1枚も出なかったが、本番では出る可能性が高い**(Google Drive / lh3 は `Referer` によって挙動が変わるため)。C5・C7のスクリーンショットで画像が出ていれば **T3-75a は「localhost限定の事象」としてクローズ**してよい。

出ていない場合のみ、本番ページ上で `javascript_tool` を使い以下を実測して報告する:

```js
const id='1X0hMXXyXwm0D-HIVDSrmkGKN_UP2o4y_'; // Navy ブラジル 中浅煎りの画像
const cands=[
  'https://drive.google.com/uc?export=view&id='+id,
  'https://lh3.googleusercontent.com/d/'+id,
  'https://drive.google.com/thumbnail?id='+id+'&sz=w800',
];
const out={};
for(const u of cands){
  let f; try{const r=await fetch(u); f=r.status+'/'+r.type;}catch(e){f='THROW';}
  const im=await new Promise(res=>{const i=new Image();i.onload=()=>res('ok '+i.naturalWidth+'x'+i.naturalHeight);i.onerror=()=>res('err');i.src=u;setTimeout(()=>res('timeout'),8000);});
  out[u.slice(0,55)]={fetch:f,img:im};
}
JSON.stringify(out,null,1)
```

あわせて、アプリ自身が実際に何バイト取れているか:

```js
const e=performance.getEntriesByType('resource').filter(r=>/lh3|drive|googleusercontent/.test(r.name));
JSON.stringify({count:e.length, sizes:[...new Set(e.map(r=>r.transferSize))].slice(0,5)})
```

**判定基準**: `transferSize` が数万バイト = 画像は取れている。全て 1857 のような小さい固定値 = エラーレスポンスを掴んでいる。
参考(localhost実測、L102): `uc?export=view` は fetch/img とも失敗、`lh3` は fetch 200 だが `<img>` は onerror、`thumbnail?id=…&sz=w800` だけ `<img>` で 450x600 が読めた。

### C-3. T3-75e(漢字の豆腐化)の本番判定

CanvasKit は日本語グリフを外部CDN(`fonts.gstatic.com`)から取りに行くため、**サンドボックスのネットワーク事情で localhost だけ失敗していた可能性がある**。C1のスクリーンショットで「実験的な提案です」「予測スコア」「この産地は」が正しく読めていれば **T3-75e は localhost限定としてクローズ**してよい。

数値で確かめたい場合:

```js
const e=performance.getEntriesByType('resource').filter(r=>/gstatic|fonts|Noto/.test(r.name));
JSON.stringify({count:e.length, failed:e.filter(r=>r.transferSize===0&&r.decodedBodySize===0).length})
```

### C-4. localhost固有ではないと分かっている項目

以下は**ビルド成果物・本番データに起因するので、本番でも同じはず**。改めて確認する必要はない(確認するなら1回だけ):

- **T3-75f**(`sheets_service.dart` の `print` による生データ出力)— `read_console_messages` に `pattern: "DEBUG: Raw Body"` を指定して1件でも出れば再現確認完了。
- **T3-75b / c / d / g** — §3のデータ突合で判定済み。

---

## 5. 手順D: 報告と起票

1. **判定結果を1表にまとめる**。T3-75a〜g それぞれについて `本番でも再現` / `localhost限定(クローズ)` / `未確認(理由)` のいずれかを書く。
2. **新規に見つかった不具合**は `docs/改修マスタープラン.md` §3 の「Phase 3 追加分(2026-08-03、T3-75)」の表に行を追加する(ID は T3-75h 以降)。書式は既存行に合わせ、**再現手順・観測値・影響画面**まで書く(次のループの実装者が調査し直さずに済む粒度)。
3. **localhost限定と判定できた項目**は、該当行の状態を `⬜` から `❌(localhost限定・本番では再現せず)` に変更し、判定根拠(スクリーンショットで画像が出た、等)を1行添える。
4. `NEXT_SESSION.md` の「2. 次回の着手点」と「3. 直近の作業ログ」を更新する(作業ログは**古い節をアーカイブへ移してから**新しい節を1件だけ)。
5. commit する。**push とデプロイは実行前に必ずチャットでユーザーの明示的な許可を得る**(L91)。
6. 検証用に起動したローカルHTTPサーバがあれば止める。

---

## 6. 停止条件(`CLAUDE.md`§日次改修ループ運用ルールと同じ)

- 1ループのコストが **$24超**、ターン数 **30到達**、連続失敗 **3回** のいずれかで停止(`.claude/loop_state.md` の数値が真実。自分で数えない)。
- ブラウザツールが**同じ操作で2〜3回失敗**したら、その画面は「未確認」として先へ進む。粘ると一気にコストを食う。
- 本番URLへのアクセス許可・本番データの削除・push・デプロイなど**ユーザーの判断待ちになったら、その場で止めて `PushNotification` で通知**する。

---

## 7. 既知の環境トラブルと対処(時間を溶かさないため)

| 症状 | 対処 |
|---|---|
| ビューポートが `451x73` に固定され `resize_window` でも戻らない | `tabs_create_mcp` で**タブを作り直す**(L103) |
| `Page.captureScreenshot` がタイムアウト | 数秒待って1回だけ再試行。駄目ならタブ作り直し(L66) |
| `computer scroll` が効かない | `javascript_tool` で `flt-glass-pane` に合成 `WheelEvent` を `dispatchEvent`(L98) |
| 拡張が未接続 | ユーザーに接続を依頼(L27) |
| `navigate` の初回が `Permission denied` | 1回だけ再試行(L21) |
| 漢字が一部だけ豆腐 | 初回描画では起こりうる。**再描画後も残るかで判定**(L06) |
