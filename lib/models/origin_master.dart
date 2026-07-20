import 'package:json_annotation/json_annotation.dart';

part 'origin_master.g.dart';

/// 産地マスタ (T4-1a、設計書§3.1)。
@JsonSerializable()
class OriginMaster {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;
  @JsonKey(defaultValue: '')
  final String countryCode;
  @JsonKey(defaultValue: '')
  final String nameJa;
  @JsonKey(defaultValue: '')
  final String nameEn;
  @JsonKey(defaultValue: '')
  final String region;

  OriginMaster({
    required this.id,
    required this.countryCode,
    required this.nameJa,
    required this.nameEn,
    required this.region,
  });

  factory OriginMaster.fromJson(Map<String, dynamic> json) =>
      _$OriginMasterFromJson(json);

  Map<String, dynamic> toJson() => _$OriginMasterToJson(this);

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  OriginMaster copyWith({
    String? id,
    String? countryCode,
    String? nameJa,
    String? nameEn,
    String? region,
  }) {
    return OriginMaster(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      nameJa: nameJa ?? this.nameJa,
      nameEn: nameEn ?? this.nameEn,
      region: region ?? this.region,
    );
  }
}

/// 初期投入データ15件 (設計書§3.1)。
///
/// **投入方針(T4-1a決定事項)**: GAS(gas/Code.gs)の`ensureSheet_`はヘッダー行のみ
/// を生成しデータ行は投入しないため、この初期データは`clasp login`実施後に
/// `tools/seed_origin_masters.dart`(このリストを`SheetsService.saveOriginMaster`
/// で1件ずつPOSTする一度きりのスクリプト)を実行して投入する運用とする。
/// IDは固定値`origin_1`〜`origin_15`とする(設計書の`'origin_'+タイムスタンプ`規約は
/// ユーザーが設定画面から追加する新規産地向け。初期データは固定・再現可能な値が
/// 適切なため、タイムスタンプの代わりに連番を採用)。
final List<OriginMaster> kInitialOriginMasters = [
  OriginMaster(id: 'origin_1', countryCode: 'ET', nameJa: 'エチオピア', nameEn: 'Ethiopia', region: 'アフリカ'),
  OriginMaster(id: 'origin_2', countryCode: 'KE', nameJa: 'ケニア', nameEn: 'Kenya', region: 'アフリカ'),
  OriginMaster(id: 'origin_3', countryCode: 'TZ', nameJa: 'タンザニア', nameEn: 'Tanzania', region: 'アフリカ'),
  OriginMaster(id: 'origin_4', countryCode: 'RW', nameJa: 'ルワンダ', nameEn: 'Rwanda', region: 'アフリカ'),
  OriginMaster(id: 'origin_5', countryCode: 'BR', nameJa: 'ブラジル', nameEn: 'Brazil', region: '中南米'),
  OriginMaster(id: 'origin_6', countryCode: 'CO', nameJa: 'コロンビア', nameEn: 'Colombia', region: '中南米'),
  OriginMaster(id: 'origin_7', countryCode: 'GT', nameJa: 'グアテマラ', nameEn: 'Guatemala', region: '中南米'),
  OriginMaster(id: 'origin_8', countryCode: 'CR', nameJa: 'コスタリカ', nameEn: 'Costa Rica', region: '中南米'),
  OriginMaster(id: 'origin_9', countryCode: 'HN', nameJa: 'ホンジュラス', nameEn: 'Honduras', region: '中南米'),
  OriginMaster(id: 'origin_10', countryCode: 'PE', nameJa: 'ペルー', nameEn: 'Peru', region: '中南米'),
  OriginMaster(id: 'origin_11', countryCode: 'ID', nameJa: 'インドネシア', nameEn: 'Indonesia', region: 'アジア・太平洋'),
  OriginMaster(id: 'origin_12', countryCode: 'VN', nameJa: 'ベトナム', nameEn: 'Vietnam', region: 'アジア・太平洋'),
  OriginMaster(id: 'origin_13', countryCode: 'IN', nameJa: 'インド', nameEn: 'India', region: 'アジア・太平洋'),
  OriginMaster(id: 'origin_14', countryCode: 'YE', nameJa: 'イエメン', nameEn: 'Yemen', region: 'その他'),
  OriginMaster(id: 'origin_15', countryCode: 'XX', nameJa: 'ブレンド', nameEn: 'Blend', region: 'その他'),
];
