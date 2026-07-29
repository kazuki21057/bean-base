import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'regression_service.dart';
import 'statistics_service.dart';

/// 複数モデルのフォールバック順 (新しい順、ユーザー検証結果に基づく)。
/// T3-39(2026-07-25): `gemini-1.5-flash`は`https://ai.google.dev/gemini-api/docs/pricing?hl=ja`
/// の現行モデル一覧に存在しなくなっていたため`gemini-2.0-flash`に置き換えて最新化した。
const _kGeminiModels = ['gemini-2.5-flash', 'gemini-2.0-flash-lite', 'gemini-2.0-flash'];

/// T3-39: 設定(090→モデル設定)でユーザーが選択できるモデルの選択肢。
/// `https://ai.google.dev/gemini-api/docs/pricing?hl=ja`(2026-07-25時点)を参照し、
/// テキスト/画像入力に対応する汎用モデル(preview版・画像/動画/音声/embedding等の
/// 専用モデルを除く)を新しい順に厳選した。
const kSelectableGeminiModels = [
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-2.5-pro',
  'gemini-2.0-flash',
  'gemini-2.0-flash-lite',
  'gemini-3.5-flash',
  'gemini-3.1-flash-lite',
];

/// T3-30: 豆の説明カード/パッケージ画像からGemini Visionで抽出した豆情報。
/// 各項目は読み取れなければnull(呼び出し側は既存のフォーム値を維持する)。
class ExtractedBeanInfo {
  final String? name;
  final String? store;
  final String? origin;
  final String? roastLevel;
  final String? type;
  final DateTime? roastDate;

  const ExtractedBeanInfo({
    this.name,
    this.store,
    this.origin,
    this.roastLevel,
    this.type,
    this.roastDate,
  });

  bool get isEmpty =>
      name == null && store == null && origin == null && roastLevel == null && type == null && roastDate == null;
}

/// T3-70(設計書`docs/store_master_design.md`§8.3): 新規購入店の情報をAIで自動取得した結果。
/// `StoreMaster`の13項目(id/name/memo/imageUrl/sourceUrl/infoFetchedAtを除く)を対象とし、
/// 項目ごとに`confidence`(high/medium/low)を必ず併記する。値が確信できない項目はnull。
class StoreInfoCandidate {
  /// 同名の別店舗が複数存在し、AIが1つに絞れなかった場合はtrue。
  /// この場合、他のフィールドはすべて空(候補提示のみ)。
  final bool ambiguous;
  final List<String> candidates;

  final String? formalName;
  final String? url;
  final String? prefecture;
  final String? address;
  final bool? hasOnlineShop;
  final bool? hasPhysicalStore;
  final bool? hasRoastery;
  final String? beanTendency;
  final String? snsUrl;
  final String? businessHours;
  final String? closedDays;
  final String? phone;
  final String? openedYear;

  /// `StoreMaster`のDartフィールド名 → 'high'/'medium'/'low'。値がnullの項目は含まれない。
  final Map<String, String> confidence;
  final List<String> sourceUrls;

  const StoreInfoCandidate({
    this.ambiguous = false,
    this.candidates = const [],
    this.formalName,
    this.url,
    this.prefecture,
    this.address,
    this.hasOnlineShop,
    this.hasPhysicalStore,
    this.hasRoastery,
    this.beanTendency,
    this.snsUrl,
    this.businessHours,
    this.closedDays,
    this.phone,
    this.openedYear,
    this.confidence = const {},
    this.sourceUrls = const [],
  });

  bool get isEmpty =>
      !ambiguous &&
      formalName == null &&
      url == null &&
      prefecture == null &&
      address == null &&
      hasOnlineShop == null &&
      hasPhysicalStore == null &&
      hasRoastery == null &&
      beanTendency == null &&
      snsUrl == null &&
      businessHours == null &&
      closedDays == null &&
      phone == null &&
      openedYear == null;

  factory StoreInfoCandidate.fromJson(Map<String, dynamic> json) {
    final confidence = <String, String>{};
    String? readString(String key) {
      final field = json[key];
      if (field is! Map) return null;
      final v = field['value'];
      final c = field['confidence'];
      if (v is! String || v.trim().isEmpty) return null;
      if (c is String && c.isNotEmpty) confidence[key] = c;
      return v.trim();
    }

    bool? readBool(String key) {
      final field = json[key];
      if (field is! Map) return null;
      final v = field['value'];
      final c = field['confidence'];
      if (v is! bool) return null;
      if (c is String && c.isNotEmpty) confidence[key] = c;
      return v;
    }

    return StoreInfoCandidate(
      ambiguous: json['ambiguous'] == true,
      candidates: (json['candidates'] as List?)?.whereType<String>().toList() ?? const [],
      formalName: readString('formalName'),
      url: readString('url'),
      prefecture: readString('prefecture'),
      address: readString('address'),
      hasOnlineShop: readBool('hasOnlineShop'),
      hasPhysicalStore: readBool('hasPhysicalStore'),
      hasRoastery: readBool('hasRoastery'),
      beanTendency: readString('beanTendency'),
      snsUrl: readString('snsUrl'),
      businessHours: readString('businessHours'),
      closedDays: readString('closedDays'),
      phone: readString('phone'),
      openedYear: readString('openedYear'),
      confidence: confidence,
      sourceUrls: (json['sourceUrls'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }
}

class AiAnalysisService {
  /// T3-39: [preferredModel]が指定されていれば先頭に置き、既定のフォールバック順
  /// (`_kGeminiModels`)を後ろに続ける(重複は除く)。未指定・空文字なら既定順のまま。
  List<String> _modelOrder(String? preferredModel) {
    if (preferredModel == null || preferredModel.isEmpty) return _kGeminiModels;
    return [preferredModel, ..._kGeminiModels.where((m) => m != preferredModel)];
  }

  /// T3-30: 豆の説明カード/パッケージ画像から豆情報を抽出する(設計書に無い新機能、
  /// マスタープランT3-30に基づく)。数値統計計算の絶対規則(Gemini非依存)は
  /// テキスト抽出には適用されないため、抽出自体をGeminiに委ねる。
  /// [knownOrigins] は既存OriginMasterのnameJa一覧。一致しやすくするためのヒントとして
  /// プロンプトに含めるのみで、実際の照合は呼び出し側(UI)が担う。
  Future<ExtractedBeanInfo> extractBeanInfoFromImage({
    required Uint8List imageBytes,
    required String mimeType,
    required List<String> knownOrigins,
    required String apiKey,
    String? preferredModel,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('APIキーが設定されていません。設定画面でGemini APIキーを入力してください。');
    }

    final prompt = _buildExtractionPrompt(knownOrigins);
    final schema = Schema.object(properties: {
      'name': Schema.string(description: '豆の名前(銘柄名)', nullable: true),
      'store': Schema.string(description: '焙煎所または購入店名', nullable: true),
      'origin': Schema.string(description: '産地(国名・地域名、日本語カタカナ表記)', nullable: true),
      'roastLevel': Schema.enumString(
        enumValues: const ['浅煎り', '中煎り', '中深煎り', '深煎り'],
        description: '焙煎度',
        nullable: true,
      ),
      'type': Schema.string(description: '品種・精製方法', nullable: true),
      'roastDate': Schema.string(description: '焙煎日 (YYYY-MM-DD形式)', nullable: true),
    });

    Object? lastError;
    for (final modelName in _modelOrder(preferredModel)) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: schema,
          ),
        );
        final content = Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)]);
        debugPrint('[Antigravity] Action: 豆情報のAI抽出を要求 (model=$modelName)');
        final response = await model.generateContent([content]);
        final text = response.text;
        if (text == null || text.isEmpty) {
          throw Exception('抽出結果が空でした');
        }
        final json = jsonDecode(text) as Map<String, dynamic>;
        return ExtractedBeanInfo(
          name: _nonEmptyString(json['name']),
          store: _nonEmptyString(json['store']),
          origin: _nonEmptyString(json['origin']),
          roastLevel: _nonEmptyString(json['roastLevel']),
          type: _nonEmptyString(json['type']),
          roastDate: _tryParseDate(json['roastDate']),
        );
      } catch (e) {
        debugPrint('[Antigravity] Gemini モデル $modelName が失敗 (extractBeanInfoFromImage): $e');
        lastError = e;
      }
    }
    throw Exception('画像からの情報抽出に失敗しました: $lastError');
  }

  /// T3-70(設計書§8.3): 新規購入店の情報をGeminiに取得させる。数値計算ではなく
  /// テキスト情報の収集のため「Gemini非依存」の絶対規則(統計解析機能向け)は適用されない。
  /// Google検索グラウンディングは`google_generative_ai: ^0.4.7`が`Tool`に
  /// `functionDeclarations`/`codeExecution`しか公開しておらず非対応のため、
  /// 非グラウンディングのまま実装する(設計書§8.1の指示どおり、パッケージ追加はしない)。
  Future<StoreInfoCandidate> fetchStoreInfo({
    required String storeName,
    String? hintPrefecture,
    required String apiKey,
    String? preferredModel,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('APIキーが設定されていません。設定画面でGemini APIキーを入力してください。');
    }

    final prompt = _buildStoreInfoPrompt(storeName, hintPrefecture);
    final schema = _storeInfoSchema();

    Object? lastError;
    for (final modelName in _modelOrder(preferredModel)) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: schema,
          ),
        );
        debugPrint('[Antigravity] Action: 購入店情報のAI取得を要求 (model=$modelName, store=$storeName)');
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) {
          throw Exception('取得結果が空でした');
        }
        final json = jsonDecode(text) as Map<String, dynamic>;
        return StoreInfoCandidate.fromJson(json);
      } catch (e) {
        debugPrint('[Antigravity] Gemini モデル $modelName が失敗 (fetchStoreInfo): $e');
        lastError = e;
      }
    }
    throw Exception('購入店情報の取得に失敗しました: $lastError');
  }

  Schema _storeInfoField(Schema valueSchema, String description) => Schema.object(
        nullable: true,
        description: description,
        properties: {
          'value': valueSchema,
          'confidence': Schema.enumString(
            enumValues: const ['high', 'medium', 'low'],
            description: 'この項目の確信度',
            nullable: true,
          ),
        },
      );

  Schema _storeInfoSchema() {
    final s = Schema.string(nullable: true);
    final b = Schema.boolean(nullable: true);
    return Schema.object(properties: {
      'ambiguous': Schema.boolean(description: '同名の別店舗が複数あり1つに絞れない場合はtrue', nullable: true),
      'candidates': Schema.array(
        items: Schema.string(),
        description: 'ambiguousがtrueのときの候補一覧(店名+所在地の簡単な説明)',
        nullable: true,
      ),
      'formalName': _storeInfoField(s, '法人名・正式屋号'),
      'url': _storeInfoField(s, '公式サイトURL'),
      'prefecture': _storeInfoField(s, '都道府県'),
      'address': _storeInfoField(s, '都道府県以下の住所(郵便番号を含めてよい)'),
      'hasOnlineShop': _storeInfoField(b, 'オンライン販売の有無'),
      'hasPhysicalStore': _storeInfoField(b, '実店舗の有無'),
      'hasRoastery': _storeInfoField(b, '焙煎所併設の有無'),
      'beanTendency': _storeInfoField(s, '取扱豆の傾向'),
      'snsUrl': _storeInfoField(s, 'SNS(Instagram等)のURL 1本'),
      'businessHours': _storeInfoField(s, '営業時間'),
      'closedDays': _storeInfoField(s, '定休日'),
      'phone': _storeInfoField(s, '電話番号'),
      'openedYear': _storeInfoField(s, '開業年(西暦4桁の文字列)'),
      'sourceUrls': Schema.array(
        items: Schema.string(),
        description: '情報の出典URL一覧',
        nullable: true,
      ),
    });
  }

  String _buildStoreInfoPrompt(String storeName, String? hintPrefecture) {
    final hint = (hintPrefecture == null || hintPrefecture.isEmpty) ? '' : '(手がかり: 都道府県「$hintPrefecture」)';
    return 'あなたはコーヒー店・自家焙煎コーヒーショップの情報収集アシスタントです。\n'
        '以下の購入店について、公式サイトやSNS等から分かる情報を調べ、指定のJSONスキーマで出力してください。\n'
        '店名: $storeName $hint\n\n'
        '絶対規則:\n'
        '- 確信が持てない項目は必ずvalueをnullにしてください。推測で埋めてはいけません。\n'
        '- 同名または類似名の別店舗が複数存在し、どの店か1つに絞れない場合は、'
        'ambiguousをtrueにしてcandidatesに候補(店名+所在地の簡単な説明)を列挙し、'
        '他の項目はすべてnullにしてください。\n'
        '- 各項目には必ずconfidence(high/medium/low)を付けてください。\n'
        '- sourceUrlsに情報の出典としたURLを列挙してください。\n'
        '- 出力は日本語にしてください。住所は郵便番号を含めてよいです。\n'
        '- 開業年は西暦4桁の文字列(例: "2015")で、不明ならnullにしてください。';
  }

  String? _nonEmptyString(Object? v) => (v is String && v.trim().isNotEmpty) ? v.trim() : null;

  DateTime? _tryParseDate(Object? v) {
    if (v is! String || v.trim().isEmpty) return null;
    return DateTime.tryParse(v.trim());
  }

  String _buildExtractionPrompt(List<String> knownOrigins) {
    final originHint = knownOrigins.isEmpty ? '' : '(既知の産地名の例: ${knownOrigins.join('、')})';
    return 'これはコーヒー豆のパッケージまたは説明カードの画像です。以下の項目を画像から読み取り、'
        '指定のJSONスキーマで出力してください。\n'
        '- name: 豆の名前(銘柄名)\n'
        '- store: 焙煎所または購入店名\n'
        '- origin: 産地(国名・地域名)。日本語カタカナ表記に変換すること$originHint\n'
        '- roastLevel: 焙煎度。浅煎り/中煎り/中深煎り/深煎りのいずれかに分類できる場合のみ設定\n'
        '- type: 品種・精製方法(例: ウォッシュド、ナチュラル、ゲイシャ種など)\n'
        '- roastDate: 焙煎日(YYYY-MM-DD形式)。記載が無ければ設定しない\n'
        '画像から読み取れない項目、または確信が持てない項目は必ずnullにしてください。数値・文字列を推測で埋めないこと。';
  }

  /// F1: 重回帰分析の結果を日本語で解釈する (設計書§8.1)。
  ///
  /// 数値はすべて Dart 側で計算済み。プロンプトは§8.1のテンプレートを固定使用し、
  /// Gemini には再計算させず解釈のみを求める (CLAUDE.md 絶対規則)。
  Future<String> interpretRegression(RegressionResult result, String apiKey, {String? preferredModel}) async {
    if (apiKey.isEmpty) return 'APIキーが設定されていません。';

    final prompt = _buildRegressionPrompt(result);
    final order = _modelOrder(preferredModel);

    for (final modelName in order) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? '解釈結果が生成されませんでした。';
      } catch (e) {
        debugPrint('[Antigravity] Gemini モデル $modelName が失敗 (interpretRegression): $e');
        if (modelName == order.last) {
          return 'AI解釈に失敗しました。\nエラー: $e\n\n'
              'APIキーと、Google Cloud Console で「Generative Language API」が有効か確認してください。';
        }
      }
    }
    return 'AI解釈に失敗しました (原因不明)。';
  }

  String _buildRegressionPrompt(RegressionResult r) {
    final coefTable = StringBuffer();
    for (final c in r.coefficients) {
      final vif = c.vif.isNaN ? '-' : c.vif.toStringAsFixed(2);
      final p = c.pValue.isNaN ? '-' : c.pValue.toStringAsFixed(3);
      coefTable.writeln(
          '${c.name}, ${c.beta.toStringAsFixed(3)}, ${c.se.toStringAsFixed(3)}, $p, $vif');
    }

    // 設計書§8.1のテンプレートを固定使用 (数値のみ Dart 側で埋め込む)。
    return 'あなたはコーヒー抽出と統計学の専門家です。以下は重回帰分析の結果です(計算済み。再計算や数値の変更はしないこと)。\n'
        'モデル: 総合評価(0-10) ~ 抽出条件 + 産地 + 交互作用 / '
        'n=${r.n}, 調整済みR²=${r.adjR2.toStringAsFixed(3)}, AIC=${r.aic.toStringAsFixed(1)}\n'
        '係数表(変数名, 係数, 標準誤差, p値, VIF):\n'
        '${coefTable.toString().trimRight()}\n'
        '注意事項: 観測データのため因果ではなく関連であること、VIF>5の変数は解釈に注意が必要なこと。\n'
        '出力: (1)最も影響が大きい要因トップ3とその実務的な意味 (2)有意でない変数から言えること\n'
        '(3)次に試すべき抽出条件の変更案1つ。各項目2-3文、日本語、断定を避けた表現で。';
  }

  Future<String> analyzeComponents(List<PcaComponent> components, String apiKey, {String? preferredModel}) async {
    if (components.isEmpty) return '分析対象の成分がありません。';
    if (apiKey.isEmpty) return 'APIキーが設定されていません。';

    final modelsToTry = _modelOrder(preferredModel);

    final prompt = _buildPrompt(components);

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        return response.text ?? '解釈結果が生成されませんでした。';
      } catch (e) {
        debugPrint('[Antigravity] Gemini モデル $modelName が失敗: $e');
        if (modelName == modelsToTry.last) {
           return 'AI解釈に失敗しました。\nエラー: $e\n\nAPIキーと、Google Cloud Console で「Generative Language API」が有効か確認してください。';
        }
      }
    }
    return 'AI解釈に失敗しました (原因不明)。';
  }

  /// F2拡張: PCA深掘り解釈(設計書§8.2、T4-3b)。既存`analyzeComponents`(簡易版)を
  /// 置換せず別メソッドとして追加。負荷量・寄与率に加え、PC1スコア上位/下位5件の
  /// 産地/焙煎度/湯温の要約(Dart側で集計済み)をプロンプトに含めることで、
  /// 主成分と実際の抽出条件を結びつけた解釈をGeminiに求める。
  Future<String> analyzeComponentsDeep({
    required PcaComponent pc1,
    required PcaComponent pc2,
    required String topPc1Summary,
    required String bottomPc1Summary,
    required String apiKey,
    String? preferredModel,
  }) async {
    if (apiKey.isEmpty) return 'APIキーが設定されていません。';

    final prompt = _buildDeepPrompt(pc1, pc2, topPc1Summary, bottomPc1Summary);
    final order = _modelOrder(preferredModel);

    for (final modelName in order) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? '解釈結果が生成されませんでした。';
      } catch (e) {
        debugPrint('[Antigravity] Gemini モデル $modelName が失敗 (analyzeComponentsDeep): $e');
        if (modelName == order.last) {
          return 'AI解釈に失敗しました。\nエラー: $e\n\n'
              'APIキーと、Google Cloud Console で「Generative Language API」が有効か確認してください。';
        }
      }
    }
    return 'AI解釈に失敗しました (原因不明)。';
  }

  String _buildDeepPrompt(
    PcaComponent pc1,
    PcaComponent pc2,
    String topPc1Summary,
    String bottomPc1Summary,
  ) {
    String loadingsText(PcaComponent c) => c.contributions.entries
        .map((e) => '${e.key}:${e.value.toStringAsFixed(2)}')
        .join(', ');

    // 設計書§8.2のテンプレートを固定使用 (数値・要約はDart側で埋め込む)。
    return 'あなたはコーヒーの官能評価と多変量解析の専門家です。味覚6軸(香り/酸味/苦味/甘味/複雑さ/フレーバー)の\n'
        '主成分分析結果です(相関行列ベース、計算済み)。\n'
        'PC1: 寄与率${(pc1.contributionRatio * 100).toStringAsFixed(1)}%, 負荷量: ${loadingsText(pc1)}\n'
        'PC2: 寄与率${(pc2.contributionRatio * 100).toStringAsFixed(1)}%, 負荷量: ${loadingsText(pc2)}\n'
        '高PC1スコアの抽出記録の特徴(上位5件の産地/焙煎度/湯温の要約): $topPc1Summary\n'
        '低PC1スコア側の同要約: $bottomPc1Summary\n'
        '出力: (1)PC1とPC2それぞれの軸の意味を一言で命名し根拠を負荷量から説明\n'
        '(2)このユーザーの味覚空間の構造について言えること (3)散布図の見方のアドバイス。\n'
        '日本語、各項目3文以内。負荷量の絶対値0.5未満の変数を主要根拠にしないこと。';
  }

  String _buildPrompt(List<PcaComponent> components) {
    final buffer = StringBuffer();
    buffer.writeln("You are a coffee flavor expert data analyst.");
    buffer.writeln("I have performed Principal Component Analysis (PCA) on coffee flavor data.");
    buffer.writeln("Here are the top components and their feature loadings (correlations):");
    
    for (var c in components) {
      buffer.writeln("\n${c.name}:");
      // Sort features by absolute value to highlight important ones
      final sortedEntries = c.contributions.entries.toList()
        ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
      
      for (var e in sortedEntries) {
        buffer.writeln("- ${e.key}: ${e.value.toStringAsFixed(2)}");
      }
    }
    
    buffer.writeln("\nTask: Interpret what these principal components likely represent in the context of coffee tasting.");
    buffer.writeln("For example, does PC1 represent 'Roast Level' (Bitterness vs Acidity)? Or 'Fruitiness'?");
    buffer.writeln("Please provide a concise explanation for PC1 and PC2 in 1-2 sentences each.");
    buffer.writeln("IMPORTANT: Please respond in Japanese.");
    buffer.writeln("output format: Start directly with the interpretation. Do not include introductory phrases like 'Here is the analysis' or 'I will interpret'.");
    buffer.writeln("Example format:\n**PC1の解釈:** ...\n**PC2の解釈:** ...");
    return buffer.toString();
  }
}

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService();
});
