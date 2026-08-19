// T5-B22(束2): 公開版共通コンポーネント `BbLoadingSkeleton` / `BbLoadingSpinner`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 一覧・カードはスケルトン(surfaceContainerHighestの角丸ブロック、
// 1.2秒周期のシマー、3〜5行)。単発処理はCircularProgressIndicator(primary)を
// 中央に。300ms未満で終わる処理では出さない判断は呼び出し側の責務とする。
// ボタン内ローディングは既存の`BbPrimaryButton(isLoading: true)`(束1)を使う。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// 一覧・カード向けのスケルトンローディング。
class BbLoadingSkeleton extends StatefulWidget {
  const BbLoadingSkeleton({super.key, this.lineCount = 3})
      : assert(lineCount >= 3 && lineCount <= 5, 'lineCountは3〜5の範囲(§8)');

  /// 表示するブロック行数(3〜5)。
  final int lineCount;

  @override
  State<BbLoadingSkeleton> createState() => _BbLoadingSkeletonState();
}

class _BbLoadingSkeletonState extends State<BbLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BbMotion.slow + BbMotion.slow + BbMotion.fast, // ≒1.2秒周期
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.4 + 0.3 * _controller.value;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BbLayout.screenPaddingH,
            vertical: BbSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < widget.lineCount; i++) ...[
                Container(
                  height: 16,
                  width: i.isEven ? double.infinity : 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(BbRadius.xs),
                  ),
                ),
                if (i != widget.lineCount - 1)
                  const SizedBox(height: BbSpace.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 単発処理向けのローディング表示。中央に`primary`色のインジケータを出す。
class BbLoadingSpinner extends StatelessWidget {
  const BbLoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
