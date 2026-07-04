import 'package:flutter/material.dart';
import '../../routing/app_screen.dart';
import '../placeholder_screen.dart';

/// Cycle 20 (T1-1b): 全22画面のプレースホルダへコードから遷移できることを
/// 確認するためのデバッグ用一覧画面。Phase 1後続タスクで各画面が本実装に
/// 置き換わり次第、このデバッグ導線は不要になる。
class ScreenGalleryScreen extends StatelessWidget {
  const ScreenGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('画面一覧 (Cycle 20 T1-1b)')),
      body: ListView.builder(
        itemCount: AppScreen.values.length,
        itemBuilder: (context, index) {
          final screen = AppScreen.values[index];
          return ListTile(
            leading: Text(screen.code),
            title: Text(screen.titleJa),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaceholderScreen(screen: screen)),
              );
            },
          );
        },
      ),
    );
  }
}
