// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pouring_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PouringStep _$PouringStepFromJson(Map<String, dynamic> json) => PouringStep(
  id: json['id'] as String? ?? '',
  methodId: json['methodId'] as String? ?? '',
  stepOrder: (json['stepOrder'] as num?)?.toInt() ?? 0,
  duration: (json['duration'] as num?)?.toInt() ?? 0,
  waterAmount: (json['waterAmount'] as num?)?.toDouble() ?? 0.0,
  waterReference: (json['waterReference'] as num?)?.toDouble() ?? 0.0,
  waterRatio: (json['waterRatio'] as num?)?.toDouble(),
  description: json['description'] as String? ?? '',
);

Map<String, dynamic> _$PouringStepToJson(PouringStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'methodId': instance.methodId,
      'stepOrder': instance.stepOrder,
      'duration': instance.duration,
      'waterAmount': instance.waterAmount,
      'waterReference': instance.waterReference,
      'waterRatio': instance.waterRatio,
      'description': instance.description,
    };
