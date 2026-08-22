// ignore_for_file: always_use_package_imports
// LocalDatabaseのDIプロバイダ。
//
// 正本: docs/local_db_schema_design.md §7.5.1-4。
// dataServiceProvider(束4で配線)がこれをref.watchし、
// LocalDbService(ref.watch(localDatabaseProvider))を返す。
// インスタンスはアプリ全体で1つ(driftは同一ファイルの多重オープンで警告を出すため)。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/local_database.dart';

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(db.close);
  return db;
});
