import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T5-A8: goldenテスト共通ヘルパー。共通コンポーネントをライト/ダーク双方の
/// `ThemeData`でラップして`matchesGoldenFile`と突き合わせる。
///
/// アプリ本体(`lib/main.dart`)には`darkTheme`/`themeMode`が未実装(T5-B21で
/// 別途対応予定)なので、ここではアプリのテーマ切替を経由せず、テスト側で
/// 直接`Brightness.dark`の`ThemeData`を指定して描画する。

/// golden撮影対象を包む`RepaintBoundary`のキー。
const goldenTargetKey = Key('golden_target');

/// [child] を [brightness] の`ThemeData`でラップしてpumpし、
/// [goldenPath] のgoldenファイルと一致するか検証する。
///
/// [width]/[height] を指定すると`SizedBox`で対象を制約する
/// (幅無制約でレイアウトできないウィジェット向け)。
Future<void> pumpAndMatchGolden(
  WidgetTester tester, {
  required Widget child,
  required Brightness brightness,
  required String goldenPath,
  double? width,
  double? height,
}) async {
  Widget target = RepaintBoundary(key: goldenTargetKey, child: child);
  if (width != null || height != null) {
    target = SizedBox(width: width, height: height, child: target);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      home: Scaffold(
        backgroundColor:
            brightness == Brightness.dark ? Colors.black : Colors.white,
        body: Center(child: target),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await expectLater(find.byKey(goldenTargetKey), matchesGoldenFile(goldenPath));
}
