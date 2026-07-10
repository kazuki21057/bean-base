import 'package:flutter/material.dart';
import 'bean_list_screen.dart';
import 'dripper_list_screen.dart';
import 'filter_list_screen.dart';
import 'grinder_list_screen.dart';
import 'method_list_screen.dart';

/// 「Masters」ナビタブの入り口。
///
/// Cycle 20 T1-7: 本番ナビ(`main_layout.dart`)の「Masters」タブを旧実装
/// `MasterListScreen`(タブ切替式)から新画面群へつなぐハブ。新しい各一覧画面
/// (`BeanListScreen`等)はそれぞれ独自のAppBarを持つ完結したScaffoldのため、
/// 旧実装のようにTabBarViewへ埋め込むと二重AppBarになる。そのため
/// タブ切替ではなく、マスター種別を選んでpushする単純な一覧にする。
class MastersHubScreen extends StatelessWidget {
  const MastersHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String, String, WidgetBuilder)>[
      (Icons.coffee, '豆管理', '焙煎所/産地/煎り度/残量', (_) => const BeanListScreen()),
      (Icons.filter_alt_outlined, 'ドリッパー管理', '', (_) => const DripperListScreen()),
      (Icons.filter_frames_outlined, 'フィルター管理', '', (_) => const FilterListScreen()),
      (Icons.receipt_long_outlined, 'メソッド管理', '発案者/抽出回数', (_) => const MethodListScreen()),
      (Icons.settings_input_component_outlined, 'グラインダー管理', '', (_) => const GrinderListScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Masters')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final (icon, title, subtitle, builder) in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  debugPrint('[Antigravity] Action: Masters ハブから$titleへ遷移');
                  Navigator.push(context, MaterialPageRoute(builder: builder));
                },
              ),
            ),
        ],
      ),
    );
  }
}
