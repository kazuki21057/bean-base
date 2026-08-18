import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T5-A8: goldenテスト共通ヘルパー。共通コンポーネントをライト/ダーク双方の
/// `ThemeData`でラップして`matchesGoldenFile`と突き合わせる。
///
/// アプリ本体(`lib/main.dart`)には`darkTheme`/`themeMode`が未実装(T5-B21で
/// 別途対応予定)なので、ここではアプリのテーマ切替を経由せず、テスト側で
/// 直接`Brightness.dark`の`ThemeData`を指定して描画する。
///
/// ベースラインはWindows環境で生成する(T5-A8、OS間のテキスト描画差のため)。

/// goldenのベースライン画像はWindows環境で生成したものに固定する(T5-A8)。
/// テキストのラスタライズ結果がOSで異なる(図形描画はOS間で一致)ため、
/// Windows以外ではgolden比較をスキップする。
/// 再生成は`rules/verification.md`の運用ルールに従い、ユーザーの明示指示がある場合のみ。
final bool skipGoldenOnNonWindows = !Platform.isWindows;

/// golden撮影対象を包む`RepaintBoundary`のキー。
const goldenTargetKey = Key('golden_target');

/// [child] を [brightness] の`ThemeData`でラップしてpumpし、
/// [goldenPath] のgoldenファイルと一致するか検証する。
///
/// [width]/[height] を指定すると`SizedBox`で対象を制約する
/// (幅無制約でレイアウトできないウィジェット向け)。
/// [theme] を渡すと、既定の素の`ThemeData(brightness:)`の代わりにそれを使う。
/// 公開版コンポーネント(T5-B22)の`buildPublicTheme(Brightness)`をそのまま
/// 渡すことを想定した拡張(既存呼び出し側は[theme]省略で従来どおり動作する)。
Future<void> pumpAndMatchGolden(
  WidgetTester tester, {
  required Widget child,
  required Brightness brightness,
  required String goldenPath,
  double? width,
  double? height,
  ThemeData? theme,
}) async {
  Widget target = RepaintBoundary(key: goldenTargetKey, child: child);
  if (width != null || height != null) {
    target = SizedBox(width: width, height: height, child: target);
  }

  final effectiveTheme = theme ?? ThemeData(brightness: brightness, useMaterial3: true);

  await tester.pumpWidget(
    MaterialApp(
      theme: effectiveTheme,
      home: Scaffold(
        backgroundColor: theme != null
            ? effectiveTheme.scaffoldBackgroundColor
            : (brightness == Brightness.dark ? Colors.black : Colors.white),
        body: Center(child: target),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(goldenTargetKey), matchesGoldenFile(goldenPath));
}
