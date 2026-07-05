import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/bean_create_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 010 豆管理(カード) — UIモック。焙煎所/豆名/煎り度/画像/残量+0%表示切替+＋。
/// 本実装は T1-6a。
class BeanListMockScreen extends StatelessWidget {
  const BeanListMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const beans = [
      ('岬の焙煎所', 'エチオピア イルガチェフェ', '浅煎り', 60),
      ('岬の焙煎所', 'タンザニア キリマンジャロ', '中深煎り', 35),
      ('Navy', 'インドネシア ブルーリントン', '深煎り', 80),
      ('Navy', 'ケニア ニエリ', '中煎り', 10),
    ];
    return MockScreenScaffold(
      screen: AppScreen.beanList,
      floatingActionButton: MockAddFab(
        tooltip: '新規豆追加(012)へ',
        destinationBuilder: () => const BeanCreateScreen(),
      ),
      children: [
        const MockSwitchTile(label: '残量0%の豆も表示する', initialValue: false),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (store, name, roast, percent) in beans)
              _BeanCard(
                  store: store, name: name, roast: roast, percent: percent),
          ],
        ),
      ],
    );
  }
}

class _BeanCard extends StatelessWidget {
  final String store;
  final String name;
  final String roast;
  final int percent;

  const _BeanCard({
    required this.store,
    required this.name,
    required this.roast,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BeanDetailMockScreen()),
      ),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLatte),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kLatte),
              ),
              child: const Icon(Icons.coffee, size: 36, color: kMocha),
            ),
            const SizedBox(height: 8),
            Text(store, style: const TextStyle(fontSize: 11, color: kMocha)),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(roast,
                      style: const TextStyle(fontSize: 11, color: kEspresso)),
                ),
                const Spacer(),
                Text('残 $percent%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kEspresso)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: kCream,
                color: kMocha,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
