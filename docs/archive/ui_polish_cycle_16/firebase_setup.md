# Firebase 導入手順書

BeanBase 2.0 に Firebase Storage (画像保存機能) を導入するための手順です。
以下のコマンドを **ターミナル (PowerShell または CMD)** で順番に実行してください。

## 前提条件
- Google アカウントを持っていること。
- Node.js がインストールされていること (推奨)。

## 手順 1: Firebase CLI のインストールとログイン

1.  **Firebaseツールのインストール**:
    ```powershell
    npm install -g firebase-tools
    ```
    ※ Node.jsがない場合は、[バイナリ版](https://firebase.google.com/docs/cli?hl=ja#install-windows) を使用するか、`dart pub global activate flutterfire_cli` だけでも進める場合がありますが、通常は `firebase-tools` が必要です。

2.  **ログイン**:
    ```powershell
    firebase login
    ```
    ブラウザが開くので、Googleアカウントでログインして許可してください。

## 手順 2: FlutterFire CLI のインストール

Flutter プロジェクトと Firebase を紐付けるツールをインストールします。

```powershell
dart pub global activate flutterfire_cli
```

※ パスが通っていないという警告が出た場合、指示通りにパスを通すか、再起動が必要な場合があります。

## 手順 3: プロジェクトの作成と設定 (Configure)

BeanBase2.0 のルートディレクトリ (`C:\src\Antigravity\BeanBase2.0`) で実行してください。

```powershell
flutterfire configure
```

コマンドを実行すると、対話形式で以下の質問がされます：

1.  **Select a Firebase project to configure your Flutter application with**:
    -   `<create a new project>` を選択し、Enter。
    -   プロジェクト名を入力 (例: `beanbase-app-2026`)。
        -   ※ ユニークな名前である必要があります。

2.  **Which platforms should your configuration support?**:
    -   `android`, `ios`, `web` (および `windows` もあれば) が選択されていることを確認し、Enter。

処理が完了すると、`lib/firebase_options.dart` というファイルが自動生成されます。これがあれば成功です。

## 手順 4: Firebase コンソールでの設定 (ブラウザ)

1.  [Firebase Console](https://console.firebase.google.com/) にアクセスし、作成したプロジェクトを開きます。
2.  **Storage** (または Build > Storage) を選択します。
3.  **「始める (Get started)」** をクリックします。
4.  **「テストモードで開始する (Start in test mode)」** を選択して次へ。
    -   ※ 開発中は誰でも読み書きできるようにしておきます（後でルールを変更します）。
5.  リージョン (保存場所) を選択して完了 (例: `asia-northeast1` など、またはデフォルト)。

## 手順 5: 本実装へ

上記が完了したら、教えてください。アプリ側のコード (`pubspec.yaml` 等) の変更作業に入ります。
