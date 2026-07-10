import 'package:flutter/material.dart';
import '../screens/create/create_form_widgets.dart';

/// 残量%を表す瓶ビジュアル(静的、10%刻み11段階の描画)。
///
/// Cycle 20 T2-2a: 任意の残量%(0〜100の連続値)を受け取り、最も近い
/// 10%刻みの段階(0/10/20/…/100の11段階)にスナップして描画する。
/// 抽出履歴からの実際の残量算出(T2-2b)・0%瓶の非表示切替(T2-2c)は
/// 別タスクで接続する。
class BeanJarWidget extends StatelessWidget {
  final num percent;
  final String? label;
  final double width;
  final double height;

  const BeanJarWidget({
    super.key,
    required this.percent,
    this.label,
    this.width = 56,
    this.height = 76,
  });

  /// percent を最も近い10%刻みの段階(0,10,20,…,100のいずれか)にスナップした値。
  int get stage {
    final clamped = percent.clamp(0, 100);
    return ((clamped / 10).round() * 10).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final fillFraction = stage / 100;
    final innerHeight = height - 4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: kLatte, width: 2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
              bottom: Radius.circular(16),
            ),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                key: Key('bean_jar_fill_stage_$stage'),
                height: innerHeight * fillFraction,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kMocha.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$stage%',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: kEspresso),
        ),
        if (label != null)
          SizedBox(
            width: width + 16,
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: kMocha),
            ),
          ),
      ],
    );
  }
}
