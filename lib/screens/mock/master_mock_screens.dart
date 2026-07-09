import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import '../create/filter_create_screen.dart';
import '../create/grinder_create_screen.dart';
import '../create/method_create_screen.dart';
import 'mock_scaffold.dart';

/// 013/016/019/022 の各マスター管理(リスト)と 014/017/020/023 の各詳細のUIモック。
/// 本実装は T1-5a〜d の汎用テンプレートで置き換わる予定。

/// 汎用マスター一覧モック(画像左・名前右+＋ボタン)。
class _MasterListMock extends StatelessWidget {
  final AppScreen screen;
  final IconData icon;
  final List<(String, String)> items; // (名前, サブテキスト)
  final Widget Function() addDestination;
  final Widget Function() detailDestination;

  const _MasterListMock({
    required this.screen,
    required this.icon,
    required this.items,
    required this.addDestination,
    required this.detailDestination,
  });

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: screen,
      floatingActionButton: MockAddFab(
        tooltip: '新規追加へ',
        destinationBuilder: addDestination,
      ),
      children: [
        for (final (name, sub) in items)
          MockListRow(
            icon: icon,
            title: name,
            subtitle: sub,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => detailDestination()),
            ),
          ),
      ],
    );
  }
}

/// 汎用マスター詳細モック(全情報+関連履歴5件)。
class _MasterDetailMock extends StatelessWidget {
  final AppScreen screen;
  final IconData icon;
  final List<(String, String)> fields;
  final Widget? extra;

  const _MasterDetailMock({
    required this.screen,
    required this.icon,
    required this.fields,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return MockScreenScaffold(
      screen: screen,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '編集(モック)',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('UIモックです。編集は後続タスクで実装されます。')),
          ),
        ),
      ],
      children: [
        FormSection(
          icon: icon,
          title: '基本情報',
          children: [
            const MockImagePicker(label: '画像(登録済みモック)'),
            for (final (label, value) in fields)
              MockInfoRow(label: label, value: value),
          ],
        ),
        if (extra != null) extra!,
        FormSection(
          icon: Icons.history,
          title: '関連する抽出履歴 5件',
          children: const [
            MockListRow(
              icon: Icons.coffee,
              title: '2026/07/04 エチオピア イルガチェフェ',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/07/03 タンザニア キリマンジャロ',
              trailing: MockScoreBadge(score: 7),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/07/02 インドネシア ブルーリントン',
              trailing: MockScoreBadge(score: 7),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/07/01 ケニア ニエリ',
              trailing: MockScoreBadge(score: 8),
            ),
            MockListRow(
              icon: Icons.coffee,
              title: '2026/06/30 エチオピア モカ ボンベ',
              trailing: MockScoreBadge(score: 5),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- ドリッパー 014(詳細のみ。013本実装は dripper_list_screen.dart) ----

class DripperDetailMockScreen extends StatelessWidget {
  const DripperDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MasterDetailMock(
      screen: AppScreen.dripperDetail,
      icon: Icons.filter_alt_outlined,
      fields: [
        ('名前', 'HARIO V60 02'),
        ('素材', 'セラミック'),
        ('形状', '円錐'),
      ],
    );
  }
}

// ---- フィルター 016 / 017 ----

class FilterListMockScreen extends StatelessWidget {
  const FilterListMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MasterListMock(
      screen: AppScreen.filterList,
      icon: Icons.layers_outlined,
      items: const [
        ('V60ペーパーフィルター 02', 'ペーパー(漂白) ・ 02'),
        ('Kalitaウェーブフィルター 185', 'ペーパー(漂白) ・ 185'),
        ('ネルフィルター', '布(ネル)'),
      ],
      addDestination: () => const FilterCreateScreen(),
      detailDestination: () => const FilterDetailMockScreen(),
    );
  }
}

class FilterDetailMockScreen extends StatelessWidget {
  const FilterDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MasterDetailMock(
      screen: AppScreen.filterDetail,
      icon: Icons.layers_outlined,
      fields: [
        ('名前', 'V60ペーパーフィルター 02'),
        ('素材', 'ペーパー(漂白)'),
        ('サイズ', '02'),
      ],
    );
  }
}

// ---- メソッド 019 / 020 ----

class MethodListMockScreen extends StatelessWidget {
  const MethodListMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MasterListMock(
      screen: AppScreen.methodList,
      icon: Icons.menu_book_outlined,
      items: const [
        ('4:6メソッド', '粕谷 哲 ・ 抽出 24回'),
        ('V60 Standard', 'HARIO ・ 抽出 18回'),
        ('Hoffmann 1cup', 'James Hoffmann ・ 抽出 6回'),
      ],
      addDestination: () => const MethodCreateScreen(),
      detailDestination: () => const MethodDetailMockScreen(),
    );
  }
}

class MethodDetailMockScreen extends StatelessWidget {
  const MethodDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MasterDetailMock(
      screen: AppScreen.methodDetail,
      icon: Icons.menu_book_outlined,
      fields: const [
        ('メソッド名', '4:6メソッド'),
        ('発案者', '粕谷 哲'),
        ('基準豆量 / 湯量', '20 g / 300 g'),
        ('湯温', '92 ℃'),
        ('推奨挽き目', '中粗挽き'),
        ('説明', '前半4割で味、後半6割で濃度を調整する'),
      ],
      extra: FormSection(
        icon: Icons.play_circle_outline,
        title: '解説動画',
        children: [
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('UIモックです。動画再生は T3-3 で実装検討されます。')),
              ),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: kEspresso,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_fill,
                      size: 56, color: kLatte),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- グラインダー 022 / 023 ----

class GrinderListMockScreen extends StatelessWidget {
  const GrinderListMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _MasterListMock(
      screen: AppScreen.grinderList,
      icon: Icons.settings_input_component_outlined,
      items: const [
        ('コマンダンテ C40', '手挽き ・ 15〜25クリック'),
        ('Wilfa Svart', '電動 ・ 中挽き常用'),
      ],
      addDestination: () => const GrinderCreateScreen(),
      detailDestination: () => const GrinderDetailMockScreen(),
    );
  }
}

class GrinderDetailMockScreen extends StatelessWidget {
  const GrinderDetailMockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MasterDetailMock(
      screen: AppScreen.grinderDetail,
      icon: Icons.settings_input_component_outlined,
      fields: [
        ('名前', 'コマンダンテ C40'),
        ('挽き目レンジ', '15〜25クリック(ペーパードリップ)'),
        ('メモ', '月1で分解清掃。浅煎りは22クリックが基準。'),
      ],
    );
  }
}
