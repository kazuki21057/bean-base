// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bean_master.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeanMaster _$BeanMasterFromJson(Map<String, dynamic> json) => BeanMaster(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '-',
  roastLevel: json['roastLevel'] as String? ?? '',
  origin: json['origin'] as String? ?? '',
  store: json['store'] as String? ?? '',
  type: json['type'] as String? ?? '',
  imageUrl: json['imageUrl'] as String?,
  purchaseDate: BeanMaster._parseDate(json['purchaseDate']),
  firstUseDate: BeanMaster._parseDate(json['firstUseDate']),
  lastUseDate: BeanMaster._parseDate(json['lastUseDate']),
  isInStock: json['isInStock'] == null
      ? false
      : BeanMaster._parseBool(json['isInStock']),
);

Map<String, dynamic> _$BeanMasterToJson(BeanMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'roastLevel': instance.roastLevel,
      'origin': instance.origin,
      'store': instance.store,
      'type': instance.type,
      'imageUrl': instance.imageUrl,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'firstUseDate': instance.firstUseDate?.toIso8601String(),
      'lastUseDate': instance.lastUseDate?.toIso8601String(),
      'isInStock': instance.isInStock,
    };
