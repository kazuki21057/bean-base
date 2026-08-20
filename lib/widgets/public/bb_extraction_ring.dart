// T5-B22(束3): 公開版の署名要素 `BbExtractionRing`。
//
// 正本は docs/android_monetization/デザイン方針.md §1.2・§8。
// CustomPainter実装。線幅は直径の6%(最小3)。トラック=ringTrack、
// 弧の色はmode=liveならlive、staticMode/thumbnailならprimary。
// ステップ境界の目盛は外周に2dpの線。thumbnailモードでは中央テキストを
// 描かない。Semantics(label: '抽出リング 経過◯分◯秒 / 全◯分')を必ず付ける。
//
// P210(抽出中画面)での「中央に目標湯量を表示」(§1.2)は画面固有の
// オーバーレイであり、本コンポーネント(汎用の時間ベースリング)の
// スコープ外(該当画面の実装タスクで対応する想定)。
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bean_base/theme/public/bb_theme.dart';

/// [BbExtractionRing]の表示モード。
///
/// 設計書(§1.2)では`static`という語を使うが、Dartの予約語`static`と
/// 衝突するため識別子は`staticMode`にしている(見た目・意味は同じ)。
enum BbExtractionRingMode { live, staticMode, thumbnail }

/// 抽出リング。抽出中(live)・ホーム/インサイトの静止表示(staticMode)・
/// 履歴行のサムネイル(thumbnail)を同一の描画ロジックで表す(§1.2)。
class BbExtractionRing extends StatelessWidget {
  const BbExtractionRing({
    super.key,
    required this.steps,
    required this.totalSeconds,
    required this.elapsedSeconds,
    required this.diameter,
    required this.mode,
  });

  /// 注湯ステップの区切り(秒数境界。外周の目盛描画用)。
  final List<double> steps;

  /// 計画総時間(秒)。円周全体に対応する。
  final double totalSeconds;

  /// 経過時間(秒)。塗られた弧の長さに対応する。
  final double elapsedSeconds;

  final double diameter;

  final BbExtractionRingMode mode;

  @override
  Widget build(BuildContext context) {
    final bbColors = context.bbColors;
    final colorScheme = Theme.of(context).colorScheme;
    final bbType = context.bbType;

    final clampedElapsed =
        totalSeconds <= 0 ? 0.0 : elapsedSeconds.clamp(0, totalSeconds).toDouble();
    final arcColor =
        mode == BbExtractionRingMode.live ? bbColors.live : colorScheme.primary;
    final elapsedText = _formatMinSec(clampedElapsed);
    final totalText = _formatMinutesOnly(totalSeconds);

    return Semantics(
      label: '抽出リング 経過$elapsedText / 全$totalText',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: CustomPaint(
          painter: _BbExtractionRingPainter(
            steps: steps,
            totalSeconds: totalSeconds,
            elapsedSeconds: clampedElapsed,
            trackColor: bbColors.ringTrack,
            arcColor: arcColor,
          ),
          child: mode == BbExtractionRingMode.thumbnail
              ? null
              : Center(
                  child: Text(
                    elapsedText,
                    style: diameter >= 180 ? bbType.numeralXl : bbType.numeralM,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}

String _formatMinSec(double seconds) {
  final total = seconds.round();
  final m = total ~/ 60;
  final s = total % 60;
  return '$m分$s秒';
}

String _formatMinutesOnly(double seconds) {
  final m = (seconds / 60).round();
  return '$m分';
}

class _BbExtractionRingPainter extends CustomPainter {
  _BbExtractionRingPainter({
    required this.steps,
    required this.totalSeconds,
    required this.elapsedSeconds,
    required this.trackColor,
    required this.arcColor,
  });

  final List<double> steps;
  final double totalSeconds;
  final double elapsedSeconds;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    final strokeWidth = math.max(diameter * 0.06, 3.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (diameter - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (totalSeconds > 0 && elapsedSeconds > 0) {
      final sweep =
          2 * math.pi * (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
      final arcPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
    }

    if (totalSeconds > 0 && steps.isNotEmpty) {
      final tickPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final outerRadius = radius + strokeWidth / 2;
      final innerRadius = outerRadius - diameter * 0.08;
      for (final stepSeconds in steps) {
        final ratio = (stepSeconds / totalSeconds).clamp(0.0, 1.0);
        final angle = -math.pi / 2 + 2 * math.pi * ratio;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + direction * innerRadius,
          center + direction * outerRadius,
          tickPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BbExtractionRingPainter oldDelegate) {
    return oldDelegate.steps != steps ||
        oldDelegate.totalSeconds != totalSeconds ||
        oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor;
  }
}
