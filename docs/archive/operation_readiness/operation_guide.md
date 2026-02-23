# BeanBase 2.0 運用・保守ガイド

## 1. ビルドとデプロイ

### Web版 (推奨)
ブラウザからアクセス可能にする場合、Webビルドが最も手軽です。
```bash
flutter build web --release
```
- `build/web` フォルダに出力されます。
- **ホスティング先**: GitHub Pages, Firebase Hosting, Vercel など。
- **注意**: Google Sheets API (Apps Script) のCORS設定で、ホスティング先のドメインを許可しているか確認してください（現在は `*` なので問題なし）。

### Android版 (APK)
Android端末にインストールする場合。
```bash
flutter build apk --release
```
- `build/app/outputs/flutter-apk/app-release.apk` が生成されます。
- インストールには端末の設定で「不明なソースからのインストール」を許可する必要があります。

### Windows版
Desktopアプリとして利用する場合。
```bash
flutter build windows --release
```
- `build/windows/runner/Release` フォルダ内のファイル一式が必要です。

## 2. データ管理とバックアップ

### データ保存先
現在は **Google Sheets** をデータベースとして使用しています。
- **メリット**: 無料、スプレッドシートとして直接編集・閲覧が可能、履歴機能あり。
- **デメリット**: オフラインで保存できない、API制限（大量アクセス時）。

### バックアップ運用
1. **Google Sheetsの履歴**: Google Drive上で自動的に変更履歴が残ります。定期的な手動バックアップは不要ですが、心配な場合は「ファイル > ダウンロード > Excel/CSV」でローカルに保存してください。
2. **マスターデータ**: `Beans`, `Methods`, `Grinders` などのシートは誤って削除しないよう保護設定（シートの保護）を推奨します。

## 3. 保守・トラブルシューティング

### よくあるエラー
- **ClientException: XMLHttpRequest error (Web)**
  - 原因: CORSエラーまたはネットワーク遮断。
  - 対応: 通信環境を確認。Apps ScriptのデプロイURLが正しいか、スクリプトが最新か確認。
- **No Overlay widget found**
  - 原因: Tooltip等の表示に必要な `Overlay` が見つからない。
  - 対応: コード修正済みですが、もし再発した場合は `MainLayout` 周りの構成を確認。

### 今後の拡張・メンテナンス
- **パッケージ更新**: `flutter pub upgrade` でライブラリを更新。`fl_chart` などUIライブラリは破壊的変更が多いので注意。
- **機能追加**: 新しい抽出器具や評価項目を追加する場合は、Google Sheetsの列追加と `CoffeeRecord` モデルの修正が必要です。

## 4. 推奨運用フロー
1. **記録**: 日々のコーヒー抽出をアプリから記録。
2. **分析**: 週に1回程度 `Statistics` 画面で傾向を確認。
3. **データ整理**: スプレッドシート上で不要なログの整理（行削除）や、コメントの追記を行ってもアプリに反映されます。
