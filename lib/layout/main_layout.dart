import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home_screen.dart';
import '../screens/master_list_screen.dart';
import '../screens/coffee_log_list_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/statistics_screen.dart';
import '../utils/nav_key.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

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
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Home')),
                      NavigationRailDestination(icon: Icon(Icons.list), label: Text('Masters')),
                      NavigationRailDestination(icon: Icon(Icons.coffee), label: Text('Logs')),
                      NavigationRailDestination(icon: Icon(Icons.calculate), label: Text('Calc')),
                      NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Stats')),
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
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.dashboard), label: 'Home', tooltip: ''),
                  NavigationDestination(icon: Icon(Icons.list), label: 'Masters', tooltip: ''),
                  NavigationDestination(icon: Icon(Icons.coffee), label: 'Logs', tooltip: ''),
                  NavigationDestination(icon: Icon(Icons.calculate), label: 'Calc', tooltip: ''),
                  NavigationDestination(icon: Icon(Icons.analytics), label: 'Stats', tooltip: ''),
                ],
              )
            : null,
        );
      },
    );
  }

  void _navigateToIndex(int index) {
    Widget screen;
    switch (index) {
      case 0: screen = const HomeScreen(); break;
      case 1: screen = const MasterListScreen(); break;
      case 2: screen = const CoffeeLogListScreen(); break;
      case 3: screen = const CalculatorScreen(); break;
      case 4: screen = const StatisticsScreen(); break;
      default: screen = const HomeScreen();
    }
    
    // Use the global navigator key to push to the main content area
    // Remove all previous routes to simulate top-level tabs
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
