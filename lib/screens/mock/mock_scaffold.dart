import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../../theme/blackboard_theme.dart';
import '../../widgets/bean_image.dart';
import '../create/create_form_widgets.dart';

/// 一覧・詳細・ダッシュボード系画面のUIモック共通骨格。
/// 作成系の CreateFormScaffold と同じパレット(コーヒートーン)を使い、
/// 保存バーの代わりに任意のFAB/AppBarアクションを持てる。
///
/// `boardTexture: true` にすると本文の背景が黒板風(Cycle 20 T2-1a)になる。
/// デフォルトは従来どおりのクリーム背景のため、他画面は無変更で動く。
class MockScreenScaffold extends StatelessWidget {
  final AppScreen screen;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final double maxWidth;
  final bool boardTexture;

  const MockScreenScaffold({
    super.key,
    required this.screen,
    required this.children,
    this.floatingActionButton,
    this.actions,
    this.maxWidth = 720,
    this.boardTexture = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: children,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: boardTexture ? kBoardBg : kCream,
      appBar: AppBar(
        backgroundColor: kEspresso,
        foregroundColor: kCream,
        actions: actions,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                screen.code,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(screen.titleJa, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: boardTexture ? BlackboardTexture(child: body) : body,
    );
  }
}

/// モック用の「＋」FAB。押すと指定画面(作成画面など)へ遷移する。
class MockAddFab extends StatelessWidget {
  final Widget Function() destinationBuilder;
  final String tooltip;

  const MockAddFab(
      {super.key, required this.destinationBuilder, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: kEspresso,
      foregroundColor: kCream,
      tooltip: tooltip,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destinationBuilder()),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

/// 画像左・テキスト右のリスト行モック。
class MockListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MockListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLatte),
      ),
      child: ListTile(
        onTap: onTap ??
            () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('UIモックです。遷移は後続タスクで実装されます。')),
                ),
        leading: Container(
          width: 48,
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: kCream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kLatte),
          ),
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? BeanImage(imagePath: imageUrl, fit: BoxFit.cover, placeholderIcon: icon)
              : Icon(icon, color: kMocha),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: kMocha)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: kLatte),
      ),
    );
  }
}

/// 詳細画面のラベル+値の行。
class MockInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const MockInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: kMocha)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// 残量%を表す瓶ビジュアルの簡易モック(Phase 2 T2-2aで本実装予定)。
class MockBeanJar extends StatelessWidget {
  final String name;
  final int percent;

  const MockBeanJar({super.key, required this.name, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 76,
          decoration: BoxDecoration(
            border: Border.all(color: kLatte, width: 2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
              bottom: Radius.circular(16),
            ),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FractionallySizedBox(
                widthFactor: 1,
                child: Container(
                  height: 72 * (percent / 100),
                  decoration: BoxDecoration(
                    color: kMocha.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('$percent%',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso)),
        SizedBox(
          width: 72,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: kMocha),
          ),
        ),
      ],
    );
  }
}

/// スコアバッジ(履歴リスト用)。
class MockScoreBadge extends StatelessWidget {
  final int score;

  const MockScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: kAccent,
      child: Text(
        '$score',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
