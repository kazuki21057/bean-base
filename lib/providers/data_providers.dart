import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_service.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';
import '../models/origin_master.dart';
import '../models/analysis_snapshot.dart';
import '../models/recipe_suggestion.dart';
import '../models/store_master.dart';

// Data Providers
final coffeeRecordsProvider = FutureProvider<List<CoffeeRecord>>((ref) async {
  final service = ref.watch(dataServiceProvider);
  return service.getCoffeeRecords();
});

/// T3-45: マスタ一覧(Bean/Grinder/Dripper/Filter/Method共通)の追加・更新・削除
/// 直後にGAS全件再取得(数秒かかる)を待たせないための基盤。
/// `ref.invalidate`は状態を`AsyncLoading`に戻し一覧全体がスピナー表示に
/// なってしまう(体感速度低下の原因)ため、楽観的更新は`state`への直接代入で
/// 行い、裏で最新データに同期する際も`invalidateSelf`ではなく`state`の
/// 直接置き換えでスピナーを再表示させない。
abstract class OptimisticListNotifier<T> extends AsyncNotifier<List<T>> {
  Future<List<T>> fetch();
  String idOf(T item);

  @override
  Future<List<T>> build() => fetch();

  /// 新規追加直後、一覧にすぐ反映するためのローカル追加。
  void addOptimistic(T item) {
    state = AsyncData([...?state.value, item]);
    _syncInBackground();
  }

  /// 更新直後、一覧の該当行だけをローカルで即時差し替える。
  void updateOptimistic(T item) {
    final current = state.value;
    if (current == null) return;
    final id = idOf(item);
    state = AsyncData([for (final e in current) idOf(e) == id ? item : e]);
    _syncInBackground();
  }

  /// 削除直後、一覧から該当行をローカルで即時除去する。
  void removeOptimistic(String id) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([for (final e in current) if (idOf(e) != id) e]);
    _syncInBackground();
  }

  Future<void> _syncInBackground() async {
    try {
      state = AsyncData(await fetch());
    } catch (e) {
      debugPrint('[Antigravity] Error: 一覧のバックグラウンド再同期に失敗 $e');
    }
  }
}

class BeanMasterNotifier extends OptimisticListNotifier<BeanMaster> {
  @override
  Future<List<BeanMaster>> fetch() => ref.watch(dataServiceProvider).getBeans();
  @override
  String idOf(BeanMaster item) => item.id;
}

final beanMasterProvider = AsyncNotifierProvider<BeanMasterNotifier, List<BeanMaster>>(
  BeanMasterNotifier.new,
);

class MethodMasterNotifier extends OptimisticListNotifier<MethodMaster> {
  @override
  Future<List<MethodMaster>> fetch() => ref.watch(dataServiceProvider).getMethods();
  @override
  String idOf(MethodMaster item) => item.id;
}

final methodMasterProvider = AsyncNotifierProvider<MethodMasterNotifier, List<MethodMaster>>(
  MethodMasterNotifier.new,
);

class GrinderMasterNotifier extends OptimisticListNotifier<GrinderMaster> {
  @override
  Future<List<GrinderMaster>> fetch() => ref.watch(dataServiceProvider).getGrinders();
  @override
  String idOf(GrinderMaster item) => item.id;
}

final grinderMasterProvider = AsyncNotifierProvider<GrinderMasterNotifier, List<GrinderMaster>>(
  GrinderMasterNotifier.new,
);

class DripperMasterNotifier extends OptimisticListNotifier<DripperMaster> {
  @override
  Future<List<DripperMaster>> fetch() => ref.watch(dataServiceProvider).getDrippers();
  @override
  String idOf(DripperMaster item) => item.id;
}

final dripperMasterProvider = AsyncNotifierProvider<DripperMasterNotifier, List<DripperMaster>>(
  DripperMasterNotifier.new,
);

class FilterMasterNotifier extends OptimisticListNotifier<FilterMaster> {
  @override
  Future<List<FilterMaster>> fetch() => ref.watch(dataServiceProvider).getFilters();
  @override
  String idOf(FilterMaster item) => item.id;
}

final filterMasterProvider = AsyncNotifierProvider<FilterMasterNotifier, List<FilterMaster>>(
  FilterMasterNotifier.new,
);

/// T3-67(docs/store_master_design.md): 購入店マスタ。026/027/028(T3-68)で使用。
class StoreMasterNotifier extends OptimisticListNotifier<StoreMaster> {
  @override
  Future<List<StoreMaster>> fetch() => ref.watch(dataServiceProvider).getStores();
  @override
  String idOf(StoreMaster item) => item.id;
}

final storeMasterProvider = AsyncNotifierProvider<StoreMasterNotifier, List<StoreMaster>>(
  StoreMasterNotifier.new,
);

final pouringStepsProvider = FutureProvider<List<PouringStep>>((ref) async {
  return ref.watch(dataServiceProvider).getPouringSteps();
});

/// T4-1e(設計書§3.2): 産地マスタ選択ドロップダウン用。
final originMasterProvider = FutureProvider<List<OriginMaster>>((ref) async {
  return ref.watch(dataServiceProvider).fetchOriginMasters();
});

/// T4-4c(設計書§7.3): 好みプロファイルの履歴(preference_section.dartの履歴タブ用)。
final preferenceSnapshotsProvider = FutureProvider<List<AnalysisSnapshot>>((ref) async {
  return ref.watch(dataServiceProvider).fetchAnalysisSnapshots(type: 'preference');
});

/// T4-6c(設計書§7.4手順1): レシピ提案の履歴。GP提案7件に1件をEI提案に
/// 切り替える`SuggestionService.shouldExplore`判定に使う。
final recipeSuggestionsProvider = FutureProvider<List<RecipeSuggestion>>((ref) async {
  return ref.watch(dataServiceProvider).fetchRecipeSuggestions();
});

// AI Analysis State
final aiAnalysisResultProvider = StateProvider<String?>((ref) => null);
final aiAnalysisLoadingProvider = StateProvider<bool>((ref) => false);
