import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'statistics_service.dart';

class AiAnalysisService {
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
