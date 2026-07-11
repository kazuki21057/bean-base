import 'package:flutter/material.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/statistics_service.dart';

/// Cycle 20 T2-6: 見た目をPhase2共通パレット(コーヒートーン)・日本語ラベルへ
/// 統一。KPI集計ロジック自体は`StatisticsService.calculateKPI`のまま変更なし。
class KpiCards extends StatelessWidget {
  final StatisticsKPI kpi;

  const KpiCards({super.key, required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard('総抽出数', '${kpi.totalBrews}', Icons.coffee),
        const SizedBox(width: 12),
        _buildCard('豆使用量(g)', kpi.totalBeansWeight.toStringAsFixed(1), Icons.monitor_weight_outlined),
        const SizedBox(width: 12),
        _buildCard('平均スコア', kpi.averageScore.toStringAsFixed(1), Icons.star_outline),
      ],
    );
  }

  Widget _buildCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLatte),
        ),
        child: Column(
          children: [
            Icon(icon, color: kMocha),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kEspresso),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: kMocha),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
