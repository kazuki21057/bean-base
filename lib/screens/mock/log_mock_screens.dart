import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 002 抽出履歴(リスト) — UIモック。日時/豆/メソッド/点数。
/// スワイプ→評価継承(T1-4c)は後続タスク。本実装は T1-4a。
class LogListMockScreen extends StatelessWidget {
  const LogListMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('2026/07/04 07:30', 'エチオピア イルガチェフェ', '4:6メソッド', 8),
      ('2026/07/03 08:02', 'タンザニア キリマンジャロ', 'V60 Standard', 7),
      ('2026/07/02 07:45', 'インドネシア ブルーリントン', '4:6メソッド', 7),
      ('2026/07/01 07:20', 'ケニア ニエリ', 'V60 Standard', 8),
      ('2026/06/30 07:55', 'エチオピア モカ ボンベ', '4:6メソッド', 5),
      ('2026/06/28 08:10', 'エチオピア イルガチェフェ', '4:6メソッド', 7),
    ];
    return MockScreenScaffold(
      screen: AppScreen.logList,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kLatte.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '← 行を左にスワイプすると評価を引き継いで再抽出できます(モック・後続タスクで実装)',
            style: TextStyle(fontSize: 12, color: kMocha),
          ),
        ),
        for (final (date, bean, method, score) in rows)
          MockListRow(
            icon: Icons.coffee,
            title: bean,
            subtitle: '$date ・ $method',
            trailing: MockScoreBadge(score: score),
          ),
      ],
    );
  }
}

/// 003 抽出履歴(詳細) — UIモック。全情報表示+編集ボタン。本実装は T1-4b。
class LogDetailMockScreen extends StatelessWidget {
  const LogDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.logDetail,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '編集(モック)',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UIモックです。編集は後続タスクで実装されます。')),
          ),
        ),
      ],
      children: const [
        FormSection(
          icon: Icons.coffee,
          title: '抽出情報',
          children: [
            MockInfoRow(label: '日時', value: '2026/07/04 07:30'),
            MockInfoRow(label: '豆', value: 'エチオピア イルガチェフェ (浅煎り)'),
            MockInfoRow(label: 'メソッド', value: '4:6メソッド'),
            MockInfoRow(label: 'グラインダー', value: 'コマンダンテ C40 (20クリック)'),
            MockInfoRow(label: 'ドリッパー', value: 'HARIO V60 02'),
            MockInfoRow(label: 'フィルター', value: 'V60ペーパー 02'),
            MockInfoRow(label: '豆量 / 湯量', value: '20 g / 300 g'),
            MockInfoRow(label: '湯温', value: '92 ℃'),
            MockInfoRow(label: '蒸らし', value: '60 g / 45 秒'),
            MockInfoRow(label: '総時間', value: '3:30'),
          ],
        ),
        FormSection(
          icon: Icons.star_outline,
          title: '評価',
          children: [
            MockInfoRow(label: '香り / 酸味', value: '8 / 7'),
            MockInfoRow(label: '苦味 / 甘み', value: '4 / 7'),
            MockInfoRow(label: '複雑さ / 風味', value: '6 / 8'),
            MockInfoRow(label: '総合', value: '8'),
            MockInfoRow(label: 'テイスト', value: 'すっきり ・ ちょうど良い'),
          ],
        ),
        FormSection(
          icon: Icons.edit_note,
          title: 'コメント',
          children: [
            Text(
              '柑橘系の酸が明るく、後味に紅茶のような余韻。蒸らしをもう5秒伸ばしても良いかもしれない。',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ],
    );
  }
}
