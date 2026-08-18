// T5-B22(束1): 公開版共通コンポーネント `BbChip`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 高さ32、角丸pill。非選択=surfaceContainerHigh+onSurfaceVariant、
// 選択=primaryContainer+onPrimaryContainer+左にチェック16。
// 焙煎度チップ用に左にroastRampの丸ドット10を付けるオプション(D8: 段階名併記)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版のチップ(フィルター・焙煎度選択等)。
class BbChip extends StatelessWidget {
  const BbChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.roastDotColor,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  /// 焙煎度チップの左ドット色(`BbColors.roastRamp`から呼び出し側が選ぶ)。
  /// 指定時もラベル(段階名)は必ず併記すること(D8)。
  final Color? roastDotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor =
        selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh;
    final fgColor =
        selected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(BbRadius.pill),
        onTap: onSelected == null
            ? null
            : () {
                debugPrint(
                  '[Antigravity] BbChip: タップ label=$label selected=${!selected}',
                );
                onSelected!(!selected);
              },
        child: Ink(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: BbSpace.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(BbRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (roastDotColor != null) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: roastDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: BbSpace.xs),
              ],
              if (selected) ...[
                Icon(Icons.check, size: 16, color: fgColor),
                const SizedBox(width: BbSpace.xs),
              ],
              Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fgColor)),
            ],
          ),
        ),
      ),
    );
  }
}
