import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import 'create/create_form_widgets.dart';
import 'log_detail_screen.dart';
import 'mock/mock_scaffold.dart';

/// Cycle 20 T1-5a: 汎用マスター画面テンプレート。
///
/// ドリッパー/フィルター/グラインダー/メソッドなど、構造が共通する
/// マスター種別の「一覧」「詳細」画面をここに集約する。各マスター種別側は
/// フィールドの取り出し方・遷移先・保存/削除処理を渡すだけで画面が組める。

/// 汎用マスター一覧(画像左・名前右+＋ボタン)。
class MasterListTemplate<T> extends StatelessWidget {
  final AppScreen screen;
  final IconData icon;
  final AsyncValue<List<T>> itemsAsync;
  final String Function(T item) nameOf;
  final String Function(T item) subtitleOf;
  final String? Function(T item) imageUrlOf;
  final void Function(BuildContext context, T item) onTapItem;
  final Widget Function() createScreenBuilder;
  final bool Function(T item)? filter;

  const MasterListTemplate({
    super.key,
    required this.screen,
    required this.icon,
    required this.itemsAsync,
    required this.nameOf,
    required this.subtitleOf,
    required this.imageUrlOf,
    required this.onTapItem,
    required this.createScreenBuilder,
    this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: screen,
      floatingActionButton: MockAddFab(
        tooltip: '新規追加へ',
        destinationBuilder: createScreenBuilder,
      ),
      children: [
        itemsAsync.when(
          data: (items) {
            final visible = filter == null ? items : items.where(filter!).toList();
            if (visible.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('登録されていません')),
              );
            }
            return Column(
              children: [
                for (final item in visible)
                  MockListRow(
                    icon: icon,
                    title: nameOf(item),
                    subtitle: subtitleOf(item),
                    imageUrl: imageUrlOf(item),
                    onTap: () => onTapItem(context, item),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('読み込みエラー: $e')),
          ),
        ),
      ],
    );
  }
}

/// 汎用マスター詳細(全情報+関連する抽出履歴5件)。
class MasterDetailTemplate extends ConsumerWidget {
  final AppScreen screen;
  final IconData icon;
  final String title;
  final String? imageUrl;
  final List<(String, String)> fields;
  final bool Function(CoffeeRecord log) relatedLogFilter;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const MasterDetailTemplate({
    super.key,
    required this.screen,
    required this.icon,
    required this.title,
    required this.fields,
    required this.relatedLogFilter,
    required this.onEdit,
    required this.onDelete,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);

    final beanNames = <String, String>{};
    beansAsync.whenData((beans) {
      for (final b in beans) {
        beanNames[b.id] = b.name;
      }
    });
    final methodNames = <String, String>{};
    methodsAsync.whenData((methods) {
      for (final m in methods) {
        methodNames[m.id] = m.name;
      }
    });

    return MockScreenScaffold(
      screen: screen,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '編集',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '削除',
          onPressed: () => _confirmDelete(context),
        ),
      ],
      children: [
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        FormSection(
          icon: icon,
          title: '基本情報',
          children: [
            for (final (label, value) in fields) MockInfoRow(label: label, value: value),
          ],
        ),
        FormSection(
          icon: Icons.history,
          title: '関連する抽出履歴',
          children: [
            logsAsync.when(
              data: (logs) {
                final related = logs.where(relatedLogFilter).toList()
                  ..sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
                final top5 = related.take(5).toList();
                if (top5.isEmpty) {
                  return const Text('関連する抽出履歴はまだありません');
                }
                return Column(
                  children: [
                    for (final log in top5)
                      MockListRow(
                        icon: Icons.coffee,
                        title: '${_formatDate(log.brewedAt)} ${beanNames[log.beanId] ?? log.beanId}',
                        subtitle: methodNames[log.methodId] ?? log.methodId,
                        trailing: MockScoreBadge(score: log.scoreOverall),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogDetailScreen(log: log)),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('読み込みエラー: $e'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「$title」を削除しますか?この操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await onDelete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }
}
