// T5-B22(束2): 公開版共通コンポーネント `BbErrorView`。
//
// 正本は docs/android_monetization/デザイン方針.md §8・§10。
// 「何が起きたか」+「どうすれば直るか」+「再試行」ボタン。謝罪文・顔文字・
// 感嘆符を入れない。フルスクリーン版(画面全体の読み込み失敗)とインライン版
// (カード内、errorContainer地+左に3pxのerrorバー)の2バリアント。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';
import 'package:bean_base/widgets/public/bb_buttons.dart';

/// 公開版のエラー表示。[isInline]でフルスクリーン/インラインを切り替える。
class BbErrorView extends StatelessWidget {
  const BbErrorView({
    super.key,
    required this.title,
    required this.description,
    this.onRetry,
    this.retryLabel = '再試行',
    this.isInline = false,
  });

  /// 何が起きたか。
  final String title;

  /// どうすれば直るか。
  final String description;

  final VoidCallback? onRetry;
  final String retryLabel;

  /// trueでカード内(errorContainer地+左3pxバー)のインライン版になる。
  final bool isInline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isInline ? colorScheme.onErrorContainer : colorScheme.onSurface;
    final descColor =
        isInline ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isInline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: isInline ? 24 : 48,
          color: colorScheme.error,
        ),
        SizedBox(height: isInline ? BbSpace.sm : BbSpace.lg),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(color: textColor),
          textAlign: isInline ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: BbSpace.xs),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(color: descColor),
          textAlign: isInline ? TextAlign.start : TextAlign.center,
        ),
        if (onRetry != null) ...[
          SizedBox(height: isInline ? BbSpace.md : BbSpace.xl),
          if (isInline)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  debugPrint(
                    '[Antigravity] BbErrorView: 再試行タップ(インライン) title=$title',
                  );
                  onRetry!();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onErrorContainer,
                ),
                child: Text(retryLabel),
              ),
            )
          else
            BbPrimaryButton(
              label: retryLabel,
              onPressed: () {
                debugPrint('[Antigravity] BbErrorView: 再試行タップ title=$title');
                onRetry!();
              },
            ),
        ],
      ],
    );

    if (!isInline) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BbLayout.screenPaddingH,
          vertical: BbSpace.xxl,
        ),
        child: body,
      );
    }

    return Container(
      padding: const EdgeInsets.all(BbLayout.cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(BbRadius.md),
        border: Border(left: BorderSide(color: colorScheme.error, width: 3)),
      ),
      child: body,
    );
  }
}
