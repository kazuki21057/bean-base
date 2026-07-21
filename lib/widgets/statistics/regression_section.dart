import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coffee_record.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/math/design_matrix.dart';
import '../../services/regression_service.dart';

/// F1: 重回帰分析セクション (設計書§5.2)。
///
/// T4-2c1 の範囲は設計書§5.2 の項目1〜4:
///   1. ヘッダ + 情報アイコン(§2.1.5 の注意3点をダイアログ表示)
///   2. モデルサマリ(n / 調整済みR² / AIC / 除外行数 / デフォルトスコア警告)
///   3. 係数テーブル(変数名 / β̂ / SE / t / p / VIF、有意判定・VIF警告・副文)
///   4. 残差 vs 予測値 散布図(等分散性の目視確認、設計書§2.1.3)
/// 項目5(AIで解釈)・項目6(予測ミニフォーム)は T4-2c2 で追加する。
///
/// 数値計算(β̂/SE/t/p/R²/AIC/VIF)は [RegressionService] に委譲し、本ウィジェットは
/// 表示のみを担う(CLAUDE.md 絶対規則: 計算は Dart ローカル実装)。
class RegressionSection extends ConsumerWidget {
  /// フィルタ適用済みの抽出履歴(statistics_screen 側で絞り込んだもの)。
  final List<CoffeeRecord> records;

  const RegressionSection({super.key, required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrigins = ref.watch(originMasterProvider);
    final service = ref.watch(regressionServiceProvider);

    return asyncOrigins.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('産地マスタの読み込みエラー: $err', style: const TextStyle(color: kMocha)),
      ),
      data: (origins) {
        final originById = {for (final o in origins) o.id: o};

        // 計画行列を先に組み、データ不足(§1.3)と線形従属(§2.1.1)を出し分ける。
        final design = buildRegressionMatrix(records, originById);
        final n = design.x.length;
        final p = design.columnNames.length - 1;
        // §1.3: F1 の最小条件は n ≥ 30 かつ n ≥ 5×説明変数。
        final required = math.max(30, 5 * p);

        if (n < required) {
          return _guidance('データが不足しています (必要: $required件, 現在: $n件)');
        }

        final result = service.fitDesign(design);
        if (result == null) {
          // Cholesky が失敗するケース = ランク落ち(設計書§2.1.1)。
          return _guidance('説明変数が線形従属です');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoRow(context),
            const SizedBox(height: 8),
            _modelSummary(result),
            const SizedBox(height: 16),
            _coefficientTable(result),
            const SizedBox(height: 20),
            const Text(
              '残差 vs 予測値',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso),
            ),
            const Text(
              '点が0の水平線周りに均等に散らばっていれば等分散の仮定が保たれています',
              style: TextStyle(fontSize: 11, color: kMocha),
            ),
            const SizedBox(height: 8),
            _residualPlot(result),
          ],
        );
      },
    );
  }

  Widget _guidance(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(message, style: const TextStyle(color: kMocha)),
        ),
      );

  // --- 1. 情報アイコン(§2.1.5 の注意3点) ---

  Widget _infoRow(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _showNotesDialog(context),
          icon: const Icon(Icons.info_outline, size: 18, color: kAccent),
          label: const Text('分析上の注意', style: TextStyle(fontSize: 12, color: kAccent)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
        ),
      );

  void _showNotesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('回帰分析を読むときの注意'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NoteBullet('スコア(0〜10の整数)は、本来は順位の尺度を等間隔の数値として扱う近似です。'),
            SizedBox(height: 10),
            _NoteBullet('観測データであり無作為化実験ではないため、係数は因果効果ではなく「関連の記述」です。'),
            SizedBox(height: 10),
            _NoteBullet('総合評価の初期値が7のため、未編集のまま保存された記録によるバイアスがあり得ます(下の警告を参照)。'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
        ],
      ),
    );
  }

  // --- 2. モデルサマリ ---

  Widget _modelSummary(RegressionResult r) {
    final defaultRatio = r.n == 0 ? 0.0 : r.defaultScoreCount / r.n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statChip('件数 n', '${r.n}'),
            _statChip('調整済み R²', r.adjR2.toStringAsFixed(3)),
            _statChip('AIC', r.aic.toStringAsFixed(1)),
            _statChip('除外行数', '${r.excludedRows}'),
          ],
        ),
        if (defaultRatio > 0.3) ...[
          const SizedBox(height: 10),
          _warningBanner(
            '総合評価が初期値7のままの記録が ${r.defaultScoreCount}件 '
            '(全体の${(defaultRatio * 100).toStringAsFixed(0)}%)あります。'
            '未編集保存によるバイアスの可能性があるため、結果は割り引いて解釈してください。',
          ),
        ],
      ],
    );
  }

  Widget _statChip(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kLatte),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: kMocha)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: kEspresso)),
          ],
        ),
      );

  Widget _warningBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF0C36D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB8860B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7A5A00))),
            ),
          ],
        ),
      );

  // --- 3. 係数テーブル ---

  Widget _coefficientTable(RegressionResult r) {
    // 有意水準は Bonferroni 補正(検定数 = 切片を除く係数の数)。
    final testCount = math.max(1, r.p);
    final alpha = 0.05 / testCount;

    // 切片を除いた係数を対象に表示(切片は解釈対象外だが参考として先頭に薄く残す)。
    final rows = <Widget>[];
    for (var i = 0; i < r.coefficients.length; i++) {
      final c = r.coefficients[i];
      final isIntercept = i == 0;
      final significant = !isIntercept && c.pValue < alpha;
      rows.add(_coefficientRow(c, isIntercept: isIntercept, significant: significant));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '係数(総合評価への影響)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso),
        ),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 6),
        Text(
          '* p < 0.05/$testCount ≒ ${alpha.toStringAsFixed(4)} で有意(Bonferroni補正)。'
          'VIF > 5 は多重共線性の注意サイン。',
          style: const TextStyle(fontSize: 10, color: kMocha),
        ),
      ],
    );
  }

  Widget _coefficientRow(RegressionCoefficient c,
      {required bool isIntercept, required bool significant}) {
    final vifWarn = !c.vif.isNaN && c.vif > 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: significant ? const Color(0xFFF3EDE3) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kLatte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name + (significant ? ' *' : ''),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: significant ? FontWeight.bold : FontWeight.w500,
                    color: isIntercept ? kMocha : kEspresso,
                  ),
                ),
              ),
              if (vifWarn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEAEA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE0A0A0)),
                  ),
                  child: Text('VIF ${_fmt(c.vif, 1)}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB03030))),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 14,
            runSpacing: 2,
            children: [
              _metric('β̂', _fmt(c.beta, 3)),
              _metric('SE', _fmt(c.se, 3)),
              _metric('t', _fmt(c.tValue, 2)),
              _metric('p', _formatP(c.pValue)),
              _metric('VIF', c.vif.isNaN ? '—' : _fmt(c.vif, 2)),
            ],
          ),
          if (!isIntercept) ...[
            const SizedBox(height: 4),
            Text(
              '1単位あたり ${c.beta >= 0 ? '+' : ''}${_fmt(c.beta, 2)} 点',
              style: const TextStyle(fontSize: 11, color: kAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: kEspresso),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(color: kMocha)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // --- 4. 残差 vs 予測値 散布図 ---

  Widget _residualPlot(RegressionResult r) {
    if (r.fitted.isEmpty) return const SizedBox.shrink();

    var minX = double.infinity, maxX = double.negativeInfinity;
    var maxAbsResidual = 0.0;
    for (var i = 0; i < r.fitted.length; i++) {
      final x = r.fitted[i];
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      final absR = r.residuals[i].abs();
      if (absR > maxAbsResidual) maxAbsResidual = absR;
    }
    final padX = (maxX - minX).abs() * 0.1 + 0.1;
    final yBound = maxAbsResidual * 1.15 + 0.05; // 0 を中央に置いて水平基準線を見やすくする

    return SizedBox(
      height: 240,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [
            for (var i = 0; i < r.fitted.length; i++)
              ScatterSpot(
                r.fitted[i],
                r.residuals[i],
                dotPainter: FlDotCirclePainter(
                  radius: 4,
                  color: kAccent.withValues(alpha: 0.7),
                  strokeWidth: 1,
                  strokeColor: Colors.black26,
                ),
              ),
          ],
          minX: minX - padX,
          maxX: maxX + padX,
          minY: -yBound,
          maxY: yBound,
          gridData: FlGridData(
            show: true,
            // y=0(残差ゼロ)の水平線を強調。
            checkToShowHorizontalLine: (value) => value == 0,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: kMocha.withValues(alpha: 0.6), strokeWidth: 1.2),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: kLatte)),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 22),
              axisNameWidget: Text('予測値', style: TextStyle(fontSize: 10, color: kMocha)),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              axisNameWidget: Text('残差', style: TextStyle(fontSize: 10, color: kMocha)),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          scatterTouchData: ScatterTouchData(
            enabled: true,
            touchTooltipData: ScatterTouchTooltipData(
              getTooltipItems: (spot) => ScatterTooltipItem(
                '予測 ${spot.x.toStringAsFixed(1)}\n残差 ${spot.y.toStringAsFixed(2)}',
                textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                bottomMargin: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- フォーマットヘルパー ---

  String _fmt(double v, int digits) {
    if (v.isNaN) return '—';
    if (v.isInfinite) return v > 0 ? '∞' : '-∞';
    return v.toStringAsFixed(digits);
  }

  String _formatP(double p) {
    if (p.isNaN) return '—';
    if (p < 0.001) return '<0.001';
    return p.toStringAsFixed(3);
  }
}

class _NoteBullet extends StatelessWidget {
  final String text;
  const _NoteBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 13)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
