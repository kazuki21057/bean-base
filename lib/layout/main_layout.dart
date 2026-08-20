// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_edition.dart';
import '../routing/app_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/masters_hub_screen.dart';
import '../screens/log_list_screen.dart';
import '../screens/brew_recipe_screen.dart';
import '../screens/statistics_screen.dart';
import '../utils/nav_key.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

/// トップレベルタブのアイコン・ラベル・遷移先画面。
/// 並びは [AppScreen.topLevelTabs]（001→002→010→030→040、T3-8でMasters/Logs入替）と一致させる。
const Map<AppScreen, IconData> _tabIcons = {
  AppScreen.dashboard: Icons.dashboard,
  AppScreen.beanList: Icons.list,
  AppScreen.logList: Icons.coffee,
  AppScreen.brewRecipe: Icons.calculate,
  AppScreen.statistics: Icons.analytics,
};

const Map<AppScreen, String> _tabLabels = {
  AppScreen.dashboard: 'ホーム',
  AppScreen.beanList: 'マスター',
  AppScreen.logList: '履歴',
  AppScreen.brewRecipe: 'レシピ',
  AppScreen.statistics: '統計',
};

Widget _screenFor(AppScreen screen) {
  switch (screen) {
    case AppScreen.dashboard:
      return const DashboardScreen();
    case AppScreen.beanList:
      return const MastersHubScreen();
    case AppScreen.logList:
      return const LogListScreen();
    case AppScreen.brewRecipe:
      return const BrewRecipeScreen();
    case AppScreen.statistics:
      return const StatisticsScreen();
    default:
      return const DashboardScreen();
  }
}

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);
    final edition = ref.watch(appEditionProvider);
    final visibleTabs = AppScreen.topLevelTabs
        .where(edition.enabledScreens.contains)
        .toList();
    // enabledScreens の縮小で selectedIndex が範囲外になると
    // NavigationBar/NavigationRail の assert に触れるため必ずクランプする。
    final safeIndex =
        (selectedIndex >= 0 && selectedIndex < visibleTabs.length) ? selectedIndex : 0;

    if (visibleTabs.isEmpty) {
      return Scaffold(body: child);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Scaffold(
          body: isMobile
            ? child
            : Row(
                children: [
                  NavigationRail(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (int index) {
                         ref.read(navIndexProvider.notifier).state = index;
                        _navigateToIndex(index, visibleTabs);
                    },
                    labelType: NavigationRailLabelType.selected,
                    destinations: [
                      for (final screen in visibleTabs)
                        NavigationRailDestination(
                          icon: Icon(_tabIcons[screen]),
                          label: Text(_tabLabels[screen]!),
                        ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: child),
                ],
              ),
          bottomNavigationBar: isMobile
            ? NavigationBar(
                selectedIndex: safeIndex,
                onDestinationSelected: (int index) {
                   ref.read(navIndexProvider.notifier).state = index;
                   _navigateToIndex(index, visibleTabs);
                },
                destinations: [
                  for (final screen in visibleTabs)
                    // T5-A7: integration_testからタブを特定するためのキー。
                    // NavigationRailDestination(デスクトップ幅)はWidgetではなく
                    // keyを持てないため、モバイル幅のNavigationDestination側にのみ付与する
                    // (integration_testの主対象はAndroidエミュレータ=モバイル幅)。
                    NavigationDestination(
                      key: ValueKey('nav_tab_${screen.code}'),
                      icon: Icon(_tabIcons[screen]),
                      label: _tabLabels[screen]!,
                      tooltip: '',
                    ),
                ],
              )
            : null,
        );
      },
    );
  }

  void _navigateToIndex(int index, List<AppScreen> tabs) {
    final screen = _screenFor(tabs[index]);

    // Use the global navigator key to push to the main content area
    // Remove all previous routes to simulate top-level tabs
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
