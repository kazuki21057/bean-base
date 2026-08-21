// T5-B23: 公開版(Android)の画面ID。
//
// 正本は docs/android_monetization/デザイン方針.md §9.1。画面IDは既存の
// `AppScreen`(`001`〜`090`)と名前空間が衝突しないよう`P`+3桁とする(D7)。
// `enum`値・IDは同表のまま一字一句を使う(勝手な追加・改名をしない)。
library;

/// 公開版の画面ID。値は`デザイン方針.md` §9.1の「enum値」列と一致させる。
enum PublicScreen {
  home,
  recordSetup,
  recordBrewing,
  recordEvaluation,
  recordDetail,
  recordEdit,
  recordList,
  insight,
  insightDetail,
  onboardingWelcome,
  onboardingGear,
  onboardingRecipe,
  onboardingDone,
  gearHub,
  beanList,
  beanDetail,
  beanEdit,
  grinderList,
  grinderDetail,
  grinderEdit,
  dripperList,
  dripperDetail,
  dripperEdit,
  filterList,
  filterDetail,
  filterEdit,
  methodList,
  methodDetail,
  methodEdit,
  settings,
  proPlan,
  dataTransfer,
}

/// `PublicScreen`から`デザイン方針.md` §9.1の「ID」列(`P100`形式)を引く拡張。
extension PublicScreenId on PublicScreen {
  /// 画面ID(`P100`〜`P920`形式)。
  String get id {
    switch (this) {
      case PublicScreen.home:
        return 'P100';
      case PublicScreen.recordSetup:
        return 'P200';
      case PublicScreen.recordBrewing:
        return 'P210';
      case PublicScreen.recordEvaluation:
        return 'P220';
      case PublicScreen.recordDetail:
        return 'P230';
      case PublicScreen.recordEdit:
        return 'P231';
      case PublicScreen.recordList:
        return 'P240';
      case PublicScreen.insight:
        return 'P300';
      case PublicScreen.insightDetail:
        return 'P310';
      case PublicScreen.onboardingWelcome:
        return 'P400';
      case PublicScreen.onboardingGear:
        return 'P410';
      case PublicScreen.onboardingRecipe:
        return 'P420';
      case PublicScreen.onboardingDone:
        return 'P430';
      case PublicScreen.gearHub:
        return 'P500';
      case PublicScreen.beanList:
        return 'P510';
      case PublicScreen.beanDetail:
        return 'P511';
      case PublicScreen.beanEdit:
        return 'P512';
      case PublicScreen.grinderList:
        return 'P520';
      case PublicScreen.grinderDetail:
        return 'P521';
      case PublicScreen.grinderEdit:
        return 'P522';
      case PublicScreen.dripperList:
        return 'P530';
      case PublicScreen.dripperDetail:
        return 'P531';
      case PublicScreen.dripperEdit:
        return 'P532';
      case PublicScreen.filterList:
        return 'P540';
      case PublicScreen.filterDetail:
        return 'P541';
      case PublicScreen.filterEdit:
        return 'P542';
      case PublicScreen.methodList:
        return 'P550';
      case PublicScreen.methodDetail:
        return 'P551';
      case PublicScreen.methodEdit:
        return 'P552';
      case PublicScreen.settings:
        return 'P900';
      case PublicScreen.proPlan:
        return 'P910';
      case PublicScreen.dataTransfer:
        return 'P920';
    }
  }
}
