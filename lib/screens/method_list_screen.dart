import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/method_master.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import 'create/method_create_screen.dart';
import 'master_template.dart';
import 'method_detail_screen.dart';

/// 019 メソッド管理(リスト)。
///
/// Cycle 20 T1-5d: 汎用マスターテンプレート(MasterListTemplate)を
/// T1-5a〜cのドリッパー/フィルター/グラインダー実装から流用した本実装。
/// メソッドは画像を持たないため一覧行はアイコンのみ、サブテキストに
/// 発案者と抽出回数(関連する抽出履歴の件数)を表示する。
class MethodListScreen extends ConsumerWidget {
  const MethodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(methodMasterProvider);
    final logsAsync = ref.watch(coffeeRecordsProvider);

    final counts = <String, int>{};
    logsAsync.whenData((logs) {
      for (final log in logs) {
        counts[log.methodId] = (counts[log.methodId] ?? 0) + 1;
      }
    });

    return MasterListTemplate<MethodMaster>(
      screen: AppScreen.methodList,
      icon: Icons.menu_book_outlined,
      itemsAsync: methodsAsync,
      filter: (m) => m.name != '-' && m.name.isNotEmpty,
      nameOf: (m) => m.name,
      subtitleOf: (m) {
        final count = counts[m.id] ?? 0;
        final parts = [
          if (m.author.isNotEmpty) m.author,
          '抽出 $count回',
        ];
        return parts.join(' ・ ');
      },
      imageUrlOf: (m) => null,
      onTapItem: (context, m) {
        debugPrint('[Antigravity] Action: メソッド一覧019から詳細020へ遷移 (id=${m.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MethodDetailScreen(method: m)),
        );
      },
      createScreenBuilder: () => const MethodCreateScreen(),
    );
  }
}
