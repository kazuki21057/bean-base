// T5-B22(束1): 公開版共通コンポーネント `BbPrimaryButton` / `BbTextButton`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 主ボタン: 高さ48、角丸md、primary地にonPrimary文字(labelLarge)。
// 破壊的操作はisDestructiveでerror地にする。
// 副次BbTextButton: 高さ44、枠線outline。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版の主ボタン。1画面に主ボタンは1つまで(§8)。
class BbPrimaryButton extends StatelessWidget {
  const BbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// 破壊的操作(削除等)のときtrue。地色がerrorになる。
  final bool isDestructive;

  /// trueの間はタップ不可にし、ラベルを16dpのインジケータへ差し替える。
  final bool isLoading;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isDestructive ? colorScheme.error : colorScheme.primary;
    final fgColor = isDestructive ? colorScheme.onError : colorScheme.onPrimary;

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isLoading || onPressed == null
            ? null
            : () {
                debugPrint('[Antigravity] BbPrimaryButton: タップ label=$label');
                onPressed!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.38),
          disabledForegroundColor: fgColor.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BbRadius.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fgColor,
                ),
              )
            : icon == null
                ? Text(label)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18),
                      const SizedBox(width: BbSpace.sm),
                      Text(label),
                    ],
                  ),
      ),
    );
  }
}

/// 公開版の副次ボタン(枠線)。
class BbTextButton extends StatelessWidget {
  const BbTextButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed == null
            ? null
            : () {
                debugPrint('[Antigravity] BbTextButton: タップ label=$label');
                onPressed!();
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BbRadius.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: Text(label),
      ),
    );
  }
}
