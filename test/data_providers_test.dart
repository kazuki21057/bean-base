import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/providers/data_providers.dart';

/// T3-45: 豆一覧(`beanMasterProvider`)は追加・更新・削除の直後にGAS全件
/// 再取得(数秒かかる)を待たずローカル状態へ即時反映されることを確認する
/// 回帰テスト。バックグラウンド再同期(`fetch()`の2回目以降の呼び出し)が
/// 未解決のままでも、一覧が`AsyncLoading`(スピナー)に戻らず即座に新しい
/// 状態を返すことを検証する。
class _CountingBeanMasterNotifier extends BeanMasterNotifier {
  _CountingBeanMasterNotifier(this._initial, this._subsequent);
  final List<BeanMaster> _initial;
  final Future<List<BeanMaster>> Function() _subsequent;
  int calls = 0;

  @override
  Future<List<BeanMaster>> fetch() {
    calls++;
    if (calls == 1) return Future.value(_initial);
    return _subsequent();
  }
}

BeanMaster _bean(String id, String name) =>
    BeanMaster(id: id, name: name, roastLevel: 'ハイ', origin: '', store: '');

void main() {
  test('addOptimisticはバックグラウンド再同期の完了を待たず一覧に即時反映する', () async {
    final backgroundSync = Completer<List<BeanMaster>>();
    final container = ProviderContainer(
      overrides: [
        beanMasterProvider.overrideWith(
          () => _CountingBeanMasterNotifier([
            _bean('b1', '既存豆'),
          ], () => backgroundSync.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(beanMasterProvider.future);
    expect(initial.map((b) => b.id), ['b1']);

    container
        .read(beanMasterProvider.notifier)
        .addOptimistic(_bean('b2', '新規豆'));

    // バックグラウンド再同期(backgroundSync)がまだ未解決でも、
    // stateはAsyncLoadingへ戻らずAsyncDataのまま新規豆を含む。
    final state = container.read(beanMasterProvider);
    expect(state.isLoading, isFalse);
    expect(state.value?.map((b) => b.id), containsAll(['b1', 'b2']));

    backgroundSync.complete([_bean('b1', '既存豆'), _bean('b2', '新規豆')]);
    await Future<void>.delayed(Duration.zero);
  });

  test('updateOptimistic/removeOptimisticも同様に即時反映する', () async {
    final backgroundSync = Completer<List<BeanMaster>>();
    final container = ProviderContainer(
      overrides: [
        beanMasterProvider.overrideWith(
          () => _CountingBeanMasterNotifier([
            _bean('b1', '旧名'),
            _bean('b2', '削除対象'),
          ], () => backgroundSync.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(beanMasterProvider.future);

    container
        .read(beanMasterProvider.notifier)
        .updateOptimistic(_bean('b1', '新名'));
    var state = container.read(beanMasterProvider);
    expect(state.value?.firstWhere((b) => b.id == 'b1').name, '新名');

    container.read(beanMasterProvider.notifier).removeOptimistic('b2');
    state = container.read(beanMasterProvider);
    expect(state.value?.map((b) => b.id), ['b1']);
    expect(state.isLoading, isFalse);
  });
}
