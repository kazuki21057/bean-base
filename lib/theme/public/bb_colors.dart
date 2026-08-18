// T5-B21: 公開版(Android)のカラートークン。
//
// 正本は docs/android_monetization/デザイン方針.md §3。
// このファイルは同ドキュメントの hex 値をそのまま実装したものであり、
// 値の解釈や配色の追加判断は一切行っていない。
//
// 禁止事項(同ドキュメント D1): このファイルから personal版のメインカラー系
// Provider(lib/providers/theme_provider.dart)、
// kEspresso/kMocha/kLatte/kCream/kAccent(lib/screens/create/create_form_widgets.dart)
// を一切参照しない。
import 'package:flutter/material.dart';

/// §3.1 `ColorScheme`(ライト)。`fromSeed` を使わず全ロールを明示値で定義する(D3)。
const ColorScheme publicColorSchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF00695E),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFB4EDE3),
  onPrimaryContainer: Color(0xFF00201C),
  secondary: Color(0xFF40565E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFD3E2E7),
  onSecondaryContainer: Color(0xFF101E23),
  tertiary: Color(0xFF7A5424),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF5DFC0),
  onTertiaryContainer: Color(0xFF2A1A05),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFF4F7F7),
  onSurface: Color(0xFF101718),
  onSurfaceVariant: Color(0xFF4C585B),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFEFF3F4),
  surfaceContainerHigh: Color(0xFFE8EDEE),
  surfaceContainerHighest: Color(0xFFE1E8E9),
  outline: Color(0xFF6F7B7E),
  outlineVariant: Color(0xFFD3DBDC),
  inverseSurface: Color(0xFF2A3234),
  onInverseSurface: Color(0xFFF0F4F5),
  inversePrimary: Color(0xFF79C8C0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF00695E),
);

/// §3.1 `ColorScheme`(ダーク)。
const ColorScheme publicColorSchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF79C8C0),
  onPrimary: Color(0xFF00332E),
  primaryContainer: Color(0xFF00504A),
  onPrimaryContainer: Color(0xFF9CEDE2),
  secondary: Color(0xFFA9BCC2),
  onSecondary: Color(0xFF14282E),
  secondaryContainer: Color(0xFF2B3E44),
  onSecondaryContainer: Color(0xFFC7DAE0),
  tertiary: Color(0xFFD9B78A),
  onTertiary: Color(0xFF3B2A12),
  tertiaryContainer: Color(0xFF54401F),
  onTertiaryContainer: Color(0xFFF3DCBB),
  error: Color(0xFFFF9B92),
  onError: Color(0xFF58100C),
  errorContainer: Color(0xFF7A211A),
  onErrorContainer: Color(0xFFFFDAD5),
  surface: Color(0xFF0E1315),
  onSurface: Color(0xFFE6EBED),
  onSurfaceVariant: Color(0xFFA3AFB4),
  surfaceContainerLowest: Color(0xFF090D0F),
  surfaceContainerLow: Color(0xFF12181A),
  surfaceContainer: Color(0xFF161C1F),
  surfaceContainerHigh: Color(0xFF1D2427),
  surfaceContainerHighest: Color(0xFF242C30),
  outline: Color(0xFF6E7A7E),
  outlineVariant: Color(0xFF2C3438),
  inverseSurface: Color(0xFFE6EBED),
  onInverseSurface: Color(0xFF14191B),
  inversePrimary: Color(0xFF00695E),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF79C8C0),
);

/// §3.2 `BbColors`。M3の`ColorScheme`ロール名に載せられないドメイン固有色(D4)。
@immutable
class BbColors extends ThemeExtension<BbColors> {
  const BbColors({
    required this.live,
    required this.liveText,
    required this.liveContainer,
    required this.onLiveContainer,
    required this.ringTrack,
    required this.roastRamp,
    required this.chartCurrent,
    required this.chartPrevious,
    required this.chartBand,
    required this.chartGrid,
    required this.chartPositive,
    required this.chartNegative,
    required this.adSlotBackground,
  });

  /// 抽出中だけ使うアンバー。リングの弧・実行中ステップ・タイマー。
  final Color live;

  /// アンバー系の文字(コントラスト確保のため`live`と別値)。
  final Color liveText;

  /// 実行中ステップ行の背景。
  final Color liveContainer;

  /// `liveContainer`上の文字。
  final Color onLiveContainer;

  /// リングの未経過部分。
  final Color ringTrack;

  /// 焙煎度8段階(ライト→イタリアン)。既存の焙煎度8段階ガイドの順序と1対1対応。
  final List<Color> roastRamp;

  /// グラフの現在系列。
  final Color chartCurrent;

  /// 前回比較の系列。
  final Color chartPrevious;

  /// 不確実性の帯(点推定と必ずセット表示、statistics_feature_design.md §0)。
  final Color chartBand;

  /// グラフの目盛線。
  final Color chartGrid;

  /// 改善・上振れ。
  final Color chartPositive;

  /// 悪化・下振れ。
  final Color chartNegative;

  /// バナー広告枠の地。
  final Color adSlotBackground;

  @override
  BbColors copyWith({
    Color? live,
    Color? liveText,
    Color? liveContainer,
    Color? onLiveContainer,
    Color? ringTrack,
    List<Color>? roastRamp,
    Color? chartCurrent,
    Color? chartPrevious,
    Color? chartBand,
    Color? chartGrid,
    Color? chartPositive,
    Color? chartNegative,
    Color? adSlotBackground,
  }) {
    return BbColors(
      live: live ?? this.live,
      liveText: liveText ?? this.liveText,
      liveContainer: liveContainer ?? this.liveContainer,
      onLiveContainer: onLiveContainer ?? this.onLiveContainer,
      ringTrack: ringTrack ?? this.ringTrack,
      roastRamp: roastRamp ?? this.roastRamp,
      chartCurrent: chartCurrent ?? this.chartCurrent,
      chartPrevious: chartPrevious ?? this.chartPrevious,
      chartBand: chartBand ?? this.chartBand,
      chartGrid: chartGrid ?? this.chartGrid,
      chartPositive: chartPositive ?? this.chartPositive,
      chartNegative: chartNegative ?? this.chartNegative,
      adSlotBackground: adSlotBackground ?? this.adSlotBackground,
    );
  }

  @override
  BbColors lerp(ThemeExtension<BbColors>? other, double t) {
    if (other is! BbColors) return this;
    return BbColors(
      live: Color.lerp(live, other.live, t)!,
      liveText: Color.lerp(liveText, other.liveText, t)!,
      liveContainer: Color.lerp(liveContainer, other.liveContainer, t)!,
      onLiveContainer: Color.lerp(onLiveContainer, other.onLiveContainer, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      roastRamp: [
        for (var i = 0; i < roastRamp.length; i++)
          Color.lerp(roastRamp[i], other.roastRamp[i], t)!,
      ],
      chartCurrent: Color.lerp(chartCurrent, other.chartCurrent, t)!,
      chartPrevious: Color.lerp(chartPrevious, other.chartPrevious, t)!,
      chartBand: Color.lerp(chartBand, other.chartBand, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartPositive: Color.lerp(chartPositive, other.chartPositive, t)!,
      chartNegative: Color.lerp(chartNegative, other.chartNegative, t)!,
      adSlotBackground: Color.lerp(adSlotBackground, other.adSlotBackground, t)!,
    );
  }
}

const List<Color> _roastRampLight = [
  Color(0xFFD9B27C),
  Color(0xFFC79A63),
  Color(0xFFB4834D),
  Color(0xFF9C6A3A),
  Color(0xFF82522B),
  Color(0xFF66401F),
  Color(0xFF4A2E16),
  Color(0xFF31200F),
];

const List<Color> _roastRampDark = [
  Color(0xFFE7C795),
  Color(0xFFD6AE79),
  Color(0xFFC39662),
  Color(0xFFAC7D4C),
  Color(0xFF93653A),
  Color(0xFF7C512C),
  Color(0xFF66401F),
  Color(0xFF513521),
];

/// §3.2の`BbColors`(ライト)。
///
/// `chartBand`は「`chartCurrent`の16%」(§3.2)。const化のため
/// アルファ値をあらかじめ計算済み(0.16 * 255 ≈ 41 = 0x29)。
const BbColors bbColorsLight = BbColors(
  live: Color(0xFFE08A2E),
  liveText: Color(0xFF8A4B00),
  liveContainer: Color(0xFFFFE4C4),
  onLiveContainer: Color(0xFF2E1600),
  ringTrack: Color(0xFFDFE6E7),
  roastRamp: _roastRampLight,
  chartCurrent: Color(0xFF00695E),
  chartPrevious: Color(0xFF98A6AA),
  chartBand: Color(0x2900695E),
  chartGrid: Color(0xFFD3DBDC),
  chartPositive: Color(0xFF2E7D5B),
  chartNegative: Color(0xFFB3261E),
  adSlotBackground: Color(0xFFE8EDEE),
);

/// §3.2の`BbColors`(ダーク)。
const BbColors bbColorsDark = BbColors(
  live: Color(0xFFF0A24A),
  liveText: Color(0xFFF5BE7E),
  liveContainer: Color(0xFF4A2E0B),
  onLiveContainer: Color(0xFFFFDCB8),
  ringTrack: Color(0xFF262E31),
  roastRamp: _roastRampDark,
  chartCurrent: Color(0xFF79C8C0),
  chartPrevious: Color(0xFF667276),
  chartBand: Color(0x2979C8C0),
  chartGrid: Color(0xFF2C3438),
  chartPositive: Color(0xFF74D3A8),
  chartNegative: Color(0xFFFF9B92),
  adSlotBackground: Color(0xFF12181A),
);
