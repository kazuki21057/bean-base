import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routing/app_screen.dart';
import '../screens/home_screen.dart';
import '../screens/master_list_screen.dart';
import '../screens/coffee_log_list_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/statistics_screen.dart';
import '../utils/nav_key.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

/// トップレベルタブのアイコン・ラベル・遷移先画面。
/// 並びは [AppScreen.topLevelTabs]（001→010→002→030→040）と一致させる。
const Map<AppScreen, IconData> _tabIcons = {
  AppScreen.dashboard: Icons.dashboard,
  AppScreen.beanList: Icons.list,
  AppScreen.logList: Icons.coffee,
  AppScreen.brewRecipe: Icons.calculate,
  AppScreen.statistics: Icons.analytics,
};

const Map<AppScreen, String> _tabLabels = {
  AppScreen.dashboard: 'Home',
  AppScreen.beanList: 'Masters',
  AppScreen.logList: 'Logs',
  AppScreen.brewRecipe: 'Calc',
  AppScreen.statistics: 'Stats',
};

Widget _screenFor(AppScreen screen) {
  switch (screen) {
    case AppScreen.dashboard:
      return const HomeScreen();
    case AppScreen.beanList:
      return const MasterListScreen();
    case AppScreen.logList:
      return const CoffeeLogListScreen();
    case AppScreen.brewRecipe:
      return const CalculatorScreen();
    case AppScreen.statistics:
      return const StatisticsScreen();
    default:
      return const HomeScreen();
  }
}

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        return Scaffold(
          body: isMobile
            ? child
            : Row(
                children: [
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (int index) {
                         ref.read(navIndexProvider.notifier).state = index;
                        _navigateToIndex(index);
                    },
                    labelType: NavigationRailLabelType.selected,
                    destinations: [
                      for (final screen in AppScreen.topLevelTabs)
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
                selectedIndex: selectedIndex,
                onDestinationSelected: (int index) {
                   ref.read(navIndexProvider.notifier).state = index;
                   _navigateToIndex(index);
                },
                destinations: [
                  for (final screen in AppScreen.topLevelTabs)
                    NavigationDestination(
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

  void _navigateToIndex(int index) {
    final screen = _screenFor(AppScreen.topLevelTabs[index]);

    // Use the global navigator key to push to the main content area
    // Remove all previous routes to simulate top-level tabs
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
