import 'package:flutter/material.dart';
import '../screens/create/create_form_widgets.dart';
import '../services/math/encoding.dart';

// 浅煎り(ベージュ)→深煎り(ダークブラウン)のグラデーション色(T3-54、設計書§3.3)。
const kRoastLightest = Color(0xFFC8A87C);
const kRoastDarkest = Color(0xFF3B2314);

/// 焙煎度(1〜8段階の順序尺度)を入力するスライダー。
///
/// `BeanMaster.roastLevel` は文字列(新8段階/旧5段階/未知の自由入力/null)の
/// まま保存されるため、このウィジェットは常に生の文字列を受け取り、
/// `roastOrdinalMap` 経由で順序値に解決してから表示する(設計書§4)。
///
/// 必ず `StatelessWidget`(制御コンポーネント)にすること。`MockChoiceChips`
/// が `initialValue` を `initState` でしか読まないために AI 自動入力が画面に
/// 反映されない既存バグ(T3-58と同型)を再発させないため(設計書§8-①)。
class RoastLevelSlider extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final Widget? trailing;
  final bool compact;
  final bool enabled;

  const RoastLevelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '煎り度',
    this.trailing,
    this.compact = false,
    this.enabled = true,
  });

  double? _resolveOrdinal() {
    if (value == null || value!.isEmpty) return null;
    final o = roastOrdinalMap[value];
    if (o == null) return null;
    if (o < 1.0 || o > 8.0) return null;
    return o;
  }

  @override
  Widget build(BuildContext context) {
    final ordinal = _resolveOrdinal();
    final isUnknown = ordinal == null && value != null && value!.isNotEmpty;
    final sliderValue = ordinal ?? 4.0;
    final thumbColor = ordinal != null ? kEspresso : kLatte;

    final canClear = ordinal != null || isUnknown;

    Widget track = SizedBox(
      height: compact ? 32 : 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [kRoastLightest, kRoastDarkest],
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
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: compact ? 8 : 10,
              ),
            ),
            child: Slider(
              min: 1,
              max: 8,
              divisions: 7,
              value: sliderValue,
              onChanged: enabled
                  ? (v) => onChanged(roastLevels8[v.round() - 1])
                  : null,
            ),
          ),
        ],
      ),
    );
    if (!enabled) {
      track = Opacity(opacity: 0.4, child: track);
    }

    final clearButton = TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: (enabled && canClear) ? () => onChanged(null) : null,
      child: const Text('クリア', style: TextStyle(fontSize: 12)),
    );

    if (compact) {
      final Widget currentValueInline;
      if (ordinal != null) {
        final idx = ordinal.toInt() - 1;
        currentValueInline = Text(
          '${roastLevels8[idx]} ${ordinal.toInt()}/8',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: kEspresso,
          ),
        );
      } else if (isUnknown) {
        currentValueInline = Text(
          '未設定(登録値: 「$value」)',
          style: const TextStyle(fontSize: 13, color: kMocha),
        );
      } else {
        currentValueInline = const Text(
          '未設定',
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
                const SizedBox(width: 8),
                currentValueInline,
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 4),
            track,
          ],
        ),
      );
    }

    final Widget currentValueDisplay;
    if (ordinal != null) {
      final idx = ordinal.toInt() - 1;
      currentValueDisplay = Text(
        '${roastLevels8[idx]} (${roastLevels8En[idx]})  ${ordinal.toInt()}/8',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: kEspresso,
        ),
      );
    } else if (isUnknown) {
      currentValueDisplay = Text(
        '未設定(登録値: 「$value」)',
        style: const TextStyle(fontSize: 13, color: kMocha),
      );
    } else {
      currentValueDisplay = const Text(
        '未設定(スライダーを動かして選択)',
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
}
