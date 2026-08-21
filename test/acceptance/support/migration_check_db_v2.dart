// T5-B12受け入れテスト用の最小限のv2スキーマ定義(v1に列を1つ追加)。
// `migration_check_db_v1.dart`のv1スキーマに対して、
// `addedNote`列を追加した状態からのマイグレーション(m.addColumn)を検証する。
import 'package:drift/drift.dart';

part 'migration_check_db_v2.g.dart';

class MigrationCheckTableV2 extends Table {
  @override
  String get tableName => 'migration_check';
  TextColumn get id => text()();
  TextColumn get label => text().withDefault(const Constant(''))();
  TextColumn get addedNote => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [MigrationCheckTableV2])
class MigrationCheckDbV2 extends _$MigrationCheckDbV2 {
  MigrationCheckDbV2(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (Migrator m, int from, int to) async {
          if (from == 1) {
            // make-migrationsが生成するstepByStepと同じ形の
            // `m.addColumn(...)`によるマイグレーション(設計書§8.2)。
            await m.addColumn(
              migrationCheckTableV2,
              migrationCheckTableV2.addedNote,
            );
          }
        },
      );
}
