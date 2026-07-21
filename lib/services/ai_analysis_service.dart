import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'regression_service.dart';
import 'statistics_service.dart';

/// 複数モデルのフォールバック順 (新しい順、ユーザー検証結果に基づく)。
const _kGeminiModels = ['gemini-2.5-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash'];

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

class AiAnalysisService {
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
    for (final modelName in _kGeminiModels) {
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
        debugPrint('[Antigravity] Gemini Model $modelName failed (extractBeanInfoFromImage): $e');
        lastError = e;
      }
    }
    throw Exception('画像からの情報抽出に失敗しました: $lastError');
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
  Future<String> interpretRegression(RegressionResult result, String apiKey) async {
    if (apiKey.isEmpty) return 'APIキーが設定されていません。';

    final prompt = _buildRegressionPrompt(result);

    for (final modelName in _kGeminiModels) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? '解釈結果が生成されませんでした。';
      } catch (e) {
        debugPrint('[Antigravity] Gemini Model $modelName failed (interpretRegression): $e');
        if (modelName == _kGeminiModels.last) {
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

  Future<String> analyzeComponents(List<PcaComponent> components, String apiKey) async {
    if (components.isEmpty) return "No components to analyze.";
    if (apiKey.isEmpty) return "API Key is missing.";

    // Prioritize newer models as per user testing
    final modelsToTry = ['gemini-2.5-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash'];
    
    final prompt = _buildPrompt(components);

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName, 
          apiKey: apiKey,
        );

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        return response.text ?? "No analysis result generated.";
      } catch (e) {
        debugPrint('Gemini Model $modelName failed: $e');
        if (modelName == modelsToTry.last) {
           return "AI Analysis Failed.\nError: $e\n\nPlease check your API Key and ensure the 'Generative Language API' is enabled in your Google Cloud Console.";
        }
      }
    }
    return "AI Analysis Failed (Unknown Error).";
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
  }) async {
    if (apiKey.isEmpty) return 'APIキーが設定されていません。';

    final prompt = _buildDeepPrompt(pc1, pc2, topPc1Summary, bottomPc1Summary);

    for (final modelName in _kGeminiModels) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? '解釈結果が生成されませんでした。';
      } catch (e) {
        debugPrint('[Antigravity] Gemini Model $modelName failed (analyzeComponentsDeep): $e');
        if (modelName == _kGeminiModels.last) {
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
