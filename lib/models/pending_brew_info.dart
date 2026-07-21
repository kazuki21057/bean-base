import 'bean_master.dart';
import 'equipment_masters.dart';
import 'method_master.dart';

/// 030(抽出レシピ)から031(評価)へ引き継ぐ、未保存の抽出セッション情報。
/// Sheetsへの永続化は行わない(CoffeeRecordとしての保存はT2-5aで実装)。
class PendingBrewInfo {
  final DateTime brewedAt;

  /// T3-15: 030でメソッドを選ばずに031へ進めるよう、必須ではなくした
  /// (031側でメソッドを選択・変更できる。T3-17参照)。
  final MethodMaster? method;
  final BeanMaster? bean;
  final GrinderMaster? grinder;
  final DripperMaster? dripper;
  final FilterMaster? filter;
  final double beanWeight;
  final double totalWater;
  final int totalTime;
  final double bloomingWater;
  final int bloomingTime;

  /// T4-5b(設計書§7.4): F3レシピ提案から031へ湯温をプリフィルするための任意値。
  /// 通常の030→031フローでは湯温は031で都度入力するためnull。
  final double? temperature;

  /// T1-4c: 002からのスワイプ操作で過去の記録から引き継ぐ評価値(任意)。
  /// 031画面の初期値としてのみ使用し、保存(records反映)はT2-5aで実装する。
  final int? scoreFragrance;
  final int? scoreAcidity;
  final int? scoreBitterness;
  final int? scoreSweetness;
  final int? scoreComplexity;
  final int? scoreFlavor;
  final int? scoreOverall;
  final String? taste;
  final String? concentration;
  final String? comment;

  const PendingBrewInfo({
    required this.brewedAt,
    this.method,
    this.bean,
    this.grinder,
    this.dripper,
    this.filter,
    required this.beanWeight,
    required this.totalWater,
    required this.totalTime,
    required this.bloomingWater,
    required this.bloomingTime,
    this.temperature,
    this.scoreFragrance,
    this.scoreAcidity,
    this.scoreBitterness,
    this.scoreSweetness,
    this.scoreComplexity,
    this.scoreFlavor,
    this.scoreOverall,
    this.taste,
    this.concentration,
    this.comment,
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
