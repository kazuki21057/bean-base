import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 001 ダッシュボード — UIモック。黒板風ヘッダ+残豆量(瓶)+直近5件。
/// 本実装は T1-3(骨組み)/T2-1b(黒板風本実装)。
class DashboardMockScreen extends StatelessWidget {
  const DashboardMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: AppScreen.dashboard,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: '設定(090)へ',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UIモックです。090への遷移は後続タスクで実装されます。')),
          ),
        ),
      ],
      children: [
        // 黒板風ウェルカムボード(T2-1aで本テーマ化)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3E33),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8D6E63), width: 6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Today's BeanBase ☕",
                style: TextStyle(
                  color: Color(0xFFF5F0E1),
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '今月の抽出: 12杯 / 平均スコア: 7.2\nおすすめ: エチオピア イルガチェフェ (残 60%)',
                style: TextStyle(
                  color: Color(0xFFD7CCC8),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        FormSection(
          icon: Icons.inventory_2_outlined,
          title: '残豆量',
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  MockBeanJar(name: 'イルガチェフェ', percent: 60),
                  SizedBox(width: 12),
                  MockBeanJar(name: 'キリマンジャロ', percent: 35),
                  SizedBox(width: 12),
                  MockBeanJar(name: 'ブルーリントン', percent: 80),
                  SizedBox(width: 12),
                  MockBeanJar(name: 'ニエリ', percent: 10),
                  SizedBox(width: 12),
                  MockBeanJar(name: 'モカ ボンベ', percent: 0),
                ],
              ),
            ),
            const MockSwitchTile(label: '残量0%の豆も表示する', initialValue: false),
          ],
        ),
        FormSection(
          icon: Icons.history,
          title: '直近の抽出 5件',
          children: const [
            MockListRow(
              icon: Icons.coffee,
              title: 'エチオピア イルガチェフェ',
              subtitle: '2026/07/04 07:30 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: 'タンザニア キリマンジャロ',
              subtitle: '2026/07/03 08:02 ・ V60 Standard',
              trailing: MockScoreBadge(score: 7),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: 'インドネシア ブルーリントン',
              subtitle: '2026/07/02 07:45 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 7),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: 'ケニア ニエリ',
              subtitle: '2026/07/01 07:20 ・ V60 Standard',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: 'エチオピア モカ ボンベ',
              subtitle: '2026/06/30 07:55 ・ 4:6メソッド',
              trailing: MockScoreBadge(score: 5),
            ),
          ],
        ),
      ],
    );
  }
}
