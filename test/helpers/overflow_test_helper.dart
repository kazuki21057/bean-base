import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T5-A8(`docs/android_release/検証強化設計.md` D-4節): overflow判定を
/// エミュレータのスクリーンショット目視ではなくwidget testで機械判定するための
/// 共通ヘルパー。`FlutterError.onError`を差し替え、
/// `A RenderFlex overflowed`を含むエラーが飛んだら検出リストに積む。
///
/// widget test内でoverflowが発生しても`flutter test`はデフォルトでは
/// テストをfailさせない(`FlutterError.onError`は既定でコンソールへの
/// 出力のみ)。そのためこのヘルパーで明示的に検知・failさせる。

/// 実機解像度相当の代表的な論理サイズ(dp)。
/// 360x690: 一般的なAndroid端末の代表値
/// 411x914: Pixel系の代表値
/// 320x690: 小型端末(検証強化設計.md §Fで実際にoverflowが確認された解像度帯)
const List<Size> kOverflowCheckSizes = [
  Size(360, 690),
  Size(411, 914),
  Size(320, 690),
];

/// [widget] を [sizes] の各論理サイズでpumpし、その間に発生した
/// `A RenderFlex overflowed`を含む`FlutterError`のメッセージ一覧を返す。
/// 空リストならoverflowなし。
///
/// `pumpWidget`後に画面固有の追加操作(スクロール等)が必要な場合は
/// [onPumped] にサイズごとの追加処理を渡す。
Future<List<String>> pumpAndDetectOverflow(
  WidgetTester tester,
  Widget widget, {
  List<Size> sizes = kOverflowCheckSizes,
  Future<void> Function(WidgetTester tester, Size size)? onPumped,
}) async {
  final detected = <String>[];
  final originalOnError = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    final message = details.exceptionAsString();
    if (message.contains('A RenderFlex overflowed')) {
      detected.add(message);
    }
    // 元のハンドラ(コンソール出力等)も引き続き呼ぶ
    originalOnError?.call(details);
  };

  addTearDown(() {
    FlutterError.onError = originalOnError;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  try {
    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(widget);
      if (onPumped != null) {
        await onPumped(tester, size);
      } else {
        // 初期ロード(FutureBuilder等)が完了しレイアウトが確定するまで
        // 待つ。既定は`pumpAndSettle`(既存widgetテストの慣例、
        // `test/settings_screen_test.dart`等と同じ)。
        await tester.pumpAndSettle();
      }
    }
  } finally {
    FlutterError.onError = originalOnError;
  }

  return detected;
}

/// [detected] が空であることを検証する(overflowが1件も無いこと)。
void expectNoOverflow(List<String> detected) {
  expect(
    detected,
    isEmpty,
    reason: 'Overflowを検出しました:\n${detected.join('\n---\n')}',
  );
}
