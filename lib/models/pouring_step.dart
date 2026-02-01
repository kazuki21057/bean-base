import 'package:json_annotation/json_annotation.dart';

part 'pouring_step.g.dart';

@JsonSerializable()
class PouringStep {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String methodId;
  @JsonKey(defaultValue: 0)
  final int stepOrder;
  @JsonKey(defaultValue: 0)
  final int duration;
  @JsonKey(defaultValue: 0.0)
  final double waterAmount;
  @JsonKey(defaultValue: 0.0)
  final double waterReference;
  final double? waterRatio;
  @JsonKey(defaultValue: '')
  final String description;

  PouringStep({
    required this.id,
    required this.methodId,
    required this.stepOrder,
    required this.duration,
    required this.waterAmount,
    required this.waterReference,
    this.waterRatio,
    required this.description,
  });

  factory PouringStep.fromJson(Map<String, dynamic> json) =>
      _$PouringStepFromJson(json);

  Map<String, dynamic> toJson() => _$PouringStepToJson(this);
}
