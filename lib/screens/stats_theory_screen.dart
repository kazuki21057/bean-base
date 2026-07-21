import 'package:flutter/material.dart';

import '../routing/app_screen.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 041 統計の理論と読み方 (T3-27)。
///
/// 回帰(F1)・PCA(F2)・ガウス過程/EI(F4)・好み検定(F5)・レシピ提案(F3) など、
/// アプリが行っている統計処理の理論的背景を日本語で説明する専用ページ。
/// 各統計機能付近(040の各セクション・030のレシピ探索・003の評価表示)から
/// [StatsTheoryLink] 経由で該当セクションへ飛べる。
///
/// **内容の正本は `statistics_feature_design.md` §2(統計理論編)。**
/// 本ページの式番号(T-1 等)は同書と一致させており、実装(サービス層の
/// doc コメントが引用する式番号)と整合する。数値計算はすべて Dart ローカルで
/// 行われ、Gemini は計算済み数値の日本語解釈のみを担う(CLAUDE.md 絶対規則)ため、
/// 本ページも「何を計算しているか」の解説に徹する。
enum StatsTheorySection {
  intro('はじめに', Icons.auto_stories_outlined),
  intervals('信頼区間と予測区間', Icons.straighten_outlined),
  regression('重回帰分析 (F1)', Icons.insights_outlined),
  pca('主成分分析 / PCA (F2)', Icons.scatter_plot_outlined),
  preference('好みの傾向の検定 (F5)', Icons.favorite_outline),
  gp('ガウス過程回帰と探索 (F4)', Icons.blur_on_outlined),
  suggestion('レシピ提案の仕組み (F3)', Icons.lightbulb_outline);

  const StatsTheorySection(this.titleJa, this.icon);

  final String titleJa;
  final IconData icon;
}

/// 各統計機能の近くに置く「理論を読む」導線。
///
/// [FormSection] の `trailing` スロットや任意の場所に置ける小さな本アイコン。
/// タップすると [StatsTheoryScreen] を該当セクションまでスクロールした状態で開く。
class StatsTheoryLink extends StatelessWidget {
  final StatsTheorySection section;
  final String tooltip;

  const StatsTheoryLink({
    super.key,
    required this.section,
    this.tooltip = 'この分析の理論を読む',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_book_outlined, size: 20, color: kAccent),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () {
        debugPrint(
            '[Antigravity] Action: 統計理論ページ(041)へ遷移 section=${section.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatsTheoryScreen(initialSection: section),
          ),
        );
      },
    );
  }
}

class StatsTheoryScreen extends StatefulWidget {
  /// 開いたときに自動スクロールして表示するセクション。null なら先頭。
  final StatsTheorySection? initialSection;

  const StatsTheoryScreen({super.key, this.initialSection});

  @override
  State<StatsTheoryScreen> createState() => _StatsTheoryScreenState();
}

class _StatsTheoryScreenState extends State<StatsTheoryScreen> {
  late final Map<StatsTheorySection, GlobalKey> _keys = {
    for (final s in StatsTheorySection.values) s: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final target = widget.initialSection;
    if (target != null && target != StatsTheorySection.intro) {
      // 初回フレーム描画後に、MockScreenScaffold 内の ListView(Scrollable)を
      // 遡って該当セクションまでスクロールする。ScrollController を自前で
      // 持たず Scrollable.ensureVisible で最寄りの Scrollable を解決する。
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(target));
    }
  }

  void _scrollTo(StatsTheorySection section) {
    final ctx = _keys[section]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 全セクションを非遅延の Column で一括ビルドする。MockScreenScaffold 内の
    // ListView は既定で画面外の子を遅延生成するため、単独の Column を渡して
    // 各セクションの GlobalKey が常に context を持つ状態にし、初期セクションへの
    // 自動スクロール(Scrollable.ensureVisible)を確実に効かせる。
    return MockScreenScaffold(
      screen: AppScreen.statsTheory,
      showSettingsAction: false,
      maxWidth: 720,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableOfContents(),
            _introSection(),
            _intervalsSection(),
            _regressionSection(),
            _pcaSection(),
            _preferenceSection(),
            _gpSection(),
            _suggestionSection(),
            const SizedBox(height: 12),
            _sourceNote(),
          ],
        ),
      ],
    );
  }

  // --- 目次 ---

  Widget _tableOfContents() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kEspresso,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 20, color: kCream),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '統計の理論と読み方',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kCream,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'このアプリが行っている統計処理の背景を、機能ごとに解説します。読みたい項目をタップしてください。',
            style: TextStyle(fontSize: 12, color: kLatte, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in StatsTheorySection.values)
                ActionChip(
                  avatar: Icon(s.icon, size: 16, color: kEspresso),
                  label: Text(s.titleJa),
                  backgroundColor: kCream,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: kEspresso,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _scrollTo(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- セクション骨格 ---

  Widget _sectionCard(
    StatsTheorySection section, {
    required List<Widget> children,
  }) {
    return FormSection(
      key: _keys[section],
      icon: section.icon,
      title: section.titleJa,
      children: children,
    );
  }

  // --- はじめに ---

  Widget _introSection() {
    return _sectionCard(
      StatsTheorySection.intro,
      children: const [
        _Para(
          'BeanBase は、あなたが記録した抽出データから「どの条件が味を良くしているか」を'
          '統計的に読み解き、次の一杯の条件を提案します。ここでは各分析が内部で何を'
          '計算しているかを、順を追って説明します。',
        ),
        _Bullet('数値計算(回帰・PCA・ガウス過程・検定)はすべて端末内(Dart)で計算します。'
            'AI(Gemini)は計算結果の文章での言い換えだけを担当し、数値そのものは作りません。'),
        _Bullet('統計量は必ず「点推定(1つの代表値)」と「不確実性(信頼区間や予測区間)」を'
            'セットで表示します。1つの数字を過信しないための約束です。'),
        _Bullet('スコア(総合評価など)は 0〜10 の整数です。本来は順位の尺度ですが、'
            '分析では等間隔の数値として扱う近似をしています。'),
        _NoteCard(
          '観測データ(実験ではなく記録)を使うため、分析でわかるのは「関連(いっしょに'
          '動く傾向)」であり、必ずしも「原因」ではありません。結果は仮説として扱い、'
          '気になった条件は実際に試して確かめてください。',
        ),
      ],
    );
  }

  // --- 信頼区間と予測区間 ---

  Widget _intervalsSection() {
    return _sectionCard(
      StatsTheorySection.intervals,
      children: const [
        _Para('どの分析でも「±いくつ」という幅がついて回ります。この幅には2種類あり、'
            '意味が異なります。'),
        _SubHead('信頼区間 (Confidence Interval)'),
        _Para('平均や係数といった「パラメータ」がどのくらいの範囲にありそうか、を表します。'
            'データが増えるほど狭くなります。'),
        _SubHead('予測区間 (Prediction Interval)'),
        _Para('「次の1回」の観測値がどのくらいばらつくか、を表します。1回ごとの偶然の'
            'ばらつき(σ)が含まれるため、データを増やしても σ の分だけは残り、'
            '信頼区間より必ず広くなります。'),
        _Formula('信頼区間 … 平均や係数の不確実性 (データ増で縮む)\n'
            '予測区間 … 次の1杯の不確実性  (データ増でも σ 分は残る)'),
        _Para('回帰の「この条件で予測」やレシピ探索の予測スコアには予測区間を使います。'
            '「だいたいこの辺に落ちるが、1回では上下にブレる」という読み方が正解です。'),
      ],
    );
  }

  // --- 重回帰分析 ---

  Widget _regressionSection() {
    return _sectionCard(
      StatsTheorySection.regression,
      children: const [
        _Para('「何が総合評価を動かすか」を調べる分析です。総合評価 y を、湯温・湯豆比・'
            '抽出時間・焙煎度・産地などの説明変数で説明する式を当てはめます。'),
        _SubHead('モデルと推定 (T-1〜T-2)'),
        _Formula('y = Xβ + ε,   ε ~ N(0, σ²I)          (T-1)\n'
            'β̂ = (XᵀX)⁻¹ Xᵀy                      (T-2)'),
        _Para('X は計画行列(1列目は切片の1)、β は各要因の効き目(係数)です。'
            '実装では逆行列を直接作らず、正規方程式を Cholesky 分解で安定に解きます。'
            '説明変数が完全に重複(線形従属)しているときは解けないため、その旨を表示します。'),
        _SubHead('係数の有意性 (T-3〜T-6)'),
        _Formula('σ̂² = RSS / (n − p − 1)                (T-3)\n'
            'SE(β̂ⱼ) = √[σ̂² ((XᵀX)⁻¹)ⱼⱼ]           (T-4)\n'
            'tⱼ = β̂ⱼ / SE(β̂ⱼ)  ~  t(n−p−1)         (T-5)\n'
            'p値 = 2 × (1 − F_t(|tⱼ|; n−p−1))       (T-6)'),
        _Para('各係数について「本当は 0(効果なし)かもしれない」という帰無仮説を t 検定で'
            '調べ、p 値が小さいほど「偶然とは言いにくい」効果です。表では有意な係数に * を付けます。'),
        _SubHead('あてはまりとモデル選択 (T-7〜T-10)'),
        _Formula('R² = 1 − RSS/TSS                      (T-7)\n'
            '調整済みR² = 1 − (1−R²)(n−1)/(n−p−1)   (T-8)\n'
            'AIC = n·ln(RSS/n) + 2(p+2)            (T-9)\n'
            'VIFⱼ = 1 / (1 − Rⱼ²)                  (T-10)'),
        _Bullet('調整済み R²: 説明変数を増やすと上がりやすい R² を、変数の数で割り引いた指標。'),
        _Bullet('AIC: 同じデータ内でモデルの良さを比べる指標(小さいほど良い)。'),
        _Bullet('VIF: 説明変数どうしの相関の強さ。5 超で注意、10 超で深刻(多重共線性)。'
            '該当する変数には警告バッジが付きます。'),
        _SubHead('カテゴリ変数の読み方'),
        _Para('産地や焙煎度のような分類は、最も件数の多い水準を「基準」とし、残りをダミー変数で'
            '表します。係数は「他の条件が同じとき、基準に対して総合評価が何点変わるか」を意味します。'),
        _NoteCard('総合評価は入力の初期値が 7 のため、未編集のまま保存された記録が多いと結果が'
            '偏ることがあります。該当が多い場合は警告を表示するので、割り引いて解釈してください。'),
      ],
    );
  }

  // --- PCA ---

  Widget _pcaSection() {
    return _sectionCard(
      StatsTheorySection.pca,
      children: const [
        _Para('香り・酸味・甘み・複雑さ・風味・苦味の6つの味覚軸は互いに相関します。'
            'PCA(主成分分析)は、これらを情報の損失を抑えつつ少数の新しい軸に'
            'まとめ直し、記録どうしの「味の近さ」を2次元の地図で見えるようにします。'),
        _SubHead('定式化 (T-11〜T-15)'),
        _Formula('R = ZᵀZ/(n−1) = VΛVᵀ                  (T-11)\n'
            '主成分スコア: tᵢ = Z vᵢ                (T-12)\n'
            '寄与率: λᵢ / m                         (T-13)\n'
            '累積寄与率: Σᵢ₌₁..k λᵢ / m             (T-14)\n'
            '負荷量: Lⱼᵢ = vⱼᵢ √λᵢ                  (T-15)'),
        _Para('各軸を標準化(平均0・分散1)した Z の相関行列 R を固有値分解します。'
            '固有値 λ の大きい順が第1・第2…主成分で、その方向にデータが最もばらついています。'
            '味覚6軸は同じ 0〜10 尺度ですが、分散の大きい軸に引っ張られないよう相関行列で統一しています。'),
        _SubHead('読み方'),
        _Bullet('寄与率: その主成分が全体のばらつきの何割を説明するか。'),
        _Bullet('負荷量(loading): 元の味覚軸と主成分の相関係数。'
            '|負荷量| ≥ 0.5 の軸がその主成分の「意味」を作ります(強調表示)。'),
        _Bullet('採用する主成分数の目安として、固有値 ≥ 1(カイザー基準)の線と'
            '累積寄与率 70% を併記します(自動では決めず判断材料として提示)。'),
      ],
    );
  }

  // --- 好みの検定 ---

  Widget _preferenceSection() {
    return _sectionCard(
      StatsTheorySection.preference,
      children: const [
        _Para('「産地×焙煎度」のグループごとに総合評価の平均を出し、'
            'あなたが特定の組み合わせを統計的に高く(または低く)評価しているかを検定します。'),
        _SubHead('平均と信頼区間 (T-22)'),
        _Formula('CI = x̄_g ± t_{0.975, n_g−1} · s_g/√n_g   (T-22)'),
        _Para('各グループの平均 x̄_g と、その平均がどのくらい確からしいかを表す95%信頼区間です。'
            '件数 n_g が少ないほど幅が広くなります。'),
        _SubHead('平均差の検定: Welch の t 検定 (T-23〜T-24)'),
        _Formula('t = (x̄_g − x̄_rest) / √(s_g²/n_g + s_rest²/n_rest)   (T-23)\n'
            'ν = Welch–Satterthwaite 近似の自由度               (T-24)'),
        _Para('あるグループの平均を「それ以外の全記録の平均」と比べ、'
            '差が偶然の範囲かを調べます。ばらつきが等しいと仮定しない Welch 版を使うため、'
            '件数やばらつきが不揃いでも扱えます。'),
        _SubHead('多重比較の補正'),
        _Para('グループが m 個あると、たまたま有意に見える組が出やすくなります。'
            'そこで有意水準を α′ = 0.05 / m に厳しくする Bonferroni 補正で「有意」バッジを判定します。'
            '補正前の p 値も学習用に併記します。'),
        _NoteCard('件数が少ないグループ(目安 n < 5)は検定せず「n不足」と表示します。'
            'この傾向は保存のたびに自動で再計算され、履歴として推移も確認できます。'),
      ],
    );
  }

  // --- GP ---

  Widget _gpSection() {
    return _sectionCard(
      StatsTheorySection.gp,
      children: const [
        _Para('レシピ探索では、記録がまばらな条件でも「湯温×比率×時間を変えたら総合評価が'
            'どうなりそうか」を滑らかに予測します。これにガウス過程回帰(GP)を使います。'),
        _SubHead('カーネルと予測分布 (T-16〜T-19)'),
        _Formula('k(x,x′) = σ_f² exp(−‖x−x′‖² / (2ℓ²))   (T-16)\n'
            'K = [k(xᵢ,xⱼ)] + σ_n² I                (T-17)\n'
            'μ(x*) = k*ᵀ K⁻¹ y                     (T-18)\n'
            'σ²(x*) = k(x*,x*) − k*ᵀ K⁻¹ k*        (T-19)'),
        _Para('「入力が近い条件は結果も近い」という考え方をカーネル(T-16)で表し、'
            '新しい条件 x* での予測を平均 μ と分散 σ²(自信のなさ)の両方で返します(T-18/T-19)。'
            'データの近くでは σ が小さく、遠い条件では σ が大きく=不確かになります。'
            '実装は逆行列を作らず K の Cholesky 分解で安定に解きます。'),
        _SubHead('ハイパーパラメータの選択 (T-20)'),
        _Formula('log p(y|X,θ) = −½ yᵀK⁻¹y − ½ log|K| − (n/2) log 2π   (T-20)\n'
            'ℓ∈{0.5,1,2}, σ_f∈{0.5,1,2}, σ_n∈{0.5,1,1.5} を総当たり'),
        _Para('カーネルの形を決める3つのつまみは、勾配法ではなく固定グリッドの総当たりで'
            '「対数周辺尤度(データへの当てはまりの良さ)」が最大の組を選びます。'),
        _SubHead('次に試す条件の選び方: 期待改善量 EI (T-21)'),
        _Formula('z = (μ(x) − f* − ξ) / σ(x),   ξ = 0.01\n'
            'EI(x) = (μ(x) − f* − ξ)Φ(z) + σ(x)φ(z)   (T-21)'),
        _Para('f* は現時点の最高スコア。EI は「予測が高い(活用)」と「不確かで伸びしろがある'
            '(探索)」のバランスを取る指標です。μ が最大の条件を〈おすすめ〉、'
            'EI が最大の条件を〈試す価値がある〉として2種類提示します。'),
        _NoteCard('学習に使える有効データ(n_eff)が少ないと予測は不安定です。目安を下回るときは'
            '予測マップを出さず、記録を増やすようご案内します。'),
      ],
    );
  }

  // --- レシピ提案 ---

  Widget _suggestionSection() {
    return _sectionCard(
      StatsTheorySection.suggestion,
      children: const [
        _Para('ダッシュボードの「今日のおすすめレシピ」は、在庫のある豆それぞれに対して'
            '次の抽出条件を提案します。データ量に応じて2つの方法を使い分けます。'),
        _SubHead('十分なデータがあるとき: GP による提案'),
        _Para('その豆の「産地×焙煎度」に有効データが十分あれば、ガウス過程(F4)で'
            '湯温×比率×時間の空間を探索し、予測スコアが最大になる条件を'
            '予測区間つきで提案します。ときどき EI 最大の「実験的な条件」も提示します。'),
        _SubHead('データが少ないとき: 過去最高記録から'),
        _Para('有効データが目安に満たないときは、同じグループ(産地×焙煎度)の過去記録の中で'
            '総合評価が最も高かったときの条件を、そのまま「これがうまくいった条件です」として提案します。'
            '該当する記録も無ければ提案は控えます。'),
        _NoteCard('提案は過去データに基づく仮説です。提案から淹れて評価を記録すると、'
            'その結果が次回以降の提案に反映され、精度が上がっていきます。'),
      ],
    );
  }

  Widget _sourceNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        '式番号(T-1 など)は設計書 statistics_feature_design.md §2 と対応し、'
        'アプリ内の各計算の実装と一致しています。',
        style: TextStyle(fontSize: 11, color: kMocha, height: 1.6),
      ),
    );
  }
}

// --- 本文パーツ ---

/// 段落。
class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: kEspresso, height: 1.7),
      ),
    );
  }
}

/// 小見出し。
class _SubHead extends StatelessWidget {
  final String text;
  const _SubHead(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: kMocha,
        ),
      ),
    );
  }
}

/// 箇条書き1行。
class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.circle, size: 6, color: kAccent),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: kEspresso, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 等幅の数式ブロック(横スクロール可)。
class _Formula extends StatelessWidget {
  final String text;
  const _Formula(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kLatte),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12.5,
            color: kEspresso,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}

/// 注意・補足カード。
class _NoteCard extends StatelessWidget {
  final String text;
  const _NoteCard(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6, top: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0C36D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFB8860B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A5A00), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
