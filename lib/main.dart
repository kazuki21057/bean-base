import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
import 'layout/main_layout.dart';
import 'providers/theme_provider.dart';
import 'utils/nav_key.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
