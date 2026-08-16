// T5-B1(E-1): public(Android)版のエントリポイント。
//
// 正本は docs/android_monetization/コードベース構成方針.md §2「層1: エントリポイントの分離」。
// この段階(E-1)では lib/main.dart(personal版)と完全に同一の起動動作にする
// (差分ゼロの状態を先に作る)。AppEditionを用いた画面出し分け・データバックエンド切替
// 等への接続は後続タスク(E-2/E-3/E-4)のスコープ。
//
// ignore_for_file: always_use_package_imports, avoid_catches_without_on_clauses
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'layout/main_layout.dart';
import 'providers/theme_provider.dart';
import 'utils/nav_key.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // T3-65: table_calendarのlocale: 'ja_JP'指定にはintlの日付シンボルデータ初期化が別途必要
  // (flutter_localizationsのdelegatesとは無関係。呼ばないとLocaleDataExceptionで落ちる)。
  await initializeDateFormatting('ja_JP', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: \$e');
  }

  // Cycle 20 T2-7: 090で保存したメインカラーがあれば起動時に反映する。
  final savedColor = await loadSavedMainColor();

  runApp(
    ProviderScope(
      overrides: [
        if (savedColor != null) mainColorProvider.overrideWith((ref) => savedColor),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainColor = ref.watch(mainColorProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BeanBase 2.0',
      // T3-28: ロケールを日本語に固定。CanvasKit の Han統合フォント選択が
      // 中国語字形(Noto Sans SC)ではなく日本語字形(Noto Sans JP)を優先する。
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      builder: (context, child) {
        // Wrap the navigator in our MainLayout (Sidebar)
        return MainLayout(child: child ?? const SizedBox.shrink());
      },
      home: const DashboardScreen(),
    );
  }
}
