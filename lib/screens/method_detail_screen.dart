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
import '../widgets/method_steps_editor.dart';

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

    final extractionCount = logsAsync.maybeWhen(
      data: (logs) => logs.where((l) => l.methodId == method.id).length,
      orElse: () => 0,
    );

    final steps = stepsAsync.maybeWhen(
      data: (all) {
        final methodSteps = all.where((s) => s.methodId == method.id).toList()
          ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));
        return methodSteps;
      },
      orElse: () => <PouringStep>[],
    );

    return MasterDetailTemplate(
      screen: AppScreen.methodDetail,
      icon: Icons.menu_book_outlined,
      title: method.name,
      fields: [
        ('メソッド名', method.name),
        ('発案者', method.author.isEmpty ? '-' : method.author),
        ('基準豆量', '${method.baseBeanWeight.toStringAsFixed(1)}g'),
        ('基準湯量', '${method.baseWaterAmount.toStringAsFixed(1)}g'),
        ('湯温', (method.temperature == null || method.temperature == 0) ? '-' : '${method.temperature!.toStringAsFixed(1)}℃'),
        ('推奨挽き目', method.grindSize ?? '-'),
        ('推奨器具', method.recommendedEquipment.isEmpty ? '-' : method.recommendedEquipment),
        ('説明', method.description.isEmpty ? '-' : method.description),
        ('抽出回数', '$extractionCount回'),
      ],
      extraSections: [
        FormSection(
          icon: Icons.water_drop_outlined,
          title: '注湯ステップ (Pouring Steps)',
          children: [
            MethodStepsEditor(
              initialSteps: steps,
              isEditing: false,
              baseBeanWeight: method.baseBeanWeight,
              onStepsChanged: (_) {},
            ),
          ],
        ),
        if (method.sourceUrl != null && method.sourceUrl!.isNotEmpty)
          FormSection(
            icon: Icons.link,
            title: '参考URL',
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final uri = Uri.tryParse(method.sourceUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
                  }
                },
                child: Text(
                  method.sourceUrl!,
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
      ],
      relatedLogFilter: (log) => log.methodId == method.id,
      onEdit: () {
        debugPrint('[Antigravity] Action: メソッド詳細020から編集画面へ遷移 (id=${method.id})');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MethodCreateScreen(editData: method)),
        );
      },
      onDelete: () async {
        debugPrint('[Antigravity] Action: メソッド削除 (id=${method.id})');
        try {
          await ref.read(dataServiceProvider).deletePouringStepsForMethod(method.id);
          await ref.read(dataServiceProvider).deleteMethod(method.id);
          ref.invalidate(methodMasterProvider);
          ref.invalidate(pouringStepsProvider);
        } catch (e) {
          debugPrint('[Antigravity] Error: メソッド削除に失敗 $e');
          rethrow;
        }
      },
    );
  }
}
