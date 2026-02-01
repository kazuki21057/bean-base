// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'method_master.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MethodMaster _$MethodMasterFromJson(Map<String, dynamic> json) => MethodMaster(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '-',
  author: json['author'] as String? ?? '',
  baseBeanWeight: (json['baseBeanWeight'] as num?)?.toDouble() ?? 0.0,
  baseWaterAmount: (json['baseWaterAmount'] as num?)?.toDouble() ?? 0.0,
  temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
  grindSize: json['grindSize'] as String?,
  description: json['description'] as String? ?? '',
  recommendedEquipment: json['recommendedEquipment'] as String? ?? '',
  sourceUrl: json['sourceUrl'] as String?,
);

Map<String, dynamic> _$MethodMasterToJson(MethodMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'baseBeanWeight': instance.baseBeanWeight,
      'baseWaterAmount': instance.baseWaterAmount,
      'temperature': instance.temperature,
      'grindSize': instance.grindSize,
      'description': instance.description,
      'recommendedEquipment': instance.recommendedEquipment,
      'sourceUrl': instance.sourceUrl,
    };
