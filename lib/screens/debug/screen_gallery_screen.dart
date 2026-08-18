// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_edition.dart';
import '../../routing/screen_registry.dart';

/// Cycle 20 (T1-1b): 全22画面のプレースホルダへコードから遷移できることを
/// 確認するためのデバッグ用一覧画面。Phase 1後続タスクで各画面が本実装に
/// 置き換わり次第、このデバッグ導線は不要になる。
/// 遷移先の解決は screen_registry.dart(実装済み画面 or プレースホルダ)。
/// T5-B2: 表示対象はエディションのホワイトリスト(enabledScreens)適用後。
class ScreenGalleryScreen extends ConsumerWidget {
  const ScreenGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screens = visibleScreens(ref.watch(appEditionProvider));
    return Scaffold(
      appBar: AppBar(title: const Text('画面一覧 (Cycle 20 T1-1b)')),
      body: ListView.builder(
        itemCount: screens.length,
        itemBuilder: (context, index) {
          final screen = screens[index];
          final implemented = isScreenImplemented(screen);
          return ListTile(
            leading: Text(screen.code),
            title: Text(screen.titleJa),
            trailing: implemented
                ? const Chip(
                    label: Text('UIモック', style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => buildScreenWidget(screen)),
              );
            },
          );
        },
      ),
    );
  }
}
