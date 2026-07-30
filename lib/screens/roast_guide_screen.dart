import 'package:flutter/material.dart';

import '../routing/app_screen.dart';
import '../services/math/encoding.dart';
import '../widgets/roast_level_slider.dart';
import 'create/create_form_widgets.dart';
import 'mock/mock_scaffold.dart';

/// 044 焙煎度8段階ガイド (T3-51)。
///
/// `roastOrdinalMap`/`roastLevels8`(`lib/services/math/encoding.dart`)が
/// 定義する8段階(ライト〜イタリアン)それぞれについて、日本語名・英語表記・
/// 味わいの特徴(酸味/苦味/コクのバランス)・見た目の色味・適した抽出方法を
/// 解説する。012/011の焙煎度スライダー([RoastLevelSlider])の `trailing` に
/// 置く [RoastGuideLink] から遷移する。
///
/// 構成は041(統計の理論と読み方、`stats_theory_screen.dart`)と同じ
/// パターン(`MockScreenScaffold`+目次チップ+`FormSection`+
/// `Scrollable.ensureVisible`による自動スクロール)を踏襲している。
class _RoastStageInfo {
  final String appearance;
  final String balance;
  final String brewMethod;

  const _RoastStageInfo({
    required this.appearance,
    required this.balance,
    required this.brewMethod,
  });
}

/// 8段階それぞれの解説文(浅い順、`roastLevels8`と同じ並び)。
const List<_RoastStageInfo> _roastStages = [
  _RoastStageInfo(
    appearance: 'いちばん浅い、薄い黄褐色。豆の質感はまだ生豆に近い。',
    balance: '酸味が最も強く突出し、コーヒー特有のコクや香ばしさはほとんど生まれていない。',
    brewMethod: '品質評価(カッピング)向けの焙煎度で、家庭での抽出にはあまり使われない。',
  ),
  _RoastStageInfo(
    appearance: 'シナモンのような明るい茶色。',
    balance: '強い酸味が続き、フルーティーな香りが立つ一方で青臭さが残ることもある。',
    brewMethod: '酸味の個性を楽しむシングルオリジンの浅煎り系ペーパードリップ向き。',
  ),
  _RoastStageInfo(
    appearance: '中程度の茶色(アメリカンローストとも呼ばれる)。',
    balance: '香ばしさとまろやかな酸味が出始め、苦味はごくわずか。',
    brewMethod: 'ペーパードリップ全般。酸味を活かしたアメリカンコーヒーにも使われる。',
  ),
  _RoastStageInfo(
    appearance: 'ミディアムよりやや濃い茶色。',
    balance: 'さわやかな酸味と苦味・甘みのバランスが良く、日本で好まれるレギュラーコーヒーの定番域。',
    brewMethod: 'ペーパードリップ全般。幅広い豆・メソッドに合わせやすい万人向けの深さ。',
  ),
  _RoastStageInfo(
    appearance: '濃い茶色。深煎りの入り口。',
    balance: '酸味と苦味のバランスが最も取れているとされ、「標準」的な深さとしてよく使われる。',
    brewMethod: 'ペーパードリップ・ハンドドリップ全般。エスプレッソに使われ始める深さでもある。',
  ),
  _RoastStageInfo(
    appearance: 'シティよりさらに濃く、豆の表面にわずかな油分が浮き始める。',
    balance: '酸味が落ち着き、苦味とコクが際立つ香ばしい味わいになる。',
    brewMethod: 'アイスコーヒー、エスプレッソ。',
  ),
  _RoastStageInfo(
    appearance: '黒に近い焦げ茶色。豆の表面全体が油でおおわれる。',
    balance: '酸味はほぼ感じられなくなり、強い苦味とロースト由来の香ばしさが前面に出る。',
    brewMethod: 'ミルクと合わせるカフェオレ、ウィンナーコーヒーなど。',
  ),
  _RoastStageInfo(
    appearance: '8段階で最も深く、ほぼ黒。油分で表面につやがある。',
    balance: '最も重厚な苦味と濃いコク。酸味はほぼ感じられない。',
    brewMethod: 'エスプレッソ、カプチーノなどイタリア式コーヒー。',
  ),
];

/// 浅煎り(ベージュ)→深煎り(ダークブラウン)を8段階に補間した色。
/// [RoastLevelSlider] のトラック色([kRoastLightest]/[kRoastDarkest])と
/// 同じ配色にして、スライダーとガイドページの見た目を対応させる。
List<Color> _roastStageColors() {
  return List.generate(8, (i) {
    final t = i / 7;
    return Color.lerp(kRoastLightest, kRoastDarkest, t)!;
  });
}

/// [RoastLevelSlider]/[RoastRangeSlider] の `trailing` に置く「焙煎度の説明を読む」導線。
///
/// [currentLabel] を渡すと、開いたときにその段階までスクロールする
/// (`roastOrdinalMap` で解決できない値・null の場合は先頭から表示)。
class RoastGuideLink extends StatelessWidget {
  final String? currentLabel;
  final String tooltip;

  const RoastGuideLink({
    super.key,
    this.currentLabel,
    this.tooltip = '焙煎度8段階の説明を読む',
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
        final ordinal =
            currentLabel == null ? null : roastOrdinalMap[currentLabel];
        final initialIndex =
            (ordinal != null && ordinal >= 1.0 && ordinal <= 8.0)
                ? ordinal.toInt() - 1
                : null;
        debugPrint(
            '[Antigravity] Action: 焙煎度ガイド(044)へ遷移 currentLabel=$currentLabel');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoastGuideScreen(initialIndex: initialIndex),
          ),
        );
      },
    );
  }
}

class RoastGuideScreen extends StatefulWidget {
  /// 開いたときに自動スクロールして表示する段階の index(0=ライト〜7=イタリアン)。
  final int? initialIndex;

  const RoastGuideScreen({super.key, this.initialIndex});

  @override
  State<RoastGuideScreen> createState() => _RoastGuideScreenState();
}

class _RoastGuideScreenState extends State<RoastGuideScreen> {
  late final List<GlobalKey> _keys = List.generate(8, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    final target = widget.initialIndex;
    if (target != null && target > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(target));
    }
  }

  void _scrollTo(int index) {
    final ctx = _keys[index].currentContext;
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
    final colors = _roastStageColors();
    return MockScreenScaffold(
      screen: AppScreen.roastGuide,
      showSettingsAction: false,
      maxWidth: 720,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tableOfContents(colors),
            _introSection(),
            for (int i = 0; i < 8; i++) _stageSection(i, colors[i]),
            const SizedBox(height: 12),
            _sourceNote(),
          ],
        ),
      ],
    );
  }

  Widget _tableOfContents(List<Color> colors) {
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
                  '焙煎度8段階ガイド',
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
            'ライトからイタリアンまでの8段階それぞれの特徴を解説します。読みたい段階をタップしてください。',
            style: TextStyle(fontSize: 12, color: kLatte, height: 1.6),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < 8; i++)
                ActionChip(
                  avatar: CircleAvatar(radius: 7, backgroundColor: colors[i]),
                  label: Text('${roastLevels8[i]} ${i + 1}/8'),
                  backgroundColor: kCream,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: kEspresso,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _scrollTo(i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _introSection() {
    return FormSection(
      icon: Icons.auto_stories_outlined,
      title: 'はじめに',
      children: const [
        _Para(
          'BeanBase は焙煎度を「ライト/シナモン/ミディアム/ハイ/シティ/フルシティ/フレンチ/'
          'イタリアン」の8段階(浅い順)で扱います。豆の登録・メソッドの推奨焙煎度・'
          '統計分析は、すべてこの8段階を基準にしています。',
        ),
        _Bullet('以前のバージョンで使われていた5段階表記(浅煎り/中浅煎り/中煎り/中深煎り/深煎り)'
            'のデータは、対応する8段階のいずれかとして引き続き扱われます。'),
        _Bullet('段階の境目は焙煎所や豆の個性によって前後します。ここでの説明は一般的な目安です。'),
      ],
    );
  }

  Widget _stageSection(int index, Color color) {
    final info = _roastStages[index];
    return FormSection(
      key: _keys[index],
      icon: Icons.circle,
      title: '${roastLevels8[index]} (${roastLevels8En[index]})  ${index + 1}/8',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: kLatte),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabeledLine('見た目の色味', info.appearance),
                  _LabeledLine('酸味/苦味/コクのバランス', info.balance),
                  _LabeledLine('適した抽出方法', info.brewMethod),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sourceNote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        '段階の名称・並びは lib/services/math/encoding.dart の roastLevels8 と一致しています。',
        style: TextStyle(fontSize: 11, color: kMocha, height: 1.6),
      ),
    );
  }
}

// --- 本文パーツ ---

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

/// ラベル+説明文の1行(見た目の色味/バランス/抽出方法の3項目で使う)。
class _LabeledLine extends StatelessWidget {
  final String label;
  final String text;
  const _LabeledLine(this.label, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kMocha,
            ),
          ),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: kEspresso, height: 1.6),
          ),
        ],
      ),
    );
  }
}
