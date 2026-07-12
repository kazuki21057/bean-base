/// Cycle 20 (T1-1a): 22画面のID・ルート定義。
///
/// 画面インベントリは docs/改修マスタープラン.md §4 が単一の真実。
/// ここではその画面IDを型安全に扱うための enum とルートパスのみを定義する。
/// 各画面Widgetの実装・登録は T1-1b（プレースホルダ生成）以降で行う。
///
/// ナビ再編方針（T1-1a決定事項、T3-8でMasters/Logsの並びを入替）:
/// - `navIndexProvider`（lib/layout/main_layout.dart）は NavigationRail/Bar の
///   トップレベルタブ選択にのみ用い、対応するルートタブは
///   [AppScreen.topLevelTabs] の並び（001 → 002 → 010 → 030 → 040）とする。
/// - 090(設定)は歯車アイコン等からの遷移のみで、ボトムナビ/レールには含めない。
/// - 詳細・編集・新規画面（011/012/014/015/017/018/020/021/023/024/003/031 等）は
///   トップレベルタブに属さず、既存の `navigatorKey`（lib/utils/nav_key.dart）経由の
///   push/pop でのみ遷移する。navIndexProviderの値はプッシュ時に変更しない。
enum AppScreen {
  dashboard('001', 'ダッシュボード'),
  logList('002', '抽出履歴(リスト)'),
  logDetail('003', '抽出履歴(詳細)'),
  beanList('010', '豆管理(カード)'),
  beanDetail('011', '豆管理(詳細)'),
  beanNew('012', '新規豆追加'),
  dripperList('013', 'ドリッパー管理'),
  dripperDetail('014', 'ドリッパー詳細'),
  dripperNew('015', '新規ドリッパー'),
  filterList('016', 'フィルター管理'),
  filterDetail('017', 'フィルター詳細'),
  filterNew('018', '新規フィルター'),
  methodList('019', 'メソッド管理'),
  methodDetail('020', 'メソッド詳細'),
  methodNew('021', '新規メソッド'),
  grinderList('022', 'グラインダー管理'),
  grinderDetail('023', 'グラインダー詳細'),
  grinderNew('024', '新規グラインダー'),
  brewRecipe('030', '抽出レシピ'),
  brewEvaluation('031', '抽出結果の評価'),
  statistics('040', '統計情報'),
  settings('090', '設定');

  final String code;
  final String titleJa;

  const AppScreen(this.code, this.titleJa);

  /// GoRouter等を導入する際にも使えるパス表現（現状はNavigator 1.0のpushキーとして利用）。
  String get routePath => '/$code';

  /// トップレベルナビ（NavigationRail/NavigationBar）に表示する画面の並び。
  /// index は `navIndexProvider` の値と一致する。
  static const List<AppScreen> topLevelTabs = [
    dashboard, // 0: Home
    logList, // 1: Logs
    beanList, // 2: Masters
    brewRecipe, // 3: Calc/抽出
    statistics, // 4: Stats
  ];
}
