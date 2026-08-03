import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create/create_form_widgets.dart';
import 'create/method_create_screen.dart';
import 'master_template.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../services/data_service.dart';
import '../utils/roast_range.dart';
import '../utils/youtube_util.dart';
import '../widgets/method_steps_editor.dart';
import '../widgets/youtube_embed.dart';

/// 020 メソッド詳細。
///
/// Cycle 20 T1-5d: 汎用マスターテンプレート(MasterDetailTemplate)を
/// T1-5a〜cのドリッパー/フィルター/グラインダー実装から流用した本実装。
/// メソッド固有の差分(発案者・抽出回数・注湯ステップ・参考URL)は
/// [MasterDetailTemplate.extraSections] で吸収する。
class MethodDetailScreen extends ConsumerWidget {
  final MethodMaster method;

  const MethodDetailScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(coffeeRecordsProvider);
    final stepsAsync = ref.watch(pouringStepsProvider);
    // T3-72d: 編集→保存→pop直後も最新値を表示するため、コンストラクタ引数
    // (遷移時点のスナップショット)ではなくmethodMasterProviderの最新値を使う。
    final methods = ref.watch(methodMasterProvider).value;
    final currentMethod = methods?.firstWhere((m) => m.id == method.id, orElse: () => method) ?? method;

    final extractionCount = logsAsync.maybeWhen(
      data: (logs) => logs.where((l) => l.methodId == currentMethod.id).length,
      orElse: () => 0,
    );

    final steps = stepsAsync.maybeWhen(
      data: (all) {
        final methodSteps = all.where((s) => s.methodId == currentMethod.id).toList()
          ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
        return methodSteps;
      },
      orElse: () => <PouringStep>[],
    );

    return MasterDetailTemplate(
      screen: AppScreen.methodDetail,
      icon: Icons.menu_book_outlined,
      title: currentMethod.name,
      fields: [
        ('メソッド名', currentMethod.name),
        ('発案者', currentMethod.author.isEmpty ? '-' : currentMethod.author),
        ('基準豆量', '${currentMethod.baseBeanWeight.toStringAsFixed(1)}g'),
        ('基準湯量', '${currentMethod.baseWaterAmount.toStringAsFixed(1)}g'),
        ('湯温', (currentMethod.temperature == null || currentMethod.temperature == 0) ? '-' : '${currentMethod.temperature!.toStringAsFixed(1)}℃'),
        ('推奨挽き目', currentMethod.grindSize ?? '-'),
        ('推奨器具', currentMethod.recommendedEquipment.isEmpty ? '-' : currentMethod.recommendedEquipment),
        ('推奨焙煎度', formatMethodRoastRange(currentMethod)),
        ('説明', currentMethod.description.isEmpty ? '-' : currentMethod.description),
        ('抽出回数', '$extractionCount回'),
      ],
      extraSections: [
        FormSection(
          icon: Icons.water_drop_outlined,
          title: '注湯ステップ',
          children: [
            MethodStepsEditor(
              initialSteps: steps,
              isEditing: false,
              baseBeanWeight: currentMethod.baseBeanWeight,
              onStepsChanged: (_) {},
            ),
          ],
        ),
        if (currentMethod.sourceUrl != null && currentMethod.sourceUrl!.isNotEmpty)
          FormSection(
            icon: Icons.link,
            title: '参考URL',
            children: [
              // T3-24: YouTube URL なら埋め込みプレーヤーを表示し、その下に
              // 従来の外部リンクも残す(外部ブラウザで開きたい人向け)。
              // YouTube 以外はリンクのみ(従来どおり)。
              if (youtubeVideoId(currentMethod.sourceUrl) case final videoId?) ...[
                YoutubeEmbed(videoId: videoId),
                const SizedBox(height: 8),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final uri = Uri.tryParse(currentMethod.sourceUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
                  }
                },
                child: Text(
                  currentMethod.sourceUrl!,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
      ],
      relatedLogFilter: (log) => log.methodId == currentMethod.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: メソッド詳細020から編集画面へ遷移 (id=${currentMethod.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MethodCreateScreen(editData: currentMethod)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: メソッド削除 (id=${currentMethod.id})');
        try {
          await ref.read(dataServiceProvider).deletePouringStepsForMethod(currentMethod.id);
          await ref.read(dataServiceProvider).deleteMethod(currentMethod.id);
          ref.read(methodMasterProvider.notifier).removeOptimistic(currentMethod.id);
          ref.invalidate(pouringStepsProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: メソッド削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
