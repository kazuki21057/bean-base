import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../create/create_form_widgets.dart';
import 'mock_scaffold.dart';

/// 014/017/020/023 の各マスター詳細のUIモック(ギャラリー単独遷移用)。
/// 一覧・新規/編集は T1-5a〜d の汎用テンプレートで本実装済み。

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
      showSettingsAction: false,
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

// ---- フィルター 017(詳細のみ。016本実装は filter_list_screen.dart) ----

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

// ---- メソッド 020(詳細のみ。019本実装は method_list_screen.dart) ----

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

// ---- グラインダー 023(詳細のみ。022本実装は grinder_list_screen.dart) ----

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
