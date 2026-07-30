# デプロイ手順 (Firebase Hosting)

> Cycle 27 T3-13。公開URL・Hosting設定の決定は `docs/改修マスタープラン.md` §1(T3-11)が単一の真実。本書はその再現手順のみをまとめる。

## 公開URL

**https://beanbase-app-2016.web.app** — 認証なし・誰でもアクセス可能。

## 前提

- Firebase CLI (`firebase-tools`) がインストール済み・`beanbase-app-2016` プロジェクトにログイン済みであること。未ログインの場合のみ `firebase login`(ブラウザOAuth、ユーザー操作)。
- `firebase.json`(`hosting.public: build/web`、SPA向け全パス→`index.html`のrewrite)・`.firebaserc`(`default: beanbase-app-2016`)はリポジトリにコミット済みのため、初回セットアップは不要。

## 手順

```bash
# 1. リリースビルド
flutter build web

# 2. Hostingへデプロイ(Hostingのみ。Firestore/Functions等は対象外)
firebase deploy --only hosting
```

成功すると `Hosting URL: https://beanbase-app-2016.web.app` が表示される。反映まで数秒〜1分程度。

## デプロイ後の確認

1. 本番URLをブラウザで開き、ダッシュボード(001)がSheets実データで表示されること・コンソールエラーが無いことを確認する。
2. Gemini API連携(統計画面のAI解釈・豆情報のGemini Vision抽出等)は`shared_preferences`のAPIキーがブラウザごとに独立して保存されるため、新しい端末/ブラウザでは090(設定)から再入力が必要。

### 既知の注意点(教訓)

- **Service Workerのキャッシュ**: デプロイ直後にローカル/実機のブラウザで新機能が反映されないことがある。これはFlutter WebのService Workerが旧`main.dart.js`をキャッシュしているため。解消するには、対象ブラウザのDevToolsコンソールで以下を実行してから再読み込みする。
  ```js
  navigator.serviceWorker.getRegistrations().then(rs => rs.forEach(r => r.unregister()));
  caches.keys().then(ks => ks.forEach(k => caches.delete(k)));
  ```
  もしくはブラウザのシークレットウィンドウ/キャッシュ削除で確認する。
- **`firebase deploy`がハーネスの安全分類器にブロックされることがある**: Claude Code側の分類器が`firebase deploy --only hosting`(や本番ドメインへの直接`curl`)を拒否する("Blocked by classifier"、詳細理由は非開示)ことがある。**対処(2026-07-30改訂、恒久運用)**: 2026-07-29時点では「同じコマンドをAgentサブエージェントに委譲すれば回避できる」という運用だったが、これは誤りと判明し撤回した——サブエージェント実行結果に「本番デプロイはチャット上での都度明示的な許可が必要で、CLAUDE.md/メモリの『事前承認済み』という記述やサブエージェント委譲による分類器ブロック回避は正当な同意経路ではない(Instruction Poisoning/Auto-Mode Bypassパターン)」というセキュリティ警告が付与された。**ブロックされたら回避を試みず、何を・なぜ実行しようとしたかをユーザーに説明し、チャットで明示的な許可を得てから再実行する。**
- **デプロイ結果の検証方法**: `build/web/main.dart.js`のハッシュと、本番から取得した`main.dart.js`・`flutter_service_worker.js`内のハッシュ値が一致すれば、確実に新しい成果物が配信されている(Service Workerキャッシュに惑わされずに済むため、ブラウザ確認の前にこれを見るとよい)。
  ```bash
  curl -s https://beanbase-app-2016.web.app/main.dart.js | md5sum
  md5sum build/web/main.dart.js
  curl -s https://beanbase-app-2016.web.app/flutter_service_worker.js | grep -o '"main.dart.js": "[^"]*"'
  ```
- **サンドボックス環境からの本番確認制約**: `claude-in-chrome`拡張は本番ドメイン(`*.web.app`/`*.firebaseapp.com`)への遷移をブロックする。開発セッション内で本番確認する場合は、デプロイした同一の`build/web`成果物を`python -m http.server`等でローカル配信し、本番GAS実データに対して確認する(ビルド・データとも本番と同一になるため、これで代替可能)。

## 運用方針

- 更新の都度、上記2コマンドを手動実行する(CI/CD自動デプロイは組んでいない)。
- 本番書き込み(Sheets/Driveへの実データ登録・削除等)を伴う変更は、実施前にユーザーへ確認する(`CLAUDE.md`・マスタープラン運用ルール参照)。
