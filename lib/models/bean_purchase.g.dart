// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bean_purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeanPurchase _$BeanPurchaseFromJson(Map<String, dynamic> json) => BeanPurchase(
  id: json['id'] == null ? '' : BeanPurchase._parseString(json['id']),
  beanId: json['beanId'] == null
      ? ''
      : BeanPurchase._parseString(json['beanId']),
  purchasedAt: BeanPurchase._parseDate(json['purchasedAt']),
  roastDate: BeanPurchase._parseDate(json['roastDate']),
  quantityGrams: BeanPurchase._parseDouble(json['quantityGrams']),
  storeId: json['storeId'] == null
      ? ''
      : BeanPurchase._parseString(json['storeId']),
  storeName: json['storeName'] == null
      ? ''
      : BeanPurchase._parseString(json['storeName']),
  memo: json['memo'] == null ? '' : BeanPurchase._parseString(json['memo']),
  createdAt: BeanPurchase._parseDate(json['createdAt']),
);

Map<String, dynamic> _$BeanPurchaseToJson(BeanPurchase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'beanId': instance.beanId,
      'purchasedAt': instance.purchasedAt?.toIso8601String(),
      'roastDate': instance.roastDate?.toIso8601String(),
      'quantityGrams': instance.quantityGrams,
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'memo': instance.memo,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
