import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../providers/data_providers.dart';
import '../routing/app_screen.dart';
import '../utils/image_utils.dart';
import 'create/create_form_widgets.dart';
import 'log_edit_screen.dart';
import 'mock/mock_scaffold.dart';
import 'stats_theory_screen.dart';

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
          trailing: const StatsTheoryLink(
            section: StatsTheorySection.intro,
            tooltip: 'この評価データが統計解析にどう使われるか',
          ),
          children: [
            _overallHero(),
            const SizedBox(height: 16),
            _sensoryRadar(),
            if (log.taste.isNotEmpty || log.concentration.isNotEmpty) ...[
              const SizedBox(height: 16),
              _tasteChips(),
            ],
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

  /// 総合スコアのヒーロー表示(T3-26)。アクセント色のカードに星+大きな数値。
  Widget _overallHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccent, kAccent.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('総合評価', style: TextStyle(color: kCream, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Text(
                '${log.scoreOverall}',
                style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1),
              ),
              const Text(' / 10', style: TextStyle(color: kCream, fontSize: 18, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  /// 6つの味覚軸の六角形レーダー(T3-26)。0〜10の目盛りを固定するため、
  /// 透明のmin(0)/max(10)ダミーデータセットを重ねる(radar_chart_widget.dartと同手法)。
  Widget _sensoryRadar() {
    const axisTitles = ['香り', '酸味', '苦味', '甘み', '複雑さ', '風味'];
    final values = <double>[
      log.scoreFragrance.toDouble(),
      log.scoreAcidity.toDouble(),
      log.scoreBitterness.toDouble(),
      log.scoreSweetness.toDouble(),
      log.scoreComplexity.toDouble(),
      log.scoreFlavor.toDouble(),
    ];

    return AspectRatio(
      aspectRatio: 1.25,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          dataSets: [
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              borderWidth: 0,
              dataEntries: List.filled(6, const RadarEntry(value: 0.0)),
            ),
            RadarDataSet(
              fillColor: Colors.transparent,
              borderColor: Colors.transparent,
              entryRadius: 0,
              borderWidth: 0,
              dataEntries: List.filled(6, const RadarEntry(value: 10.0)),
            ),
            RadarDataSet(
              fillColor: kAccent.withValues(alpha: 0.35),
              borderColor: kAccent,
              entryRadius: 3,
              borderWidth: 2,
              dataEntries: [for (final v in values) RadarEntry(value: v)],
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.15,
          titleTextStyle: const TextStyle(color: kEspresso, fontSize: 12, fontWeight: FontWeight.bold),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: kMocha, fontSize: 9),
          tickBorderData: const BorderSide(color: Colors.transparent),
          gridBorderData: BorderSide(color: kLatte, width: 1),
          getTitle: (index, angle) {
            if (index < axisTitles.length) {
              // 軸名の下に実数値を添えて、レーダー形状と正確な値の両方を読めるようにする。
              return RadarChartTitle(text: '${axisTitles[index]} ${values[index].toStringAsFixed(0)}', angle: angle);
            }
            return const RadarChartTitle(text: '');
          },
        ),
      ),
    );
  }

  /// テイスト・濃度のチップ(T3-26)。
  Widget _tasteChips() {
    final tastes = [log.taste, log.concentration].where((s) => s.isNotEmpty).toList();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in tastes)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kLatte),
              ),
              child: Text(t, style: const TextStyle(fontSize: 13, color: kEspresso)),
            ),
        ],
      ),
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
