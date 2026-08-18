// T5-B1(E-1): personal(web) / public(Android) のエディション設定オブジェクト。
//
// 正本は docs/android_monetization/コードベース構成方針.md §2「層2: エディション設定オブジェクト」。
// この段階(E-1)では AppEdition の定義とインスタンス用意のみを行い、
// 実際の画面出し分け・データバックエンド切替・AIキー取得への接続は行わない
// (接続は後続タスクE-2/E-3/E-4のスコープ)。
import 'package:bean_base/routing/app_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリの配布形態。
enum Edition { personal, public }

/// AIキーの取得方法。
enum AiKeyMode {
  /// 設定画面でユーザー自身のGeminiキーを入力する(personal版)。
  ownKey,

  /// サーバ(プロキシ)経由でAI機能を提供する(public版)。
  proxy,
}

/// エディションごとの差分をすべて集約する設定オブジェクト。
class AppEdition {
  final Edition kind;

  /// 出す画面の集合(ホワイトリスト方式。既定は非表示、明示的に許可した画面だけ出す)。
  final Set<AppScreen> enabledScreens;

  /// true=端末ローカルDB / false=Google Sheets(GAS経由)。
  final bool useLocalDb;

  final AiKeyMode aiKeyMode;
  final bool showAds;
  final bool enableSubscription;

  /// 開発者向け画面(lib/screens/debug/)への導線を出すか。public版はfalse。
  final bool showDebugScreens;

  const AppEdition({
    required this.kind,
    required this.enabledScreens,
    required this.useLocalDb,
    required this.aiKeyMode,
    required this.showAds,
    required this.enableSubscription,
    required this.showDebugScreens,
  });
}

// AppScreenの全値を含むconstセット。
// (Set.from(AppScreen.values)はconstコンストラクタでないため
// const AppEdition のフィールド初期化には使えず、列挙で用意する)
const Set<AppScreen> kAllAppScreens = {
  AppScreen.dashboard,
  AppScreen.logList,
  AppScreen.logDetail,
  AppScreen.beanList,
  AppScreen.beanDetail,
  AppScreen.beanNew,
  AppScreen.dripperList,
  AppScreen.dripperDetail,
  AppScreen.dripperNew,
  AppScreen.filterList,
  AppScreen.filterDetail,
  AppScreen.filterNew,
  AppScreen.methodList,
  AppScreen.methodDetail,
  AppScreen.methodNew,
  AppScreen.grinderList,
  AppScreen.grinderDetail,
  AppScreen.grinderNew,
  AppScreen.beanPurchaseHistory,
  AppScreen.storeList,
  AppScreen.storeDetail,
  AppScreen.storeNew,
  AppScreen.brewRecipe,
  AppScreen.brewEvaluation,
  AppScreen.statistics,
  AppScreen.statsTheory,
  AppScreen.statsStatus,
  AppScreen.geminiModel,
  AppScreen.roastGuide,
  AppScreen.explorationStatus,
  AppScreen.settings,
};

/// personal(web)版: 現状の全画面表示・Sheetsバックエンド・自分のGeminiキー・
/// 広告なし・課金なしに相当する設定。
const AppEdition kPersonalEdition = AppEdition(
  kind: Edition.personal,
  enabledScreens: kAllAppScreens,
  useLocalDb: false,
  aiKeyMode: AiKeyMode.ownKey,
  showAds: false,
  enableSubscription: false,
  showDebugScreens: true,
);

/// public(Android)版。enabledScreensは現時点では全画面を許可する(T5-B2で決定、
/// 根拠は コードベース構成方針.md §9.2 D2)。開発者向け画面の遮断は
/// showDebugScreens=false で行う。
const AppEdition kPublicEdition = AppEdition(
  kind: Edition.public,
  enabledScreens: kAllAppScreens,
  useLocalDb: false,
  aiKeyMode: AiKeyMode.ownKey,
  showAds: false,
  enableSubscription: false,
  showDebugScreens: false,
);

/// T5-B3(E-3): 現在アクティブな[AppEdition]を提供するProvider。
///
/// 既定値は[kPersonalEdition](personal版が明示的にoverrideしなくても正しく動くように)。
/// public版のエントリポイント(lib/main_public.dart)ではProviderScope.overridesで
/// [kPublicEdition]に差し替える。
final appEditionProvider = Provider<AppEdition>((ref) => kPersonalEdition);
