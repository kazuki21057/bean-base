// T5-B22(束2): 公開版共通コンポーネント `BbEmptyState`。
//
// 正本は docs/android_monetization/デザイン方針.md §8・§10。
// 中央寄せ。線画アイコン48(onSurfaceVariant)、見出しtitleMedium、
// 説明bodyMedium2行以内、主アクション1つ。「データがありません」は禁止し、
// 次にやることを書く(実文言は呼び出し側が§10の表から渡す)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';
import 'package:bean_base/widgets/public/bb_buttons.dart';

/// 公開版の空状態表示。一覧・データ不足画面で使う。
class BbEmptyState extends StatelessWidget {
  const BbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionTap,
  });

  /// 線画アイコン(§8: 48dp・onSurfaceVariant)。
  final IconData icon;

  final String title;

  /// bodyMedium・2行以内(maxLinesで強制)。
  final String description;

  /// 主アクションのラベル。nullの場合はボタンを出さない。
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BbLayout.screenPaddingH,
        vertical: BbSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: BbSpace.lg),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BbSpace.sm),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: BbSpace.xl),
            BbPrimaryButton(
              label: actionLabel!,
              onPressed: onActionTap == null
                  ? null
                  : () {
                      debugPrint(
                        '[Antigravity] BbEmptyState: アクションタップ label=$actionLabel',
                      );
                      onActionTap!();
                    },
            ),
          ],
        ],
      ),
    );
  }
}
