import 'bean_master.dart';
import 'equipment_masters.dart';
import 'method_master.dart';

/// 030(抽出レシピ)から031(評価)へ引き継ぐ、未保存の抽出セッション情報。
/// Sheetsへの永続化は行わない(CoffeeRecordとしての保存はT2-5aで実装)。
class PendingBrewInfo {
  final DateTime brewedAt;
  final MethodMaster method;
  final BeanMaster? bean;
  final GrinderMaster? grinder;
  final DripperMaster? dripper;
  final FilterMaster? filter;
  final double beanWeight;
  final double totalWater;
  final int totalTime;
  final double bloomingWater;
  final int bloomingTime;

  const PendingBrewInfo({
    required this.brewedAt,
    required this.method,
    this.bean,
    this.grinder,
    this.dripper,
    this.filter,
    required this.beanWeight,
    required this.totalWater,
    required this.totalTime,
    required this.bloomingWater,
    required this.bloomingTime,
  });

  /// UIモック/画面ギャラリーでのプレビュー表示専用のダミーデータ。
  factory PendingBrewInfo.mock() {
    return PendingBrewInfo(
      brewedAt: DateTime.now(),
      method: MethodMaster(
        id: 'mock',
        name: '4:6メソッド',
        author: '',
        baseBeanWeight: 20,
        baseWaterAmount: 300,
        temperature: 92,
        description: '',
        recommendedEquipment: '',
      ),
      beanWeight: 20,
      totalWater: 300,
      totalTime: 210,
      bloomingWater: 40,
      bloomingTime: 45,
    );
  }
}
