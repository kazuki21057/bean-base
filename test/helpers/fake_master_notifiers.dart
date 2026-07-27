import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/models/equipment_masters.dart';
import 'package:bean_base/models/method_master.dart';
import 'package:bean_base/providers/data_providers.dart';

/// T3-45: `beanMasterProvider`等が`FutureProvider`から`AsyncNotifierProvider`
/// (楽観的更新対応)に変わったことに伴うテスト用フェイク。`fetch()`のみを
/// 差し替え、実際のGAS通信(`dataServiceProvider`)を経由せず固定データ・
/// フェイクサービス呼び出しのどちらも返せるようにする。
class FakeBeanMasterNotifier extends BeanMasterNotifier {
  FakeBeanMasterNotifier(this._fetcher);
  final Future<List<BeanMaster>> Function() _fetcher;
  @override
  Future<List<BeanMaster>> fetch() => _fetcher();
}

class FakeMethodMasterNotifier extends MethodMasterNotifier {
  FakeMethodMasterNotifier(this._fetcher);
  final Future<List<MethodMaster>> Function() _fetcher;
  @override
  Future<List<MethodMaster>> fetch() => _fetcher();
}

class FakeGrinderMasterNotifier extends GrinderMasterNotifier {
  FakeGrinderMasterNotifier(this._fetcher);
  final Future<List<GrinderMaster>> Function() _fetcher;
  @override
  Future<List<GrinderMaster>> fetch() => _fetcher();
}

class FakeDripperMasterNotifier extends DripperMasterNotifier {
  FakeDripperMasterNotifier(this._fetcher);
  final Future<List<DripperMaster>> Function() _fetcher;
  @override
  Future<List<DripperMaster>> fetch() => _fetcher();
}

class FakeFilterMasterNotifier extends FilterMasterNotifier {
  FakeFilterMasterNotifier(this._fetcher);
  final Future<List<FilterMaster>> Function() _fetcher;
  @override
  Future<List<FilterMaster>> fetch() => _fetcher();
}
