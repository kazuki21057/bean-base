import 'package:flutter/material.dart';
import 'app_screen.dart';
import '../screens/create/bean_create_screen.dart';
import '../screens/create/dripper_create_screen.dart';
import '../screens/create/filter_create_screen.dart';
import '../screens/create/grinder_create_screen.dart';
import '../screens/create/method_create_screen.dart';
import '../screens/create/brew_evaluation_screen.dart';
import '../models/pending_brew_info.dart';
import '../screens/mock/dashboard_mock_screen.dart';
import '../screens/mock/log_mock_screens.dart';
import '../screens/mock/bean_mock_screens.dart';
import '../screens/mock/master_mock_screens.dart';
import '../screens/mock/brew_recipe_mock_screen.dart';
import '../screens/mock/stats_settings_mock_screens.dart';
import '../screens/dripper_list_screen.dart';
import '../screens/filter_list_screen.dart';
import '../screens/grinder_list_screen.dart';

/// 画面ID → Widget の解決テーブル。
/// 全22画面がUIモック(見た目のみ・データ未接続)として登録済み。
/// 本実装(実データ接続)が済んだ画面から順次差し替えていく。
Widget buildScreenWidget(AppScreen screen) {
  switch (screen) {
    case AppScreen.dashboard:
      return const DashboardMockScreen();
    case AppScreen.logList:
      return const LogListMockScreen();
    case AppScreen.logDetail:
      return const LogDetailMockScreen();
    case AppScreen.beanList:
      return const BeanListMockScreen();
    case AppScreen.beanDetail:
      return const BeanDetailMockScreen();
    case AppScreen.beanNew:
      return const BeanCreateScreen();
    case AppScreen.dripperList:
      return const DripperListScreen();
    case AppScreen.dripperDetail:
      return const DripperDetailMockScreen();
    case AppScreen.dripperNew:
      return const DripperCreateScreen();
    case AppScreen.filterList:
      return const FilterListScreen();
    case AppScreen.filterDetail:
      return const FilterDetailMockScreen();
    case AppScreen.filterNew:
      return const FilterCreateScreen();
    case AppScreen.methodList:
      return const MethodListMockScreen();
    case AppScreen.methodDetail:
      return const MethodDetailMockScreen();
    case AppScreen.methodNew:
      return const MethodCreateScreen();
    case AppScreen.grinderList:
      return const GrinderListScreen();
    case AppScreen.grinderDetail:
      return const GrinderDetailMockScreen();
    case AppScreen.grinderNew:
      return const GrinderCreateScreen();
    case AppScreen.brewRecipe:
      return const BrewRecipeMockScreen();
    case AppScreen.brewEvaluation:
      return BrewEvaluationScreen(info: PendingBrewInfo.mock());
    case AppScreen.statistics:
      return const StatisticsMockScreen();
    case AppScreen.settings:
      return const SettingsMockScreen();
  }
}

/// UIモック以上が実装済みの画面(ギャラリーでの表示分け用)。
/// 2026-07-05 時点で全22画面のUIモックが揃っている。
bool isScreenImplemented(AppScreen screen) => true;
