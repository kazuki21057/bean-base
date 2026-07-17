import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/create_form_widgets.dart';
import 'log_edit_screen.dart';
import 'mock/mock_scaffold.dart';

/// 003 抽出履歴(詳細)。
///
/// Cycle 20 T1-4b: UIモック(LogDetailMockScreen)の骨格に実データを接続した
/// 本実装。編集アクションから既存の LogEditScreen(DataService.updateCoffeeRecord
/// で保存)へ遷移する。
class LogDetailScreen extends ConsumerWidget {
  final CoffeeRecord log;

  const LogDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beansAsync = ref.watch(beanMasterProvider);
    final methodsAsync = ref.watch(methodMasterProvider);
    final grindersAsync = ref.watch(grinderMasterProvider);
    final drippersAsync = ref.watch(dripperMasterProvider);
    final filtersAsync = ref.watch(filterMasterProvider);

    String resolveName(String id, AsyncValue<List<dynamic>> asyncValue) {
      if (id.isEmpty) return '-';
      return asyncValue.maybeWhen(
        data: (list) {
          for (final item in list) {
            if (item.id == id) return item.name as String;
          }
          return id;
        },
        orElse: () => id,
      );
    }

    final beanName = resolveName(log.beanId, beansAsync);
    final methodName = resolveName(log.methodId, methodsAsync);
    final grinderName = resolveName(log.grinderId, grindersAsync);
    final dripperName = resolveName(log.dripperId, drippersAsync);
    final filterName = resolveName(log.filterId, filtersAsync);
    final beanDisplay =
        log.roastLevel.isEmpty ? beanName : '$beanName (${log.roastLevel})';

    String? imageUrl = log.beanImageUrl;
    if ((imageUrl == null || imageUrl.isEmpty) && log.beanId.isNotEmpty) {
      beansAsync.whenData((beans) {
        for (final b in beans) {
          if (b.id == log.beanId) {
            imageUrl = b.imageUrl;
            break;
          }
        }
      });
    }
    final optimizedImageUrl = ImageUtils.getOptimizedImageUrl(imageUrl);

    return MockScreenScaffold(
      screen: AppScreen.logDetail,
      showSettingsAction: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '編集',
          onPressed: () {
            debugPrint('[Antigravity] Action: 抽出履歴詳細003から編集画面へ遷移 (id=${log.id})');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LogEditScreen(log: log)),
            );
          },
        ),
      ],
      children: [
        if (optimizedImageUrl != null)
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(optimizedImageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        FormSection(
          icon: Icons.coffee,
          title: '抽出情報',
          children: [
            MockInfoRow(label: '日時', value: _formatDateTime(log.brewedAt)),
            MockInfoRow(label: '豆', value: beanDisplay),
            if (methodName != '-') MockInfoRow(label: 'メソッド', value: methodName),
            if (grinderName != '-')
              MockInfoRow(label: 'グラインダー', value: grinderName),
            if (dripperName != '-')
              MockInfoRow(label: 'ドリッパー', value: dripperName),
            if (filterName != '-')
              MockInfoRow(label: 'フィルター', value: filterName),
            MockInfoRow(
              label: '豆量 / 湯量',
              value: '${_fmtNum(log.beanWeight)} g / ${_fmtNum(log.totalWater)} g',
            ),
            if (log.temperature > 0)
              MockInfoRow(label: '湯温', value: '${_fmtNum(log.temperature)} ℃'),
            if (log.bloomingWater > 0 || log.bloomingTime > 0)
              MockInfoRow(
                label: '蒸らし',
                value: '${_fmtNum(log.bloomingWater)} g / ${log.bloomingTime} 秒',
              ),
            if (log.totalTime > 0)
              MockInfoRow(label: '総時間', value: _formatTime(log.totalTime)),
            if (log.grindSize.isNotEmpty)
              MockInfoRow(label: '挽き目', value: log.grindSize),
          ],
        ),
        FormSection(
          icon: Icons.star_outline,
          title: '評価',
          children: [
            MockInfoRow(label: '香り', value: '${log.scoreFragrance}/10'),
            MockInfoRow(label: '酸味', value: '${log.scoreAcidity}/10'),
            MockInfoRow(label: '苦味', value: '${log.scoreBitterness}/10'),
            MockInfoRow(label: '甘み', value: '${log.scoreSweetness}/10'),
            MockInfoRow(label: '複雑さ', value: '${log.scoreComplexity}/10'),
            MockInfoRow(label: '風味', value: '${log.scoreFlavor}/10'),
            MockInfoRow(label: '総合', value: '${log.scoreOverall}/10'),
            if (log.taste.isNotEmpty || log.concentration.isNotEmpty)
              MockInfoRow(
                label: 'テイスト',
                value: [log.taste, log.concentration]
                    .where((s) => s.isNotEmpty)
                    .join(' ・ '),
              ),
          ],
        ),
        FormSection(
          icon: Icons.edit_note,
          title: 'コメント',
          children: [
            Text(
              log.comment.isEmpty ? 'コメントなし' : log.comment,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}/$m/$day $h:$min';
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtNum(double v) => v.toStringAsFixed(1);
}
