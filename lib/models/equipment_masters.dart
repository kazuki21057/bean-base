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

  GrinderMaster copyWith({
    String? id,
    String? name,
    String? grindRange,
    String? description,
    String? imageUrl,
  }) {
    return GrinderMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      grindRange: grindRange ?? this.grindRange,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
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

  DripperMaster copyWith({
    String? id,
    String? name,
    String? material,
    String? shape,
    String? imageUrl,
  }) {
    return DripperMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      shape: shape ?? this.shape,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
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

  FilterMaster copyWith({
    String? id,
    String? name,
    String? material,
    String? size,
    String? imageUrl,
  }) {
    return FilterMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }
}
