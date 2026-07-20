// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'origin_master.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginMaster _$OriginMasterFromJson(Map<String, dynamic> json) => OriginMaster(
  id: json['id'] == null ? '' : OriginMaster._parseString(json['id']),
  countryCode: json['countryCode'] as String? ?? '',
  nameJa: json['nameJa'] as String? ?? '',
  nameEn: json['nameEn'] as String? ?? '',
  region: json['region'] as String? ?? '',
);

Map<String, dynamic> _$OriginMasterToJson(OriginMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'countryCode': instance.countryCode,
      'nameJa': instance.nameJa,
      'nameEn': instance.nameEn,
      'region': instance.region,
    };
