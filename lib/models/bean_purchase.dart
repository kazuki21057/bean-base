import 'package:json_annotation/json_annotation.dart';

part 'bean_purchase.g.dart';

/// 購入履歴 (T3-62、設計書`docs/bean_purchase_design.md`§2)。
/// 011の追加購入・012の初回購入登録のたびに1行追記される。
@JsonSerializable()
class BeanPurchase {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;

  /// `BeanMaster.id`。数字のみの値のため`_parseString`必須
  /// (Sheetsが数値セルに変換して返すとキャストエラーになる、T3-67と同型)。
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String beanId;

  @JsonKey(fromJson: _parseDate)
  final DateTime? purchasedAt;

  @JsonKey(fromJson: _parseDate)
  final DateTime? roastDate;

  @JsonKey(fromJson: _parseDouble)
  final double? quantityGrams;

  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String storeId;

  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String storeName;

  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String memo;

  @JsonKey(fromJson: _parseDate)
  final DateTime? createdAt;

  BeanPurchase({
    required this.id,
    required this.beanId,
    this.purchasedAt,
    this.roastDate,
    this.quantityGrams,
    this.storeId = '',
    this.storeName = '',
    this.memo = '',
    this.createdAt,
  });

  factory BeanPurchase.fromJson(Map<String, dynamic> json) =>
      _$BeanPurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$BeanPurchaseToJson(this);

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value.trim());
    }
    return null;
  }

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

  BeanPurchase copyWith({
    String? id,
    String? beanId,
    DateTime? purchasedAt,
    DateTime? roastDate,
    double? quantityGrams,
    String? storeId,
    String? storeName,
    String? memo,
    DateTime? createdAt,
  }) {
    return BeanPurchase(
      id: id ?? this.id,
      beanId: beanId ?? this.beanId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      roastDate: roastDate ?? this.roastDate,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
