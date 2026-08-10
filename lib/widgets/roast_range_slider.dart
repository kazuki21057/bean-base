// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import '../screens/create/create_form_widgets.dart';
import '../services/math/encoding.dart';
import 'roast_level_slider.dart' show kRoastLightest, kRoastDarkest;

/// 焙煎度(1〜8段階の順序尺度)の**範囲**を入力するスライダー(T3-71、
/// `docs/method_roast_range_design.md`§5)。`RoastLevelSlider`(T3-54)の
/// 範囲版で、色・レイアウト・変換規則はすべて同ウィジェットを踏襲する。
///
/// 必ず `StatelessWidget`(制御コンポーネント)にすること。内部に選択状態を
/// 持ってはならない(`docs/roast_slider_design.md`§8-①の再発防止)。
class RoastRangeSlider extends StatelessWidget {
  final String? minValue;
  final String? maxValue;
  final void Function(String? min, String? max) onChanged;
  final String label;
  final Widget? trailing;
  final bool enabled;

  const RoastRangeSlider({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.label = '推奨焙煎度',
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final a = _resolveOrdinal(minValue);
    final b = _resolveOrdinal(maxValue);
    final isUnknown =
        a == null && b == null && ((minValue?.isNotEmpty ?? false) || (maxValue?.isNotEmpty ?? false));

    double? lo;
    double? hi;
    if (a != null && b != null) {
      lo = a < b ? a : b;
      hi = a > b ? a : b;
    } else if (a != null) {
      lo = a;
      hi = a;
    } else if (b != null) {
      lo = b;
      hi = b;
    }

    final isSet = lo != null && hi != null;
    final isPoint = isSet && lo == hi;
    final values = isSet ? RangeValues(lo, hi) : const RangeValues(3, 6);
    final thumbColor = isSet ? kEspresso : kLatte;
    final canClear = isSet || isUnknown;

    Widget track = SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const hPad = 12.0;
          final trackW = (constraints.maxWidth - hPad * 2).clamp(1.0, double.infinity);
          double fx(double o) => (o - 1) / 7 * trackW;
          return Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [kRoastLightest, kRoastDarkest]),
                            ),
                          ),
                        ),
                        if (isSet) ...[
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: fx(lo!),
                            child: ColoredBox(color: Colors.white.withValues(alpha: 0.55)),
                          ),
                          Positioned(
                            left: fx(hi!),
                            top: 0,
                            bottom: 0,
                            right: 0,
                            child: ColoredBox(color: Colors.white.withValues(alpha: 0.55)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  activeTickMarkColor: Colors.white.withValues(alpha: 0.7),
                  inactiveTickMarkColor: Colors.white.withValues(alpha: 0.7),
                  thumbColor: thumbColor,
                  overlayColor: kAccent.withValues(alpha: 0.2),
                  rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                  overlappingShapeStrokeColor: Colors.white,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: RangeSlider(
                  min: 1,
                  max: 8,
                  divisions: 7,
                  values: values,
                  onChanged: enabled
                      ? (v) => onChanged(
                            roastLevels8[v.start.round() - 1],
                            roastLevels8[v.end.round() - 1],
                          )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
    if (!enabled || !isSet) {
      track = Opacity(opacity: 0.4, child: track);
    }

    final clearButton = TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: (enabled && canClear) ? () => onChanged(null, null) : null,
      child: const Text('クリア', style: TextStyle(fontSize: 12)),
    );

    final Widget currentValueDisplay;
    if (isSet && isPoint) {
      final idx = lo.round() - 1;
      currentValueDisplay = Text(
        '${roastLevels8[idx]} (${roastLevels8En[idx]})  ${idx + 1}/8 のみ',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: kEspresso,
        ),
      );
    } else if (isSet) {
      final loIdx = lo.round() - 1;
      final hiIdx = hi.round() - 1;
      currentValueDisplay = Text(
        '${roastLevels8[loIdx]} 〜 ${roastLevels8[hiIdx]}  ${loIdx + 1}〜${hiIdx + 1}/8',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: kEspresso,
        ),
      );
    } else if (isUnknown) {
      final rawText = (minValue?.isNotEmpty ?? false) &&
              (maxValue?.isNotEmpty ?? false) &&
              minValue != maxValue
          ? '「$minValue」「$maxValue」'
          : '「${(minValue?.isNotEmpty ?? false) ? minValue : maxValue}」';
      currentValueDisplay = Text(
        '未設定(登録値: $rawText)',
        style: const TextStyle(fontSize: 13, color: kMocha),
      );
    } else {
      currentValueDisplay = const Text(
        '未設定(スライダーを動かして範囲を選択)',
        style: TextStyle(fontSize: 13, color: kMocha),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: kMocha)),
              const Spacer(),
              clearButton,
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          Center(child: currentValueDisplay),
          track,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('浅い', style: TextStyle(fontSize: 11, color: kMocha)),
                Text('深い', style: TextStyle(fontSize: 11, color: kMocha)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double? _resolveOrdinal(String? value) {
    if (value == null || value.isEmpty) return null;
    final o = roastOrdinalMap[value];
    if (o == null) return null;
    if (o < 1.0 || o > 8.0) return null;
    return o;
  }
}
