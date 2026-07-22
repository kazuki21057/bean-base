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
- **サンドボックス環境からの本番確認制約**: `claude-in-chrome`拡張は本番ドメイン(`*.web.app`/`*.firebaseapp.com`)への遷移をブロックする。開発セッション内で本番確認する場合は、デプロイした同一の`build/web`成果物を`python -m http.server`等でローカル配信し、本番GAS実データに対して確認する(ビルド・データとも本番と同一になるため、これで代替可能)。

## 運用方針

- 更新の都度、上記2コマンドを手動実行する(CI/CD自動デプロイは組んでいない)。
- 本番書き込み(Sheets/Driveへの実データ登録・削除等)を伴う変更は、実施前にユーザーへ確認する(`CLAUDE.md`・マスタープラン運用ルール参照)。
