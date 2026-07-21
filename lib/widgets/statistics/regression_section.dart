import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/coffee_record.dart';
import '../../providers/data_providers.dart';
import '../../screens/create/create_form_widgets.dart';
import '../../services/ai_analysis_service.dart';
import '../../services/math/design_matrix.dart';
import '../../services/math/encoding.dart';
import '../../services/regression_service.dart';

/// F1: 重回帰分析セクション (設計書§5.2)。
///
/// 設計書§5.2 の項目1〜6:
///   1. ヘッダ + 情報アイコン(§2.1.5 の注意3点をダイアログ表示)  [T4-2c1]
///   2. モデルサマリ(n / 調整済みR² / AIC / 除外行数 / デフォルトスコア警告)  [T4-2c1]
///   3. 係数テーブル(変数名 / β̂ / SE / t / p / VIF、有意判定・VIF警告・副文)  [T4-2c1]
///   4. 残差 vs 予測値 散布図(等分散性の目視確認、設計書§2.1.3)  [T4-2c1]
///   5. AIで解釈(§8.1 の `interpretRegression`、既存 AiAnalysisService パターン)  [T4-2c2]
///   6. このモデルで予測(湯温/比率/時間/焙煎度/産地 → predict() の点推定+95%予測区間)  [T4-2c2]
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
            const SizedBox(height: 20),
            _RegressionPredictionForm(model: result),
            const SizedBox(height: 20),
            _RegressionAiSection(model: result),
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

/// 設計書§5.2 項目6: このモデルで予測するミニフォーム(T4-2c2)。
/// 条件を入力 → [RegressionService.predict] の点推定+95%予測区間(T-25)を表示。
class _RegressionPredictionForm extends ConsumerStatefulWidget {
  final RegressionResult model;
  const _RegressionPredictionForm({required this.model});

  @override
  ConsumerState<_RegressionPredictionForm> createState() =>
      _RegressionPredictionFormState();
}

class _RegressionPredictionFormState
    extends ConsumerState<_RegressionPredictionForm> {
  late final TextEditingController _tempCtrl;
  late final TextEditingController _ratioCtrl;
  late final TextEditingController _timeCtrl;
  String _roastLabel = '中煎り';
  String? _originLevel;
  ({double point, double lower, double upper})? _result;

  // 順序値の重複を避けた代表ラベル(設計書§3.5 の roastOrdinalMap の正規5値)。
  static const _roastOptions = ['浅煎り', '中浅煎り', '中煎り', '中深煎り', '深煎り'];

  @override
  void initState() {
    super.initState();
    final cm = widget.model.design.centerMeans;
    // 初期値は訓練データの平均(中心)。この点での予測はほぼ切片に一致する。
    _tempCtrl = TextEditingController(text: (cm['temperature'] ?? 90).toStringAsFixed(1));
    _ratioCtrl = TextEditingController(text: (cm['brewRatio'] ?? 15).toStringAsFixed(1));
    _timeCtrl = TextEditingController(text: (cm['totalTimeMin'] ?? 3).toStringAsFixed(1));
    _originLevel = widget.model.design.baseLevel;
  }

  @override
  void dispose() {
    _tempCtrl.dispose();
    _ratioCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _predict(String originLevel) {
    final cm = widget.model.design.centerMeans;
    final temp = double.tryParse(_tempCtrl.text.trim()) ?? cm['temperature'] ?? 90;
    final ratio = double.tryParse(_ratioCtrl.text.trim()) ?? cm['brewRatio'] ?? 15;
    final time = double.tryParse(_timeCtrl.text.trim()) ?? cm['totalTimeMin'] ?? 3;
    final roast = roastOrdinalMap[_roastLabel] ?? 3.0;

    final r = ref.read(regressionServiceProvider).predict(
          widget.model,
          temperature: temp,
          brewRatio: ratio,
          totalTimeMin: time,
          roastOrdinal: roast,
          originLevel: originLevel,
        );
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final originOptions = [
      widget.model.design.baseLevel,
      ...widget.model.design.dummyLevels,
    ];
    // 選択中の産地が現モデルの水準に無ければ基準水準へフォールバック。
    final selectedOrigin =
        originOptions.contains(_originLevel) ? _originLevel! : widget.model.design.baseLevel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLatte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('このモデルで予測',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kEspresso)),
          const SizedBox(height: 2),
          const Text('抽出条件を入れると総合評価の予測値と95%予測区間を表示します',
              style: TextStyle(fontSize: 11, color: kMocha)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numField('湯温', _tempCtrl, '℃')),
              const SizedBox(width: 10),
              Expanded(child: _numField('湯量比(湯/豆)', _ratioCtrl, '倍')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _numField('総抽出時間', _timeCtrl, '分')),
              const SizedBox(width: 10),
              Expanded(child: _roastDropdown()),
            ],
          ),
          const SizedBox(height: 10),
          _originDropdown(originOptions, selectedOrigin),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _predict(selectedOrigin),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('予測する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            _resultCard(_result!),
          ],
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController ctrl, String suffix) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: kMocha),
        suffixText: suffix,
        isDense: true,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kAccent)),
      ),
    );
  }

  Widget _roastDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _roastLabel,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: kEspresso),
      decoration: const InputDecoration(
        labelText: '焙煎度',
        labelStyle: TextStyle(fontSize: 12, color: kMocha),
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        for (final label in _roastOptions)
          DropdownMenuItem(value: label, child: Text(label)),
      ],
      onChanged: (v) => setState(() => _roastLabel = v ?? _roastLabel),
    );
  }

  Widget _originDropdown(List<String> options, String selected) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: kEspresso),
      decoration: const InputDecoration(
        labelText: '産地',
        labelStyle: TextStyle(fontSize: 12, color: kMocha),
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        for (final level in options)
          DropdownMenuItem(value: level, child: Text(level)),
      ],
      onChanged: (v) => setState(() => _originLevel = v),
    );
  }

  Widget _resultCard(({double point, double lower, double upper}) r) {
    final outOfRange = r.point < 0 || r.point > 10;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('予測される総合評価', style: TextStyle(fontSize: 11, color: kMocha)),
          const SizedBox(height: 2),
          Text('${r.point.toStringAsFixed(2)} 点',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kEspresso)),
          const SizedBox(height: 4),
          Text('95%予測区間: ${r.lower.toStringAsFixed(2)} 〜 ${r.upper.toStringAsFixed(2)} 点',
              style: const TextStyle(fontSize: 12, color: kMocha)),
          if (outOfRange) ...[
            const SizedBox(height: 4),
            const Text('※ 0〜10の範囲外です。訓練データから離れた条件での外挿の可能性があります。',
                style: TextStyle(fontSize: 10, color: Color(0xFFB03030))),
          ],
        ],
      ),
    );
  }
}

/// 設計書§5.2 項目5: 回帰結果のAI解釈(T4-2c2)。
/// §8.1 のプロンプトで Gemini を呼ぶ。既存 PCA の AI 分析と同じ操作感。
class _RegressionAiSection extends ConsumerStatefulWidget {
  final RegressionResult model;
  const _RegressionAiSection({required this.model});

  @override
  ConsumerState<_RegressionAiSection> createState() => _RegressionAiSectionState();
}

class _RegressionAiSectionState extends ConsumerState<_RegressionAiSection> {
  bool _loading = false;
  String? _result;

  Future<void> _run() async {
    final prefs = await SharedPreferences.getInstance();
    var apiKey = prefs.getString('gemini_api_key');
    if ((apiKey == null || apiKey.isEmpty) && mounted) {
      apiKey = await _askApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        await prefs.setString('gemini_api_key', apiKey);
      }
    }
    if (apiKey == null || apiKey.isEmpty) return;

    setState(() => _loading = true);
    try {
      debugPrint('[Antigravity] Action: 回帰結果のAI解釈を要求 (n=${widget.model.n})');
      final text = await ref.read(aiAnalysisServiceProvider).interpretRegression(widget.model, apiKey);
      if (mounted) setState(() => _result = text);
    } catch (e) {
      debugPrint('[Antigravity] Error: interpretRegression 失敗: $e');
      if (mounted) setState(() => _result = 'エラー: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askApiKey() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini APIキーを入力'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'APIキー',
            hintText: 'Google Gemini のAPIキー',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('保存')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_result != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text('AI解釈',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.deepPurple.shade800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_result!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Center(
          child: ElevatedButton.icon(
            onPressed: _run,
            icon: const Icon(Icons.psychology),
            label: Text(_result == null ? 'AIで解釈する' : '再解釈する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade50,
              foregroundColor: Colors.deepPurple,
            ),
          ),
        ),
      ],
    );
  }
}
