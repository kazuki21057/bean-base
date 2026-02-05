import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'layout/main_layout.dart';
import 'utils/nav_key.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'BeanBase 2.0',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      builder: (context, child) {
        // Wrap the navigator in our MainLayout (Sidebar)
        return MainLayout(child: child ?? const SizedBox.shrink());
      },
      home: const HomeScreen(),
    );
  }
}
