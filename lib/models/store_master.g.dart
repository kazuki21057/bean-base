// GENERATED CODE - DO NOT MODIFY BY HAND
// (T3-67: build_runnerがこのマシンで不安定なため手書き。T3-34/origin_masterと同じ運用)

part of 'store_master.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreMaster _$StoreMasterFromJson(Map<String, dynamic> json) => StoreMaster(
  id: json['id'] == null ? '' : StoreMaster._parseString(json['id']),
  name: json['name'] as String? ?? '-',
  formalName: json['formalName'] as String? ?? '',
  url: json['url'] as String? ?? '',
  prefecture: json['prefecture'] as String? ?? '',
  address: json['address'] as String? ?? '',
  hasOnlineShop: json['hasOnlineShop'] == null
      ? false
      : StoreMaster._parseBool(json['hasOnlineShop']),
  hasPhysicalStore: json['hasPhysicalStore'] == null
      ? false
      : StoreMaster._parseBool(json['hasPhysicalStore']),
  hasRoastery: json['hasRoastery'] == null
      ? false
      : StoreMaster._parseBool(json['hasRoastery']),
  beanTendency: json['beanTendency'] as String? ?? '',
  memo: json['memo'] as String? ?? '',
  imageUrl: json['imageUrl'] as String?,
  snsUrl: json['snsUrl'] as String? ?? '',
  businessHours: json['businessHours'] as String? ?? '',
  closedDays: json['closedDays'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  openedYear: json['openedYear'] == null
      ? ''
      : StoreMaster._parseString(json['openedYear']),
  sourceUrl: json['sourceUrl'] as String? ?? '',
  infoFetchedAt: StoreMaster._parseDate(json['infoFetchedAt']),
);

Map<String, dynamic> _$StoreMasterToJson(StoreMaster instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'formalName': instance.formalName,
      'url': instance.url,
      'prefecture': instance.prefecture,
      'address': instance.address,
      'hasOnlineShop': instance.hasOnlineShop,
      'hasPhysicalStore': instance.hasPhysicalStore,
      'hasRoastery': instance.hasRoastery,
      'beanTendency': instance.beanTendency,
      'memo': instance.memo,
      'imageUrl': instance.imageUrl,
      'snsUrl': instance.snsUrl,
      'businessHours': instance.businessHours,
      'closedDays': instance.closedDays,
      'phone': instance.phone,
      'openedYear': instance.openedYear,
      'sourceUrl': instance.sourceUrl,
      'infoFetchedAt': instance.infoFetchedAt?.toIso8601String(),
    };
