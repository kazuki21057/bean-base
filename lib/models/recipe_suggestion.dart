import 'package:json_annotation/json_annotation.dart';

part 'recipe_suggestion.g.dart';

/// レシピ提案の記録 (設計書§7.4)。
///
/// モデル自体はT4-1d(データ基盤/F6)でDataService配線の一部として先行導入する。
/// 実際に提案を生成・表示するロジック(SuggestionService・ダッシュボードカード)は
/// T4-5b(F3)以降で実装する。
@JsonSerializable()
class RecipeSuggestion {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;
  @JsonKey(defaultValue: '')
  final String beanId;
  @JsonKey(defaultValue: '')
  final String originId;
  @JsonKey(defaultValue: '')
  final String roastLevel;
  @JsonKey(fromJson: _parseDouble)
  final double temperature;
  @JsonKey(fromJson: _parseDouble)
  final double brewRatio;
  @JsonKey(fromJson: _parseInt)
  final int totalTimeSec;
  @JsonKey(defaultValue: '')
  final String rationale;
  @JsonKey(defaultValue: '')
  final String accepted;
  @JsonKey(defaultValue: '')
  final String resultRecordId;

  RecipeSuggestion({
    required this.id,
    required this.createdAt,
    required this.beanId,
    required this.originId,
    required this.roastLevel,
    required this.temperature,
    required this.brewRatio,
    required this.totalTimeSec,
    required this.rationale,
    required this.accepted,
    required this.resultRecordId,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) =>
      _$RecipeSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSuggestionToJson(this);

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      if (value.trim().isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  RecipeSuggestion copyWith({
    String? id,
    DateTime? createdAt,
    String? beanId,
    String? originId,
    String? roastLevel,
    double? temperature,
    double? brewRatio,
    int? totalTimeSec,
    String? rationale,
    String? accepted,
    String? resultRecordId,
  }) {
    return RecipeSuggestion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      beanId: beanId ?? this.beanId,
      originId: originId ?? this.originId,
      roastLevel: roastLevel ?? this.roastLevel,
      temperature: temperature ?? this.temperature,
      brewRatio: brewRatio ?? this.brewRatio,
      totalTimeSec: totalTimeSec ?? this.totalTimeSec,
      rationale: rationale ?? this.rationale,
      accepted: accepted ?? this.accepted,
      resultRecordId: resultRecordId ?? this.resultRecordId,
    );
  }
}
