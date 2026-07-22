import 'package:bean_base/screens/stats_theory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatsTheoryScreen (T3-27)', () {
    testWidgets('全セクションの見出しとキーとなる式番号が描画される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: StatsTheoryScreen())),
      );
      await tester.pumpAndSettle();

      // 目次(ヘッダー)
      expect(find.text('統計の理論と読み方'), findsWidgets);

      // 各セクション見出し(ActionChip と FormSection タイトルで複数ヒットしうる)
      for (final s in StatsTheorySection.values) {
        expect(find.text(s.titleJa), findsWidgets,
            reason: '${s.name} の見出しが見つからない');
      }

      // 実装と整合する式番号が本文に出ている(Column 一括ビルドのため画面外でも探索可)。
      expect(find.textContaining('(T-2)'), findsWidgets); // 回帰の推定式
      expect(find.textContaining('(T-11)'), findsWidgets); // PCA の固有値分解
      expect(find.textContaining('(T-22)'), findsWidgets); // 好み検定の信頼区間
    });

    testWidgets('initialSection を渡すとエラーなく起動しスクロールされる', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StatsTheoryScreen(initialSection: StatsTheorySection.gp),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // GP セクションの内容(EI の式)が表示可能な状態にある
      expect(find.textContaining('EI(x)'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StatsTheoryLink をタップすると理論ページへ遷移する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => const Center(
                  child: StatsTheoryLink(section: StatsTheorySection.regression),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(StatsTheoryScreen), findsNothing);

      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(StatsTheoryScreen), findsOneWidget);
    });
  });
}
