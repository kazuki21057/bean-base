import 'package:json_annotation/json_annotation.dart';

part 'coffee_record.g.dart';

@JsonSerializable()
class CoffeeRecord {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(name: 'brewedAt', fromJson: _parseDateTime)
  final DateTime brewedAt;
  @JsonKey(defaultValue: '')
  final String grinderId;
  @JsonKey(defaultValue: '')
  final String dripperId;
  @JsonKey(defaultValue: '')
  final String filterId;
  @JsonKey(defaultValue: '')
  final String beanId;
  @JsonKey(defaultValue: '')
  final String roastLevel;
  @JsonKey(defaultValue: '')
  final String origin;
  @JsonKey(fromJson: _parseDouble)
  final double beanWeight;
  @JsonKey(fromJson: _parseString)
  final String grindSize;
  @JsonKey(fromJson: _parseString)
  final String methodId;
  @JsonKey(fromJson: _parseString)
  final String taste;
  @JsonKey(fromJson: _parseString)
  final String concentration;
  @JsonKey(fromJson: _parseDouble)
  final double temperature;
  @JsonKey(fromJson: _parseDouble)
  final double bloomingWater;
  @JsonKey(fromJson: _parseDouble)
  final double totalWater;
  @JsonKey(fromJson: _parseInt)
  final int bloomingTime;
  @JsonKey(fromJson: _parseInt)
  final int totalTime;
  @JsonKey(fromJson: _parseInt)
  final int scoreFragrance;
  @JsonKey(fromJson: _parseInt)
  final int scoreAcidity;
  @JsonKey(fromJson: _parseInt)
  final int scoreBitterness;
  @JsonKey(fromJson: _parseInt)
  final int scoreSweetness;
  @JsonKey(fromJson: _parseInt)
  final int scoreComplexity;
  @JsonKey(fromJson: _parseInt)
  final int scoreFlavor;
  @JsonKey(fromJson: _parseInt)
  final int scoreOverall;
  @JsonKey(defaultValue: '')
  final String comment;
  final String? grinderImageUrl;
  final String? dripperImageUrl;
  final String? filterImageUrl;
  final String? beanImageUrl;

  CoffeeRecord({
    required this.id,
    required this.brewedAt,
    required this.grinderId,
    required this.dripperId,
    required this.filterId,
    required this.beanId,
    required this.roastLevel,
    required this.origin,
    required this.beanWeight,
    required this.grindSize,
    required this.methodId,
    required this.taste,
    required this.concentration,
    required this.temperature,
    required this.bloomingWater,
    required this.totalWater,
    required this.bloomingTime,
    required this.totalTime,
    required this.scoreFragrance,
    required this.scoreAcidity,
    required this.scoreBitterness,
    required this.scoreSweetness,
    required this.scoreComplexity,
    required this.scoreFlavor,
    required this.scoreOverall,
    required this.comment,
    this.grinderImageUrl,
    this.dripperImageUrl,
    this.filterImageUrl,
    this.beanImageUrl,
  });

  factory CoffeeRecord.fromJson(Map<String, dynamic> json) =>
      _$CoffeeRecordFromJson(json);

  Map<String, dynamic> toJson() => _$CoffeeRecordToJson(this);

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      if (value.trim().isEmpty) return DateTime.now();
      try {
        String formatted = value.replaceAll('/', '-');
        
        // Split date and time
        List<String> parts = formatted.split(RegExp(r'[ T]'));
        if (parts.isNotEmpty) {
           // Fix Date Part
           List<String> dateParts = parts[0].split('-');
           if (dateParts.length == 3) {
             String y = dateParts[0];
             String m = dateParts[1].padLeft(2, '0');
             String d = dateParts[2].padLeft(2, '0');
             parts[0] = '$y-$m-$d';
           }
        }
        
        if (parts.length > 1) {
           // Fix Time Part
           List<String> timeParts = parts[1].split(':');
           for(int i=0; i<timeParts.length; i++) {
              timeParts[i] = timeParts[i].padLeft(2, '0');
           }
           if (timeParts.length == 2) {
              timeParts.add('00');
           }
           parts[1] = timeParts.join(':');
        }
        
        formatted = parts.join('T');
        return DateTime.parse(formatted);
      } catch (e) {
        // Fallback or custom parsing
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return 0.0;
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.trim().isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num) return value.toString();
    return value.toString();
  }
}
