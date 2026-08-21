// T5-B23: 公開版(Android)のナビゲーションシェル。
//
// 正本は docs/android_monetization/デザイン方針.md §9.2。下部`NavigationBar`
// (4タブ: ホーム/履歴/インサイト/道具)+中央下FAB「淹れる」を持ち、
// `IndexedStack`でタブの状態を保持する。ホームタブのみ実画面(`HomeScreen`)を
// 表示し、他3タブとFABタップ時の遷移先は本タスクの範囲外(それぞれ
// T5-B24/T5-B25/T5-B27・P200で本実装する)のため、簡単なプレースホルダを
// 表示するに留める。
import 'package:flutter/material.dart';

import 'package:bean_base/screens/public/home_screen.dart';

/// 公開版のトップレベルナビゲーションシェル。
class PublicShell extends StatefulWidget {
  const PublicShell({super.key});

  @override
  State<PublicShell> createState() => _PublicShellState();
}

class _PublicShellState extends State<PublicShell> {
  int _index = 0;

  void _onFabTap() {
    debugPrint('[Antigravity] PublicShell: FAB「淹れる」タップ');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _PublicPlaceholderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // T5-B23 adversaryレビューMajor-1対応: `_tabs`を`static const`にすると、
    // タブ切替の`setState`で`build()`が再実行されても子ウィジェットが同一の
    // constインスタンスのままになり、Flutterフレームワークの
    // `child.widget == newWidget`高速パス(`Element.update()`自体を呼ばない
    // 最適化)により`HomeScreen`(`_HomeBody`)の`build()`が再実行されない。
    // これでは`homeScreenClock()`(build()のたびに最新時刻を取得する想定)が
    // タブ切替では呼び直されず、週境界をまたいでも「今週」集計が古いまま
    // 表示され続けるおそれがある。`build()`のたびに新しいインスタンスを
    // 生成することで、この高速パスを避け子の`build()`を確実に再実行させる。
    final tabs = <Widget>[
      HomeScreen(),
      _PublicPlaceholderScreen(),
      _PublicPlaceholderScreen(),
      _PublicPlaceholderScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (index) {
          debugPrint('[Antigravity] PublicShell: タブ切替 index=$index');
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'インサイト',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: '道具',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabTap,
        icon: const Icon(Icons.coffee),
        label: const Text('淹れる'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// 未実装タブ・未実装遷移先向けの簡単なプレースホルダ画面。
class _PublicPlaceholderScreen extends StatelessWidget {
  const _PublicPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: Center(child: Text('準備中')),
    );
  }
}
