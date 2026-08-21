// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_check_db_v1.dart';

// ignore_for_file: type=lint
class $MigrationCheckTableV1Table extends MigrationCheckTableV1
    with TableInfo<$MigrationCheckTableV1Table, MigrationCheckTableV1Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationCheckTableV1Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_check';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationCheckTableV1Data> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationCheckTableV1Data map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationCheckTableV1Data(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $MigrationCheckTableV1Table createAlias(String alias) {
    return $MigrationCheckTableV1Table(attachedDatabase, alias);
  }
}

class MigrationCheckTableV1Data extends DataClass
    implements Insertable<MigrationCheckTableV1Data> {
  final String id;
  final String label;
  const MigrationCheckTableV1Data({required this.id, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    return map;
  }

  MigrationCheckTableV1Companion toCompanion(bool nullToAbsent) {
    return MigrationCheckTableV1Companion(id: Value(id), label: Value(label));
  }

  factory MigrationCheckTableV1Data.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationCheckTableV1Data(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
    };
  }

  MigrationCheckTableV1Data copyWith({String? id, String? label}) =>
      MigrationCheckTableV1Data(id: id ?? this.id, label: label ?? this.label);
  MigrationCheckTableV1Data copyWithCompanion(
    MigrationCheckTableV1Companion data,
  ) {
    return MigrationCheckTableV1Data(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationCheckTableV1Data(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationCheckTableV1Data &&
          other.id == this.id &&
          other.label == this.label);
}

class MigrationCheckTableV1Companion
    extends UpdateCompanion<MigrationCheckTableV1Data> {
  final Value<String> id;
  final Value<String> label;
  final Value<int> rowid;
  const MigrationCheckTableV1Companion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationCheckTableV1Companion.insert({
    required String id,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MigrationCheckTableV1Data> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationCheckTableV1Companion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return MigrationCheckTableV1Companion(
      id: id ?? this.id,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationCheckTableV1Companion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MigrationCheckDbV1 extends GeneratedDatabase {
  _$MigrationCheckDbV1(QueryExecutor e) : super(e);
  $MigrationCheckDbV1Manager get managers => $MigrationCheckDbV1Manager(this);
  late final $MigrationCheckTableV1Table migrationCheckTableV1 =
      $MigrationCheckTableV1Table(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [migrationCheckTableV1];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MigrationCheckTableV1TableCreateCompanionBuilder =
    MigrationCheckTableV1Companion Function({
      required String id,
      Value<String> label,
      Value<int> rowid,
    });
typedef $$MigrationCheckTableV1TableUpdateCompanionBuilder =
    MigrationCheckTableV1Companion Function({
      Value<String> id,
      Value<String> label,
      Value<int> rowid,
    });

class $$MigrationCheckTableV1TableFilterComposer
    extends Composer<_$MigrationCheckDbV1, $MigrationCheckTableV1Table> {
  $$MigrationCheckTableV1TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationCheckTableV1TableOrderingComposer
    extends Composer<_$MigrationCheckDbV1, $MigrationCheckTableV1Table> {
  $$MigrationCheckTableV1TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationCheckTableV1TableAnnotationComposer
    extends Composer<_$MigrationCheckDbV1, $MigrationCheckTableV1Table> {
  $$MigrationCheckTableV1TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$MigrationCheckTableV1TableTableManager
    extends
        RootTableManager<
          _$MigrationCheckDbV1,
          $MigrationCheckTableV1Table,
          MigrationCheckTableV1Data,
          $$MigrationCheckTableV1TableFilterComposer,
          $$MigrationCheckTableV1TableOrderingComposer,
          $$MigrationCheckTableV1TableAnnotationComposer,
          $$MigrationCheckTableV1TableCreateCompanionBuilder,
          $$MigrationCheckTableV1TableUpdateCompanionBuilder,
          (
            MigrationCheckTableV1Data,
            BaseReferences<
              _$MigrationCheckDbV1,
              $MigrationCheckTableV1Table,
              MigrationCheckTableV1Data
            >,
          ),
          MigrationCheckTableV1Data,
          PrefetchHooks Function()
        > {
  $$MigrationCheckTableV1TableTableManager(
    _$MigrationCheckDbV1 db,
    $MigrationCheckTableV1Table table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationCheckTableV1TableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MigrationCheckTableV1TableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MigrationCheckTableV1TableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationCheckTableV1Companion(
                id: id,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationCheckTableV1Companion.insert(
                id: id,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationCheckTableV1TableProcessedTableManager =
    ProcessedTableManager<
      _$MigrationCheckDbV1,
      $MigrationCheckTableV1Table,
      MigrationCheckTableV1Data,
      $$MigrationCheckTableV1TableFilterComposer,
      $$MigrationCheckTableV1TableOrderingComposer,
      $$MigrationCheckTableV1TableAnnotationComposer,
      $$MigrationCheckTableV1TableCreateCompanionBuilder,
      $$MigrationCheckTableV1TableUpdateCompanionBuilder,
      (
        MigrationCheckTableV1Data,
        BaseReferences<
          _$MigrationCheckDbV1,
          $MigrationCheckTableV1Table,
          MigrationCheckTableV1Data
        >,
      ),
      MigrationCheckTableV1Data,
      PrefetchHooks Function()
    >;

class $MigrationCheckDbV1Manager {
  final _$MigrationCheckDbV1 _db;
  $MigrationCheckDbV1Manager(this._db);
  $$MigrationCheckTableV1TableTableManager get migrationCheckTableV1 =>
      $$MigrationCheckTableV1TableTableManager(_db, _db.migrationCheckTableV1);
}
