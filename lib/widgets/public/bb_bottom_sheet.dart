// T5-B22(束3): 公開版共通コンポーネント `BbBottomSheet`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 上端角丸xl(28)、sheetエレベーション。ドラッグハンドル(32×4、
// outlineVariant色、上sm余白)。タイトル行(titleMedium+右に閉じる
// アイコン、48dpタップ域)。内容。下部に固定アクション行(SafeArea下端+
// lg余白)。高さは内容に追従、画面の90%を上限にスクロール。
//
// 装飾(背景・上端角丸・影)は`BbCard`と同様にウィジェット自身が持つ
// (goldenテストで`showModalBottomSheet`を経由せず単体描画できるように
// するため)。`showBbBottomSheet()`はモーダル自体を透明にしてこの
// ウィジェットへ見た目を委ねる。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_tokens.dart';

/// [BbBottomSheet]でボトムシートを開くヘルパー。`isScrollControlled: true`を
/// 既定にする(§8)。
Future<T?> showBbBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  List<Widget>? actions,
  bool isScrollControlled = true,
}) {
  debugPrint('[Antigravity] showBbBottomSheet: 表示 title=$title');
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        BbBottomSheet(title: title, actions: actions, child: child),
  );
}

/// 公開版のボトムシート本体。
class BbBottomSheet extends StatelessWidget {
  const BbBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.onClose,
  });

  final String title;
  final Widget child;

  /// 下部に固定表示するアクション行(等幅で並べる)。
  final List<Widget>? actions;

  /// nullの場合は閉じるアイコンタップで`Navigator.maybePop`する。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final topRadius = BorderRadius.vertical(top: Radius.circular(BbRadius.xl));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: topRadius,
          // §5.3: ダークモードは影を使わずサーフェスのトーンで段差を表す規則
          // (BbCardと同じ方針)。
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.16),
                    offset: const Offset(0, -2),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: topRadius,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: BbSpace.sm),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: BbLayout.screenPaddingH),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: '閉じる',
                          onPressed: () {
                            debugPrint(
                              '[Antigravity] BbBottomSheet: 閉じるタップ title=$title',
                            );
                            if (onClose != null) {
                              onClose!();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BbLayout.screenPaddingH,
                    ),
                    child: child,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      BbLayout.screenPaddingH,
                      BbSpace.md,
                      BbLayout.screenPaddingH,
                      BbSpace.lg,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < actions!.length; i++) ...[
                          if (i != 0) const SizedBox(width: BbSpace.sm),
                          Expanded(child: actions![i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
