import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../screens/create/create_form_widgets.dart';
import '../../services/gp_service.dart';

/// ヒートマップに重ねる実測点(T3-53 設計書§5)。
class GpHeatmapPoint {
  final double temperature;
  final double brewRatio;
  final int score;

  /// true = 表示中の豆自身の記録、false = 参考(現状は未使用、将来の拡張用)。
  final bool isPrimary;

  const GpHeatmapPoint({
    required this.temperature,
    required this.brewRatio,
    required this.score,
    this.isPrimary = true,
  });
}

/// 予測総合評価マップ(湯温×湯:豆比。時間・粒度は固定)。
/// 030(レシピ探索)と045(探索の検証状況、T3-53)で共用する。
/// [overlay] を渡すと、実測点があるセルに件数バッジと枠を描く(T3-53)。
/// [overlay] が空のときは従来(T3-52c 以前)と完全に同じ見た目になる。
class GpHeatmap extends StatelessWidget {
  final GpModel model;
  final int fixedTime;
  final double fixedGrind;
  final List<GpHeatmapPoint> overlay;

  const GpHeatmap({
    super.key,
    required this.model,
    required this.fixedTime,
    required this.fixedGrind,
    this.overlay = const [],
  });

  /// 湯温軸(045の実測セル数カウントでも共用、T3-53c)。
  static const temps = <double>[80, 85, 90, 95];

  /// 比率軸(045の実測セル数カウントでも共用、T3-53c)。
  static const ratios = <double>[14, 15, 16, 17, 18];

  @override
  Widget build(BuildContext context) {
    final service = GpService();
    final grid = <List<double>>[];
    var muMin = double.infinity;
    var muMax = double.negativeInfinity;
    for (final t in temps) {
      final row = <double>[];
      for (final r in ratios) {
        final mu = service.predict(model, t, r, fixedTime, fixedGrind).mean;
        row.add(mu);
        muMin = math.min(muMin, mu);
        muMax = math.max(muMax, mu);
      }
      grid.add(row);
    }

    var bestI = 0, bestJ = 0;
    for (var i = 0; i < grid.length; i++) {
      for (var j = 0; j < grid[i].length; j++) {
        if (grid[i][j] > grid[bestI][bestJ]) {
          bestI = i;
          bestJ = j;
        }
      }
    }

    // セル↔実測点の対応(設計書§5): 軸刻みの半分 (湯温±2.5, 比率±0.5)。
    final counts = List.generate(temps.length, (_) => List.filled(ratios.length, 0));
    for (final p in overlay) {
      for (var i = 0; i < temps.length; i++) {
        if ((p.temperature - temps[i]).abs() > 2.5) continue;
        for (var j = 0; j < ratios.length; j++) {
          if ((p.brewRatio - ratios[j]).abs() > 0.5) continue;
          counts[i][j]++;
        }
      }
    }

    final range = (muMax - muMin).abs() < 1e-9 ? 1.0 : (muMax - muMin);
    return Table(
      defaultColumnWidth: const FlexColumnWidth(1),
      children: [
        TableRow(
          children: [
            _labelCell('湯温\\比率', bold: true),
            for (final r in ratios) _labelCell('1:${r.toStringAsFixed(0)}', bold: true),
          ],
        ),
        for (var i = 0; i < temps.length; i++)
          TableRow(
            children: [
              _labelCell('${temps[i].toStringAsFixed(0)}℃', bold: true),
              for (var j = 0; j < ratios.length; j++)
                _valueCell(
                  grid[i][j],
                  (grid[i][j] - muMin) / range,
                  highlighted: i == bestI && j == bestJ,
                  count: counts[i][j],
                ),
            ],
          ),
      ],
    );
  }

  Widget _labelCell(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: kEspresso,
          ),
        ),
      );

  Widget _valueCell(double mu, double t, {bool highlighted = false, int count = 0}) {
    final bg = Color.lerp(kCream, kAccent, t.clamp(0.0, 1.0)) ?? kCream;
    final textColor = t > 0.55 ? Colors.white : kEspresso;
    return Container(
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: highlighted ? Border.all(color: kEspresso, width: 2) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            mu.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: textColor, fontWeight: highlighted ? FontWeight.bold : FontWeight.normal),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              bottom: 1,
              child: Text(
                '●$count',
                style: TextStyle(fontSize: 9, color: textColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
