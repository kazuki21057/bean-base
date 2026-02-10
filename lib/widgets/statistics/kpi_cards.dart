import 'package:flutter/material.dart';
import '../../services/statistics_service.dart';

class KpiCards extends StatelessWidget {
  final StatisticsKPI kpi;

  const KpiCards({super.key, required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard(context, 'Total Brews', '${kpi.totalBrews}', Icons.coffee),
        const SizedBox(width: 8),
        _buildCard(context, 'Beans (g)', kpi.totalBeansWeight.toStringAsFixed(1), Icons.monitor_weight),
        const SizedBox(width: 8),
        _buildCard(context, 'Avg Score', kpi.averageScore.toStringAsFixed(1), Icons.star),
      ],
    );
  }

  Widget _buildCard(BuildContext context, String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
