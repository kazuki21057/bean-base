// T5-B22(束1): 公開版共通コンポーネント `BbSectionHeader`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// アイベロウ(labelMedium、onSurfaceVariant、字間0.8)+見出し(titleLarge)+
// 右端に任意アクション(テキストボタン)。上xl(24)/下md(12)の余白。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版のセクション見出し。
class BbSectionHeader extends StatelessWidget {
  const BbSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? eyebrow;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: BbSpace.xl, bottom: BbSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                Text(title, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap == null
                  ? null
                  : () {
                      debugPrint(
                        '[Antigravity] BbSectionHeader: アクションタップ label=$actionLabel',
                      );
                      onActionTap!();
                    },
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
