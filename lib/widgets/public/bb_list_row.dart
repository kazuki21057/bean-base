// T5-B22(束1): 公開版共通コンポーネント `BbListRow`。
//
// 正本は docs/android_monetization/デザイン方針.md §8。
// 最小高rowMinHeight(56)、タップ領域48dp以上。左: リーディング(画像44×44/
// アイコン24/サムネ36、`BbExtractionRing`連携は束3で未実装のためプレース
// ホルダのWidgetを呼び出し側から渡す想定)、中央: 主テキスト+副テキスト、
// 右: 数値+単位+シェブロン。区切り線はoutlineVariant 1px(最終行は
// `showDivider: false`で抑止する)。
import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_theme.dart';
import 'package:bean_base/theme/public/bb_tokens.dart';

/// 公開版の一覧行。
class BbListRow extends StatelessWidget {
  const BbListRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.value,
    this.unit,
    this.showChevron = true,
    this.showDivider = true,
    this.onTap,
  });

  /// 左のリーディング要素(画像44×44角丸sm / アイコン24 / サムネ36の
  /// プレースホルダ等、呼び出し側が組み立てて渡す)。
  final Widget? leading;

  final String title;
  final String? subtitle;

  /// 右側の数値表示(`numeralS`)。
  final String? value;

  /// [value]の単位(`unit`ロール)。
  final String? unit;

  final bool showChevron;

  /// falseにすると下の区切り線を引かない(一覧の最終行向け)。
  final bool showDivider;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // `context.bbType`は`buildPublicTheme()`未適用のThemeData配下でも
    // フォールバックを返すため安全に無条件評価できる(bb_theme.dart参照、
    // T5-B22束1夜間ループ敵対的レビューMajor-1)。ただし`value`がnullの時は
    // 参照しないため、未使用な`BbTypography`生成を避けるべく`value != null`
    // の時だけ評価する(/code-review Minor)。
    final bbType = value != null ? context.bbType : null;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: BbLayout.rowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BbLayout.screenPaddingH,
          vertical: BbSpace.sm,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(width: 44, height: 44, child: Center(child: leading)),
              const SizedBox(width: BbSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: BbSpace.sm),
              Text(value!, style: bbType!.numeralS),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(unit!, style: bbType.unit),
              ],
            ],
            if (showChevron) ...[
              const SizedBox(width: BbSpace.xs),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    final tappable = onTap == null
        ? row
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                debugPrint('[Antigravity] BbListRow: タップ title=$title');
                onTap!();
              },
              child: row,
            ),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tappable,
        if (showDivider)
          Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant),
      ],
    );
  }
}
