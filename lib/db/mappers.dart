// ignore_for_file: always_use_package_imports
// drift行モデル(Row) ⇔ アプリのJSONモデル の相互変換をまとめる。
//
// 正本: docs/local_db_schema_design.md §7.4。
// 束1(T5-B13-1): mill_master・dripper_master・filter_master・origin_masterの4テーブル分。
// 束2〜4がテーブル分のextensionを追記していく(このファイル自体は束1で新規作成)。
//
// 全列を明示的にValue(...)で埋める(Value.absent()は使わない。部分更新を作らず、
// update(t).replace(...)が全列上書きであることと整合させるため)。
import 'package:drift/drift.dart';

import 'local_database.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../models/equipment_masters.dart';
import '../models/origin_master.dart';
import '../models/store_master.dart';

// --- mill_master (GrinderMaster) ---

extension MillMasterRowMapper on MillMasterRow {
  GrinderMaster toModel() => GrinderMaster(
        id: id,
        name: name,
        grindRange: grindRange,
        description: description,
        imageUrl: imageUrl,
      );
}

extension GrinderMasterCompanionMapper on GrinderMaster {
  MillMasterTableCompanion toCompanion() => MillMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        grindRange: Value(grindRange),
        description: Value(description),
        imageUrl: Value(imageUrl),
      );
}

// --- dripper_master (DripperMaster) ---

extension DripperMasterRowMapper on DripperMasterRow {
  DripperMaster toModel() => DripperMaster(
        id: id,
        name: name,
        material: material,
        shape: shape,
        imageUrl: imageUrl,
      );
}

extension DripperMasterCompanionMapper on DripperMaster {
  DripperMasterTableCompanion toCompanion() => DripperMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        material: Value(material),
        shape: Value(shape),
        imageUrl: Value(imageUrl),
      );
}

// --- filter_master (FilterMaster) ---

extension FilterMasterRowMapper on FilterMasterRow {
  FilterMaster toModel() => FilterMaster(
        id: id,
        name: name,
        material: material,
        size: size,
        imageUrl: imageUrl,
      );
}

extension FilterMasterCompanionMapper on FilterMaster {
  FilterMasterTableCompanion toCompanion() => FilterMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        material: Value(material),
        size: Value(size),
        imageUrl: Value(imageUrl),
      );
}

// --- origin_master (OriginMaster) ---

extension OriginMasterRowMapper on OriginMasterRow {
  OriginMaster toModel() => OriginMaster(
        id: id,
        countryCode: countryCode,
        nameJa: nameJa,
        nameEn: nameEn,
        region: region,
      );
}

extension OriginMasterCompanionMapper on OriginMaster {
  OriginMasterTableCompanion toCompanion() => OriginMasterTableCompanion(
        id: Value(id),
        countryCode: Value(countryCode),
        nameJa: Value(nameJa),
        nameEn: Value(nameEn),
        region: Value(region),
      );
}

// --- bean_master (BeanMaster) ---

extension BeanMasterRowMapper on BeanMasterRow {
  BeanMaster toModel() => BeanMaster(
        id: id,
        name: name,
        roastLevel: roastLevel,
        origin: origin,
        store: store,
        type: type,
        imageUrl: imageUrl,
        beanImageUrl: beanImageUrl,
        infoImageUrl: infoImageUrl,
        purchaseDate: purchaseDate,
        firstUseDate: firstUseDate,
        lastUseDate: lastUseDate,
        isInStock: isInStock,
        initialQuantityGrams: initialQuantityGrams,
        originId: originId,
        roastDate: roastDate,
        stockBaselineGrams: stockBaselineGrams,
        stockBaselineAt: stockBaselineAt,
        storageLocation: storageLocation,
        seekOptimalConditions: seekOptimalConditions,
        storeId: storeId,
      );
}

extension BeanMasterCompanionMapper on BeanMaster {
  BeanMasterTableCompanion toCompanion() => BeanMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        roastLevel: Value(roastLevel),
        origin: Value(origin),
        store: Value(store),
        type: Value(type),
        imageUrl: Value(imageUrl),
        beanImageUrl: Value(beanImageUrl),
        infoImageUrl: Value(infoImageUrl),
        purchaseDate: Value(purchaseDate),
        firstUseDate: Value(firstUseDate),
        lastUseDate: Value(lastUseDate),
        isInStock: Value(isInStock),
        initialQuantityGrams: Value(initialQuantityGrams),
        originId: Value(originId),
        roastDate: Value(roastDate),
        stockBaselineGrams: Value(stockBaselineGrams),
        stockBaselineAt: Value(stockBaselineAt),
        storageLocation: Value(storageLocation),
        seekOptimalConditions: Value(seekOptimalConditions),
        storeId: Value(storeId),
      );
}

// --- store_master (StoreMaster) ---

extension StoreMasterRowMapper on StoreMasterRow {
  StoreMaster toModel() => StoreMaster(
        id: id,
        name: name,
        formalName: formalName,
        url: url,
        prefecture: prefecture,
        address: address,
        hasOnlineShop: hasOnlineShop,
        hasPhysicalStore: hasPhysicalStore,
        hasRoastery: hasRoastery,
        beanTendency: beanTendency,
        memo: memo,
        imageUrl: imageUrl,
        snsUrl: snsUrl,
        businessHours: businessHours,
        closedDays: closedDays,
        phone: phone,
        openedYear: openedYear,
        sourceUrl: sourceUrl,
        infoFetchedAt: infoFetchedAt,
      );
}

extension StoreMasterCompanionMapper on StoreMaster {
  StoreMasterTableCompanion toCompanion() => StoreMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        formalName: Value(formalName),
        url: Value(url),
        prefecture: Value(prefecture),
        address: Value(address),
        hasOnlineShop: Value(hasOnlineShop),
        hasPhysicalStore: Value(hasPhysicalStore),
        hasRoastery: Value(hasRoastery),
        beanTendency: Value(beanTendency),
        memo: Value(memo),
        imageUrl: Value(imageUrl),
        snsUrl: Value(snsUrl),
        businessHours: Value(businessHours),
        closedDays: Value(closedDays),
        phone: Value(phone),
        openedYear: Value(openedYear),
        sourceUrl: Value(sourceUrl),
        infoFetchedAt: Value(infoFetchedAt),
      );
}

// --- bean_purchases (BeanPurchase) ---

extension BeanPurchaseRowMapper on BeanPurchaseRow {
  BeanPurchase toModel() => BeanPurchase(
        id: id,
        beanId: beanId,
        purchasedAt: purchasedAt,
        roastDate: roastDate,
        quantityGrams: quantityGrams,
        storeId: storeId,
        storeName: storeName,
        memo: memo,
        createdAt: createdAt,
      );
}

extension BeanPurchaseCompanionMapper on BeanPurchase {
  BeanPurchasesTableCompanion toCompanion() => BeanPurchasesTableCompanion(
        id: Value(id),
        beanId: Value(beanId),
        purchasedAt: Value(purchasedAt),
        roastDate: Value(roastDate),
        quantityGrams: Value(quantityGrams),
        storeId: Value(storeId),
        storeName: Value(storeName),
        memo: Value(memo),
        createdAt: Value(createdAt),
      );
}
