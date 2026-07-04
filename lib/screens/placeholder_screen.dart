import 'package:flutter/material.dart';
import '../routing/app_screen.dart';

/// Cycle 20 (T1-1b): 画面IDと和名だけを表示するプレースホルダ。
/// 各画面の本実装（Phase 1後続タスク）が入るまでの仮の遷移先として使う。
class PlaceholderScreen extends StatelessWidget {
  final AppScreen screen;

  const PlaceholderScreen({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${screen.code} ${screen.titleJa}')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(screen.code, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(screen.titleJa, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
