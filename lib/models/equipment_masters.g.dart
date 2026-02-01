// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'equipment_masters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrinderMaster _$GrinderMasterFromJson(Map<String, dynamic> json) =>
    GrinderMaster(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      grindRange: json['grindRange'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$GrinderMasterToJson(GrinderMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'grindRange': instance.grindRange,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
    };

DripperMaster _$DripperMasterFromJson(Map<String, dynamic> json) =>
    DripperMaster(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      material: json['material'] as String?,
      shape: json['shape'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$DripperMasterToJson(DripperMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'material': instance.material,
      'shape': instance.shape,
      'imageUrl': instance.imageUrl,
    };

FilterMaster _$FilterMasterFromJson(Map<String, dynamic> json) => FilterMaster(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '-',
  material: json['material'] as String?,
  size: FilterMaster._parseString(json['size']),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$FilterMasterToJson(FilterMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'material': instance.material,
      'size': instance.size,
      'imageUrl': instance.imageUrl,
    };
