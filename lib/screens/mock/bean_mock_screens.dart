import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 011 豆管理(詳細) — UIモック。全情報・編集・関連履歴5件。本実装は T1-6b。
class BeanDetailMockScreen extends StatelessWidget {
  const BeanDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.beanDetail,
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
          title: '豆情報',
          children: [
            MockImagePicker(label: '豆の画像(登録済みモック)'),
            MockInfoRow(label: '豆名', value: 'エチオピア イルガチェフェ'),
            MockInfoRow(label: '焙煎所', value: '岬の焙煎所'),
            MockInfoRow(label: '産地', value: 'エチオピア'),
            MockInfoRow(label: '品種・精製', value: 'ウォッシュド'),
            MockInfoRow(label: '煎り度', value: '浅煎り'),
            MockInfoRow(label: '購入日', value: '2026/06/15'),
            MockInfoRow(label: '残量', value: '60% (在庫あり)'),
          ],
        ),
        FormSection(
          icon: Icons.history,
          title: 'この豆の抽出履歴 5件',
          children: [
            MockListRow(
              icon: Icons.coffee,
              title: '2026/07/04 07:30 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/06/28 08:10 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 7),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/06/25 07:40 ・ V60 Standard',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/06/22 08:00 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 6),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/06/18 07:35 ・ V60 Standard',
              trailing: MockScoreBadge(score: 7),
            ),
          ],
        ),
      ],
    );
  }
}
