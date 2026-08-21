// T5-B12受け入れテスト用の最小限のv1スキーマ定義。
// docs/local_db_schema_design.md §10-3の「意図的にschemaVersionを1バージョン
// 上げる」検証を、実アプリの`lib/db/tables.dart`とは別に行うための専用DB。
import 'package:drift/drift.dart';

part 'migration_check_db_v1.g.dart';

class MigrationCheckTableV1 extends Table {
  @override
  String get tableName => 'migration_check';
  TextColumn get id => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [MigrationCheckTableV1])
class MigrationCheckDbV1 extends _$MigrationCheckDbV1 {
  MigrationCheckDbV1(super.executor);

  @override
  int get schemaVersion => 1;
}
