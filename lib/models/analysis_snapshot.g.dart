// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalysisSnapshot _$AnalysisSnapshotFromJson(Map<String, dynamic> json) =>
    AnalysisSnapshot(
      id: json['id'] == null ? '' : AnalysisSnapshot._parseString(json['id']),
      createdAt: AnalysisSnapshot._parseDateTime(json['createdAt']),
      type: json['type'] as String? ?? '',
      dataCount: AnalysisSnapshot._parseInt(json['dataCount']),
      payloadJson: json['payloadJson'] as String? ?? '',
    );

Map<String, dynamic> _$AnalysisSnapshotToJson(AnalysisSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': instance.type,
      'dataCount': instance.dataCount,
      'payloadJson': instance.payloadJson,
    };
