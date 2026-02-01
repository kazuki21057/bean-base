import 'package:json_annotation/json_annotation.dart';

part 'equipment_masters.g.dart';

@JsonSerializable()
class GrinderMaster {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  final String? grindRange; // description of range
  final String? description;
  final String? imageUrl;

  GrinderMaster({
    required this.id,
    required this.name,
    this.grindRange,
    this.description,
    this.imageUrl,
  });

  factory GrinderMaster.fromJson(Map<String, dynamic> json) =>
      _$GrinderMasterFromJson(json);

  Map<String, dynamic> toJson() => _$GrinderMasterToJson(this);
}

@JsonSerializable()
class DripperMaster {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  final String? material;
  final String? shape;
  final String? imageUrl;

  DripperMaster({
    required this.id,
    required this.name,
    this.material,
    this.shape,
    this.imageUrl,
  });

  factory DripperMaster.fromJson(Map<String, dynamic> json) =>
      _$DripperMasterFromJson(json);

  Map<String, dynamic> toJson() => _$DripperMasterToJson(this);
}

@JsonSerializable()
class FilterMaster {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  final String? material;
  @JsonKey(fromJson: _parseString)
  final String? size;
  final String? imageUrl;

  FilterMaster({
    required this.id,
    required this.name,
    this.material,
    this.size,
    this.imageUrl,
  });

  factory FilterMaster.fromJson(Map<String, dynamic> json) =>
      _$FilterMasterFromJson(json);

  Map<String, dynamic> toJson() => _$FilterMasterToJson(this);

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
