// T5-B21: 公開版(Android)のタイポグラフィトークン。
//
// 正本は docs/android_monetization/デザイン方針.md §4。
// 和文はプラットフォーム既定フォント(§1.3、fontFamily指定なし)。
// 数字・単位・ラテンは本来 IBM Plex Mono を等幅(tabular figures)で組む(§4.2)が、
// フォント未調達のためfontFamily指定は暫定的に外している(下記コメント参照)。
import 'package:flutter/material.dart';

/// §4.1 `TextTheme`(和文はプラットフォーム既定フォント)。
///
/// 色は渡された[colorScheme]の`onSurface`を基準にする(M3の既定Typographyと
/// 同じ考え方。個別ロールごとの色は§4.1の表に定義が無いため、テキスト色は
/// このロールに統一する)。
TextTheme publicTextTheme(ColorScheme colorScheme) {
  final baseColor = colorScheme.onSurface;
  return TextTheme(
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: -0.2,
      color: baseColor,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: 0,
      color: baseColor,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 1.40,
      letterSpacing: 0,
      color: baseColor,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.60,
      letterSpacing: 0,
      color: baseColor,
    ),
    bodyMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.50,
      letterSpacing: 0,
      color: baseColor,
    ),
    bodySmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.40,
      letterSpacing: 0.2,
      color: baseColor,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.20,
      letterSpacing: 0.2,
      color: baseColor,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.20,
      letterSpacing: 0.8,
      color: baseColor,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.20,
      letterSpacing: 0.6,
      color: baseColor,
    ),
  );
}

/// §4.2 `BbTypography`。数値・単位専用の等幅トークン
/// (本来`fontFamily: 'IBMPlexMono'`だがフォント未調達のため暫定的に未指定、
/// `fontFeatures: [FontFeature.tabularFigures()]`)。
@immutable
class BbTypography extends ThemeExtension<BbTypography> {
  const BbTypography({
    required this.numeralXl,
    required this.numeralL,
    required this.numeralM,
    required this.numeralS,
    required this.unit,
  });

  /// 抽出リング中央のタイマー/目標湯量。
  final TextStyle numeralXl;

  /// 総合評価・主要KPI。
  final TextStyle numeralL;

  /// カード内の数値。
  final TextStyle numeralM;

  /// リスト行の数値。
  final TextStyle numeralS;

  /// 単位(g/℃/秒/%)。色は`onSurfaceVariant`(§4.2)、数値の直後にベースライン揃えで置く。
  final TextStyle unit;

  @override
  BbTypography copyWith({
    TextStyle? numeralXl,
    TextStyle? numeralL,
    TextStyle? numeralM,
    TextStyle? numeralS,
    TextStyle? unit,
  }) {
    return BbTypography(
      numeralXl: numeralXl ?? this.numeralXl,
      numeralL: numeralL ?? this.numeralL,
      numeralM: numeralM ?? this.numeralM,
      numeralS: numeralS ?? this.numeralS,
      unit: unit ?? this.unit,
    );
  }

  @override
  BbTypography lerp(ThemeExtension<BbTypography>? other, double t) {
    if (other is! BbTypography) return this;
    return BbTypography(
      numeralXl: TextStyle.lerp(numeralXl, other.numeralXl, t)!,
      numeralL: TextStyle.lerp(numeralL, other.numeralL, t)!,
      numeralM: TextStyle.lerp(numeralM, other.numeralM, t)!,
      numeralS: TextStyle.lerp(numeralS, other.numeralS, t)!,
      unit: TextStyle.lerp(unit, other.unit, t)!,
    );
  }
}

const List<FontFeature> _tabularFigures = [FontFeature.tabularFigures()];

// T5-B21夜間ループ敵対的レビューM2: 'IBMPlexMono'はpubspec.yamlに未登録・
// assets/fonts/にファイルが無く実体を伴わないため、フォント調達(本タスクの
// スコープ外)までfontFamily指定を外す。fontFeatures(tabularFigures)は
// プラットフォーム既定フォントでも等幅数字が機能する場合があるため残す。
// フォント調達後、各TextStyleに`fontFamily: 'IBMPlexMono'`を復活させること。

/// [BbTypography]をベースの文字色(引数省略時は指定しない=呼び出し側の
/// `DefaultTextStyle`/`Theme`の色を継承)で組み立てる。
///
/// [unitColor]は§4.2の規定どおり`unit`ロールにのみ適用する色(`onSurfaceVariant`)。
/// 省略時は[color]にフォールバックする。
BbTypography buildBbTypography({Color? color, Color? unitColor}) {
  return BbTypography(
    numeralXl: TextStyle(
      fontFeatures: _tabularFigures,
      fontSize: 48,
      fontWeight: FontWeight.w600,
      height: 1.00,
      letterSpacing: -1.0,
      color: color,
    ),
    numeralL: TextStyle(
      fontFeatures: _tabularFigures,
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.05,
      letterSpacing: -0.5,
      color: color,
    ),
    numeralM: TextStyle(
      fontFeatures: _tabularFigures,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.10,
      letterSpacing: 0,
      color: color,
    ),
    numeralS: TextStyle(
      fontFeatures: _tabularFigures,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.20,
      letterSpacing: 0,
      color: color,
    ),
    unit: TextStyle(
      fontFeatures: _tabularFigures,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.20,
      letterSpacing: 0.4,
      color: unitColor ?? color,
    ),
  );
}
