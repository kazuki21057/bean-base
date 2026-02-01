import 'package:json_annotation/json_annotation.dart';

part 'method_master.g.dart';

@JsonSerializable()
class MethodMaster {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  @JsonKey(defaultValue: '')
  final String author;
  @JsonKey(defaultValue: 0.0)
  final double baseBeanWeight;
  @JsonKey(defaultValue: 0.0)
  final double baseWaterAmount;
  @JsonKey(defaultValue: 0.0)
  final double? temperature;
  final String? grindSize;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(defaultValue: '')
  final String recommendedEquipment;
  final String? sourceUrl;

  MethodMaster({
    required this.id,
    required this.name,
    required this.author,
    required this.baseBeanWeight,
    required this.baseWaterAmount,
    this.temperature,
    this.grindSize,
    required this.description,
    required this.recommendedEquipment,
    this.sourceUrl,
  });

  factory MethodMaster.fromJson(Map<String, dynamic> json) =>
      _$MethodMasterFromJson(json);

  Map<String, dynamic> toJson() => _$MethodMasterToJson(this);
}
