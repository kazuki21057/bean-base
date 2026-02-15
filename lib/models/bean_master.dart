import 'package:json_annotation/json_annotation.dart';

part 'bean_master.g.dart';

@JsonSerializable()
class BeanMaster {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  @JsonKey(defaultValue: '')
  final String roastLevel;
  @JsonKey(defaultValue: '')
  final String origin;
  @JsonKey(defaultValue: '')
  final String store;
  @JsonKey(defaultValue: '')
  final String type;
  final String? imageUrl;

  @JsonKey(fromJson: _parseDate)
  final DateTime? purchaseDate;
  @JsonKey(fromJson: _parseDate)
  final DateTime? firstUseDate;
  @JsonKey(fromJson: _parseDate)
  final DateTime? lastUseDate;
  @JsonKey(fromJson: _parseBool, defaultValue: false)
  final bool isInStock;

  BeanMaster({
    required this.id,
    required this.name,
    required this.roastLevel,
    required this.origin,
    this.store = '',
    this.type = '',
    this.imageUrl,
    this.purchaseDate,
    this.firstUseDate,
    this.lastUseDate,
    this.isInStock = false,
  });

  factory BeanMaster.fromJson(Map<String, dynamic> json) =>
      _$BeanMasterFromJson(json);

  Map<String, dynamic> toJson() => _$BeanMasterToJson(this);

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try {
        String formatted = value.replaceAll('/', '-');
        if (formatted.contains(' ')) formatted = formatted.replaceAll(' ', 'T');
        if (formatted.split(':').length == 2) formatted += ':00';
        return DateTime.parse(formatted);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == 'yes' || v == '1';
    }
    return false;
  }
  BeanMaster copyWith({
    String? id,
    String? name,
    String? roastLevel,
    String? origin,
    String? store,
    String? type,
    String? imageUrl,
    DateTime? purchaseDate,
    DateTime? firstUseDate,
    DateTime? lastUseDate,
    bool? isInStock,
  }) {
    return BeanMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      roastLevel: roastLevel ?? this.roastLevel,
      origin: origin ?? this.origin,
      store: store ?? this.store,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      firstUseDate: firstUseDate ?? this.firstUseDate,
      lastUseDate: lastUseDate ?? this.lastUseDate,
      isInStock: isInStock ?? this.isInStock,
    );
  }
}
