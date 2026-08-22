// ignore_for_file: always_use_package_imports
// drift行モデル(Row) ⇔ アプリのJSONモデル の相互変換をまとめる。
//
// 正本: docs/local_db_schema_design.md §7.4。
// 束1(T5-B13-1): mill_master・dripper_master・filter_master・origin_masterの4テーブル分。
// 束2(T5-B13-2): bean_master・store_master・bean_purchasesの3テーブル分。
// 束3(T5-B13-3): coffee_data・methods_master・pouring_stepsの3テーブル分。
// 束4(T5-B13-4、当バンドル): analysis_history・recipe_suggestionsの2テーブル分。
//
// 全列を明示的にValue(...)で埋める(Value.absent()は使わない。部分更新を作らず、
// update(t).replace(...)が全列上書きであることと整合させるため)。
import 'package:drift/drift.dart';

import 'local_database.dart';
import '../models/analysis_snapshot.dart';
import '../models/bean_master.dart';
import '../models/bean_purchase.dart';
import '../models/coffee_record.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/origin_master.dart';
import '../models/pouring_step.dart';
import '../models/recipe_suggestion.dart';
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

// --- coffee_data (CoffeeRecord) ---

extension CoffeeDataRowMapper on CoffeeDataRow {
  CoffeeRecord toModel() => CoffeeRecord(
        id: id,
        brewedAt: brewedAt,
        grinderId: grinderId,
        dripperId: dripperId,
        filterId: filterId,
        beanId: beanId,
        roastLevel: roastLevel,
        origin: origin,
        beanWeight: beanWeight,
        grindSize: grindSize,
        methodId: methodId,
        taste: taste,
        concentration: concentration,
        temperature: temperature,
        bloomingWater: bloomingWater,
        totalWater: totalWater,
        bloomingTime: bloomingTime,
        totalTime: totalTime,
        scoreFragrance: scoreFragrance,
        scoreAcidity: scoreAcidity,
        scoreBitterness: scoreBitterness,
        scoreSweetness: scoreSweetness,
        scoreComplexity: scoreComplexity,
        scoreFlavor: scoreFlavor,
        scoreOverall: scoreOverall,
        comment: comment,
        grinderImageUrl: grinderImageUrl,
        dripperImageUrl: dripperImageUrl,
        filterImageUrl: filterImageUrl,
        beanImageUrl: beanImageUrl,
        originId: originId,
      );
}

extension CoffeeRecordCompanionMapper on CoffeeRecord {
  /// `updated_at`はローカルDB専用のメタ列で`CoffeeRecord`に対応フィールドが無いため、
  /// 保存のたびに現在時刻で埋める(設計書§4.1「行の最終更新時刻」)。
  CoffeeDataTableCompanion toCompanion() => CoffeeDataTableCompanion(
        id: Value(id),
        brewedAt: Value(brewedAt),
        grinderId: Value(grinderId),
        dripperId: Value(dripperId),
        filterId: Value(filterId),
        beanId: Value(beanId),
        roastLevel: Value(roastLevel),
        origin: Value(origin),
        originId: Value(originId),
        beanWeight: Value(beanWeight),
        grindSize: Value(grindSize),
        methodId: Value(methodId),
        taste: Value(taste),
        concentration: Value(concentration),
        temperature: Value(temperature),
        bloomingWater: Value(bloomingWater),
        totalWater: Value(totalWater),
        bloomingTime: Value(bloomingTime),
        totalTime: Value(totalTime),
        scoreFragrance: Value(scoreFragrance),
        scoreAcidity: Value(scoreAcidity),
        scoreBitterness: Value(scoreBitterness),
        scoreSweetness: Value(scoreSweetness),
        scoreComplexity: Value(scoreComplexity),
        scoreFlavor: Value(scoreFlavor),
        scoreOverall: Value(scoreOverall),
        comment: Value(comment),
        grinderImageUrl: Value(grinderImageUrl),
        dripperImageUrl: Value(dripperImageUrl),
        filterImageUrl: Value(filterImageUrl),
        beanImageUrl: Value(beanImageUrl),
        updatedAt: Value(DateTime.now()),
      );
}

// --- methods_master (MethodMaster) ---

extension MethodsMasterRowMapper on MethodsMasterRow {
  MethodMaster toModel() => MethodMaster(
        id: id,
        name: name,
        author: author,
        baseBeanWeight: baseBeanWeight,
        baseWaterAmount: baseWaterAmount,
        temperature: temperature,
        grindSize: grindSize,
        description: description,
        recommendedEquipment: recommendedEquipment,
        sourceUrl: sourceUrl,
        recommendedRoastLevel: recommendedRoastLevel,
        recommendedRoastMin: recommendedRoastMin,
        recommendedRoastMax: recommendedRoastMax,
      );
}

extension MethodMasterCompanionMapper on MethodMaster {
  MethodsMasterTableCompanion toCompanion() => MethodsMasterTableCompanion(
        id: Value(id),
        name: Value(name),
        author: Value(author),
        baseBeanWeight: Value(baseBeanWeight),
        baseWaterAmount: Value(baseWaterAmount),
        temperature: Value(temperature),
        grindSize: Value(grindSize),
        description: Value(description),
        recommendedEquipment: Value(recommendedEquipment),
        sourceUrl: Value(sourceUrl),
        recommendedRoastLevel: Value(recommendedRoastLevel),
        recommendedRoastMin: Value(recommendedRoastMin),
        recommendedRoastMax: Value(recommendedRoastMax),
      );
}

// --- pouring_steps (PouringStep) ---

extension PouringStepRowMapper on PouringStepRow {
  PouringStep toModel() => PouringStep(
        id: id,
        methodId: methodId,
        stepOrder: stepOrder,
        duration: duration,
        waterAmount: waterAmount,
        waterReference: waterReference,
        waterRatio: waterRatio,
        description: description,
      );
}

extension PouringStepCompanionMapper on PouringStep {
  PouringStepsTableCompanion toCompanion() => PouringStepsTableCompanion(
        id: Value(id),
        methodId: Value(methodId),
        stepOrder: Value(stepOrder),
        duration: Value(duration),
        waterAmount: Value(waterAmount),
        waterReference: Value(waterReference),
        waterRatio: Value(waterRatio),
        description: Value(description),
      );
}

// --- analysis_history (AnalysisSnapshot) ---

extension AnalysisHistoryRowMapper on AnalysisHistoryRow {
  AnalysisSnapshot toModel() => AnalysisSnapshot(
        id: id,
        createdAt: createdAt,
        type: type,
        dataCount: dataCount,
        payloadJson: payloadJson,
      );
}

extension AnalysisSnapshotCompanionMapper on AnalysisSnapshot {
  AnalysisHistoryTableCompanion toCompanion() => AnalysisHistoryTableCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        type: Value(type),
        dataCount: Value(dataCount),
        payloadJson: Value(payloadJson),
      );
}

// --- recipe_suggestions (RecipeSuggestion) ---

extension RecipeSuggestionRowMapper on RecipeSuggestionRow {
  RecipeSuggestion toModel() => RecipeSuggestion(
        id: id,
        createdAt: createdAt,
        beanId: beanId,
        originId: originId,
        roastLevel: roastLevel,
        methodId: methodId,
        temperature: temperature,
        brewRatio: brewRatio,
        totalTimeSec: totalTimeSec,
        rationale: rationale,
        accepted: accepted,
        resultRecordId: resultRecordId,
      );
}

extension RecipeSuggestionCompanionMapper on RecipeSuggestion {
  RecipeSuggestionsTableCompanion toCompanion() =>
      RecipeSuggestionsTableCompanion(
        id: Value(id),
        createdAt: Value(createdAt),
        beanId: Value(beanId),
        originId: Value(originId),
        roastLevel: Value(roastLevel),
        methodId: Value(methodId),
        temperature: Value(temperature),
        brewRatio: Value(brewRatio),
        totalTimeSec: Value(totalTimeSec),
        rationale: Value(rationale),
        accepted: Value(accepted),
        resultRecordId: Value(resultRecordId),
      );
}
