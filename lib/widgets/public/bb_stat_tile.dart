// T5-B22(束3): 公開版共通コンポーネント `BbStatTile`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 上にラベル(labelMedium、onSurfaceVariant)、下に数値(numeralL)+単位
// (unit)、任意で補助行(前回比、chartPositive/chartNegativeの三角+
// numeralS)。2〜4個を横並びにしても崩れないようExpanded前提で組む
// (このウィジェット自体は幅を強制しないため、呼び出し側のRowで
// Expandedにより並べる)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版の統計タイル。
class BbStatTile extends StatelessWidget {
  const BbStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.deltaValue,
    this.deltaLabel,
    this.isPositiveDelta,
  });

  final String label;

  /// 数値表示(すでに書式化済みの文字列を渡す)。
  final String value;

  final String? unit;

  /// 前回比の数値(符号込みの文字列、例 '+1.2')。nullなら補助行を表示しない。
  final String? deltaValue;

  /// [deltaValue]の左に付けるラベル(例 '前回比')。省略可。
  final String? deltaLabel;

  /// trueで上向き三角+chartPositive、falseで下向き三角+chartNegative。
  /// [deltaValue]と共にnullでない場合のみ補助行を表示する。
  final bool? isPositiveDelta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bbColors = context.bbColors;
    final bbType = context.bbType;
    final showDelta = deltaValue != null && isPositiveDelta != null;
    final deltaColor =
        isPositiveDelta == true ? bbColors.chartPositive : bbColors.chartNegative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: BbSpace.xxs),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: bbType.numeralL,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: bbType.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (showDelta) ...[
          const SizedBox(height: BbSpace.xxs),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositiveDelta! ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 16,
                  color: deltaColor,
                ),
                if (deltaLabel != null) ...[
                  Flexible(
                    child: Text(
                      deltaLabel!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: Text(
                    deltaValue!,
                    style: bbType.numeralS.copyWith(color: deltaColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
