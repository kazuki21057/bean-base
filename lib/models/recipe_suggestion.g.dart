// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_suggestion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeSuggestion _$RecipeSuggestionFromJson(Map<String, dynamic> json) =>
    RecipeSuggestion(
      id: json['id'] == null ? '' : RecipeSuggestion._parseString(json['id']),
      createdAt: RecipeSuggestion._parseDateTime(json['createdAt']),
      beanId: json['beanId'] as String? ?? '',
      originId: json['originId'] as String? ?? '',
      roastLevel: json['roastLevel'] as String? ?? '',
      temperature: RecipeSuggestion._parseDouble(json['temperature']),
      brewRatio: RecipeSuggestion._parseDouble(json['brewRatio']),
      totalTimeSec: RecipeSuggestion._parseInt(json['totalTimeSec']),
      rationale: json['rationale'] as String? ?? '',
      accepted: json['accepted'] as String? ?? '',
      resultRecordId: json['resultRecordId'] as String? ?? '',
    );

Map<String, dynamic> _$RecipeSuggestionToJson(RecipeSuggestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'beanId': instance.beanId,
      'originId': instance.originId,
      'roastLevel': instance.roastLevel,
      'temperature': instance.temperature,
      'brewRatio': instance.brewRatio,
      'totalTimeSec': instance.totalTimeSec,
      'rationale': instance.rationale,
      'accepted': instance.accepted,
      'resultRecordId': instance.resultRecordId,
    };
