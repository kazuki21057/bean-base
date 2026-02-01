// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoffeeRecord _$CoffeeRecordFromJson(Map<String, dynamic> json) => CoffeeRecord(
  id: json['id'] as String? ?? '',
  brewedAt: CoffeeRecord._parseDateTime(json['brewedAt']),
  grinderId: json['grinderId'] as String? ?? '',
  dripperId: json['dripperId'] as String? ?? '',
  filterId: json['filterId'] as String? ?? '',
  beanId: json['beanId'] as String? ?? '',
  roastLevel: json['roastLevel'] as String? ?? '',
  origin: json['origin'] as String? ?? '',
  beanWeight: CoffeeRecord._parseDouble(json['beanWeight']),
  grindSize: CoffeeRecord._parseString(json['grindSize']),
  methodId: CoffeeRecord._parseString(json['methodId']),
  taste: CoffeeRecord._parseString(json['taste']),
  concentration: CoffeeRecord._parseString(json['concentration']),
  temperature: CoffeeRecord._parseDouble(json['temperature']),
  bloomingWater: CoffeeRecord._parseDouble(json['bloomingWater']),
  totalWater: CoffeeRecord._parseDouble(json['totalWater']),
  bloomingTime: CoffeeRecord._parseInt(json['bloomingTime']),
  totalTime: CoffeeRecord._parseInt(json['totalTime']),
  scoreFragrance: CoffeeRecord._parseInt(json['scoreFragrance']),
  scoreAcidity: CoffeeRecord._parseInt(json['scoreAcidity']),
  scoreBitterness: CoffeeRecord._parseInt(json['scoreBitterness']),
  scoreSweetness: CoffeeRecord._parseInt(json['scoreSweetness']),
  scoreComplexity: CoffeeRecord._parseInt(json['scoreComplexity']),
  scoreFlavor: CoffeeRecord._parseInt(json['scoreFlavor']),
  scoreOverall: CoffeeRecord._parseInt(json['scoreOverall']),
  comment: json['comment'] as String? ?? '',
  grinderImageUrl: json['grinderImageUrl'] as String?,
  dripperImageUrl: json['dripperImageUrl'] as String?,
  filterImageUrl: json['filterImageUrl'] as String?,
  beanImageUrl: json['beanImageUrl'] as String?,
);

Map<String, dynamic> _$CoffeeRecordToJson(CoffeeRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brewedAt': instance.brewedAt.toIso8601String(),
      'grinderId': instance.grinderId,
      'dripperId': instance.dripperId,
      'filterId': instance.filterId,
      'beanId': instance.beanId,
      'roastLevel': instance.roastLevel,
      'origin': instance.origin,
      'beanWeight': instance.beanWeight,
      'grindSize': instance.grindSize,
      'methodId': instance.methodId,
      'taste': instance.taste,
      'concentration': instance.concentration,
      'temperature': instance.temperature,
      'bloomingWater': instance.bloomingWater,
      'totalWater': instance.totalWater,
      'bloomingTime': instance.bloomingTime,
      'totalTime': instance.totalTime,
      'scoreFragrance': instance.scoreFragrance,
      'scoreAcidity': instance.scoreAcidity,
      'scoreBitterness': instance.scoreBitterness,
      'scoreSweetness': instance.scoreSweetness,
      'scoreComplexity': instance.scoreComplexity,
      'scoreFlavor': instance.scoreFlavor,
      'scoreOverall': instance.scoreOverall,
      'comment': instance.comment,
      'grinderImageUrl': instance.grinderImageUrl,
      'dripperImageUrl': instance.dripperImageUrl,
      'filterImageUrl': instance.filterImageUrl,
      'beanImageUrl': instance.beanImageUrl,
    };
