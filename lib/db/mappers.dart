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
import '../models/equipment_masters.dart';
import '../models/origin_master.dart';

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
