// T5-B21: 公開版(Android)のテーマ組み立て。
//
// 正本は docs/android_monetization/デザイン方針.md §6・§7。
// `buildPublicTheme(Brightness)`でライト/ダークそれぞれの`ThemeData`を構築する。
// `CardTheme`/`InputDecorationTheme`等の細かいコンポーネントテーマはT5-B22以降で拡張する
// (§7の表: 本タスクでは必須ではない)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_colors.dart';
import 'package:bean_base/theme/public/bb_typography.dart';

// T5-B22(束1)夜間ループ敵対的レビューMajor-1: `buildPublicTheme()`を通さない
// (=`BbColors`/`BbTypography`の`ThemeExtension`が登録されていない)`ThemeData`
// 配下で`lib/widgets/public/`のコンポーネントが使われた場合に備え、`!`での
// 強制アンラップではなく現在の`ColorScheme`から組み立てたフォールバックを返す。

/// 指定[brightness]に応じて公開版の`ThemeData`を構築する。
ThemeData buildPublicTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = isDark ? publicColorSchemeDark : publicColorSchemeLight;
  final bbColors = isDark ? bbColorsDark : bbColorsLight;
  final bbTypography = buildBbTypography(
    color: colorScheme.onSurface,
    unitColor: colorScheme.onSurfaceVariant,
  );

  // §5.3: 「surfaceTintColorはColors.transparentに固定し、M3の自動ティントで
  // 色が濁るのを防ぐ」規則。ThemeDataにトップレベルのsurfaceTintColorは無いため、
  // ティントを描画しうる主要コンポーネントテーマへ個別に設定する。
  const transparentTint = Colors.transparent;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: publicTextTheme(colorScheme),
    cardTheme: const CardThemeData(surfaceTintColor: transparentTint),
    appBarTheme: const AppBarTheme(surfaceTintColor: transparentTint),
    bottomSheetTheme: const BottomSheetThemeData(surfaceTintColor: transparentTint),
    dialogTheme: const DialogThemeData(surfaceTintColor: transparentTint),
    navigationBarTheme:
        const NavigationBarThemeData(surfaceTintColor: transparentTint),
    popupMenuTheme: const PopupMenuThemeData(surfaceTintColor: transparentTint),
    extensions: [bbColors, bbTypography],
  );
}

/// `Theme.of(context).extension<BbColors>()!`/`<BbTypography>()!`を
/// 画面側に直接書かせないための`BuildContext`拡張(§7末尾)。
extension BbThemeContext on BuildContext {
  /// `buildPublicTheme()`未適用のテーマ配下では、`brightness`に応じた
  /// `bbColorsLight`/`bbColorsDark`へフォールバックする(`!`によるクラッシュを防止)。
  BbColors get bbColors {
    final theme = Theme.of(this);
    return theme.extension<BbColors>() ??
        (theme.brightness == Brightness.dark ? bbColorsDark : bbColorsLight);
  }

  /// `buildPublicTheme()`未適用のテーマ配下では、現在の`ColorScheme`から
  /// 組み立てたタイポグラフィへフォールバックする(`!`によるクラッシュを防止)。
  BbTypography get bbType {
    final theme = Theme.of(this);
    return theme.extension<BbTypography>() ??
        buildBbTypography(
          color: theme.colorScheme.onSurface,
          unitColor: theme.colorScheme.onSurfaceVariant,
        );
  }
}
