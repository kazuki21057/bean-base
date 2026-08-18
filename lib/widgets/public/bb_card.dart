// T5-B22(束1): 公開版共通コンポーネント `BbCard`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 角丸md(14)・内側cardPadding(16)。ライト=surfaceContainerLow+outlineVariant
// 1px+raisedの影。ダーク=surfaceContainerLowのみ(枠線・影なし、§5.3の規則)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版のカードコンテナ。`onTap`指定時はリップルをカード形状にクリップする。
class BbCard extends StatelessWidget {
  const BbCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(BbRadius.md);

    final decoration = BoxDecoration(
      color: colorScheme.surfaceContainerLow,
      borderRadius: radius,
      border: isDark
          ? null
          : Border.all(color: colorScheme.outlineVariant, width: 1),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(BbLayout.cardPadding),
      child: child,
    );

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    // T5-B22(束1)夜間ループ/code-review Major-2: `boxShadow`はカード外側に
    // はみ出して描画される必要があるため、`ClipRRect`の外側の`DecoratedBox`で
    // 影(および背景色・枠線)を描き、`ClipRRect`はリップルのクリップだけを
    // 担う(内側の`Ink`は非タップ分岐と同じ`decoration`をそのまま使い、
    // 見た目を一致させる)。
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: decoration.boxShadow),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('[Antigravity] BbCard: タップ');
              onTap!();
            },
            child: Ink(decoration: decoration, child: content),
          ),
        ),
      ),
    );
  }
}
