// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration_check_db_v2.dart';

// ignore_for_file: type=lint
class $MigrationCheckTableV2Table extends MigrationCheckTableV2
    with TableInfo<$MigrationCheckTableV2Table, MigrationCheckTableV2Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationCheckTableV2Table(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _addedNoteMeta = const VerificationMeta(
    'addedNote',
  );
  @override
  late final GeneratedColumn<String> addedNote = GeneratedColumn<String>(
    'added_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, label, addedNote];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_check';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationCheckTableV2Data> instance, {
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
    if (data.containsKey('added_note')) {
      context.handle(
        _addedNoteMeta,
        addedNote.isAcceptableOrUnknown(data['added_note']!, _addedNoteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MigrationCheckTableV2Data map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationCheckTableV2Data(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      addedNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_note'],
      ),
    );
  }

  @override
  $MigrationCheckTableV2Table createAlias(String alias) {
    return $MigrationCheckTableV2Table(attachedDatabase, alias);
  }
}

class MigrationCheckTableV2Data extends DataClass
    implements Insertable<MigrationCheckTableV2Data> {
  final String id;
  final String label;
  final String? addedNote;
  const MigrationCheckTableV2Data({
    required this.id,
    required this.label,
    this.addedNote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || addedNote != null) {
      map['added_note'] = Variable<String>(addedNote);
    }
    return map;
  }

  MigrationCheckTableV2Companion toCompanion(bool nullToAbsent) {
    return MigrationCheckTableV2Companion(
      id: Value(id),
      label: Value(label),
      addedNote: addedNote == null && nullToAbsent
          ? const Value.absent()
          : Value(addedNote),
    );
  }

  factory MigrationCheckTableV2Data.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationCheckTableV2Data(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      addedNote: serializer.fromJson<String?>(json['addedNote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'addedNote': serializer.toJson<String?>(addedNote),
    };
  }

  MigrationCheckTableV2Data copyWith({
    String? id,
    String? label,
    Value<String?> addedNote = const Value.absent(),
  }) => MigrationCheckTableV2Data(
    id: id ?? this.id,
    label: label ?? this.label,
    addedNote: addedNote.present ? addedNote.value : this.addedNote,
  );
  MigrationCheckTableV2Data copyWithCompanion(
    MigrationCheckTableV2Companion data,
  ) {
    return MigrationCheckTableV2Data(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      addedNote: data.addedNote.present ? data.addedNote.value : this.addedNote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationCheckTableV2Data(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('addedNote: $addedNote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, addedNote);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationCheckTableV2Data &&
          other.id == this.id &&
          other.label == this.label &&
          other.addedNote == this.addedNote);
}

class MigrationCheckTableV2Companion
    extends UpdateCompanion<MigrationCheckTableV2Data> {
  final Value<String> id;
  final Value<String> label;
  final Value<String?> addedNote;
  final Value<int> rowid;
  const MigrationCheckTableV2Companion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.addedNote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationCheckTableV2Companion.insert({
    required String id,
    this.label = const Value.absent(),
    this.addedNote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MigrationCheckTableV2Data> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? addedNote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (addedNote != null) 'added_note': addedNote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationCheckTableV2Companion copyWith({
    Value<String>? id,
    Value<String>? label,
    Value<String?>? addedNote,
    Value<int>? rowid,
  }) {
    return MigrationCheckTableV2Companion(
      id: id ?? this.id,
      label: label ?? this.label,
      addedNote: addedNote ?? this.addedNote,
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
    if (addedNote.present) {
      map['added_note'] = Variable<String>(addedNote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationCheckTableV2Companion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('addedNote: $addedNote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MigrationCheckDbV2 extends GeneratedDatabase {
  _$MigrationCheckDbV2(QueryExecutor e) : super(e);
  $MigrationCheckDbV2Manager get managers => $MigrationCheckDbV2Manager(this);
  late final $MigrationCheckTableV2Table migrationCheckTableV2 =
      $MigrationCheckTableV2Table(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [migrationCheckTableV2];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MigrationCheckTableV2TableCreateCompanionBuilder =
    MigrationCheckTableV2Companion Function({
      required String id,
      Value<String> label,
      Value<String?> addedNote,
      Value<int> rowid,
    });
typedef $$MigrationCheckTableV2TableUpdateCompanionBuilder =
    MigrationCheckTableV2Companion Function({
      Value<String> id,
      Value<String> label,
      Value<String?> addedNote,
      Value<int> rowid,
    });

class $$MigrationCheckTableV2TableFilterComposer
    extends Composer<_$MigrationCheckDbV2, $MigrationCheckTableV2Table> {
  $$MigrationCheckTableV2TableFilterComposer({
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

  ColumnFilters<String> get addedNote => $composableBuilder(
    column: $table.addedNote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationCheckTableV2TableOrderingComposer
    extends Composer<_$MigrationCheckDbV2, $MigrationCheckTableV2Table> {
  $$MigrationCheckTableV2TableOrderingComposer({
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

  ColumnOrderings<String> get addedNote => $composableBuilder(
    column: $table.addedNote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationCheckTableV2TableAnnotationComposer
    extends Composer<_$MigrationCheckDbV2, $MigrationCheckTableV2Table> {
  $$MigrationCheckTableV2TableAnnotationComposer({
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

  GeneratedColumn<String> get addedNote =>
      $composableBuilder(column: $table.addedNote, builder: (column) => column);
}

class $$MigrationCheckTableV2TableTableManager
    extends
        RootTableManager<
          _$MigrationCheckDbV2,
          $MigrationCheckTableV2Table,
          MigrationCheckTableV2Data,
          $$MigrationCheckTableV2TableFilterComposer,
          $$MigrationCheckTableV2TableOrderingComposer,
          $$MigrationCheckTableV2TableAnnotationComposer,
          $$MigrationCheckTableV2TableCreateCompanionBuilder,
          $$MigrationCheckTableV2TableUpdateCompanionBuilder,
          (
            MigrationCheckTableV2Data,
            BaseReferences<
              _$MigrationCheckDbV2,
              $MigrationCheckTableV2Table,
              MigrationCheckTableV2Data
            >,
          ),
          MigrationCheckTableV2Data,
          PrefetchHooks Function()
        > {
  $$MigrationCheckTableV2TableTableManager(
    _$MigrationCheckDbV2 db,
    $MigrationCheckTableV2Table table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationCheckTableV2TableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MigrationCheckTableV2TableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MigrationCheckTableV2TableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> addedNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationCheckTableV2Companion(
                id: id,
                label: label,
                addedNote: addedNote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> label = const Value.absent(),
                Value<String?> addedNote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationCheckTableV2Companion.insert(
                id: id,
                label: label,
                addedNote: addedNote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationCheckTableV2TableProcessedTableManager =
    ProcessedTableManager<
      _$MigrationCheckDbV2,
      $MigrationCheckTableV2Table,
      MigrationCheckTableV2Data,
      $$MigrationCheckTableV2TableFilterComposer,
      $$MigrationCheckTableV2TableOrderingComposer,
      $$MigrationCheckTableV2TableAnnotationComposer,
      $$MigrationCheckTableV2TableCreateCompanionBuilder,
      $$MigrationCheckTableV2TableUpdateCompanionBuilder,
      (
        MigrationCheckTableV2Data,
        BaseReferences<
          _$MigrationCheckDbV2,
          $MigrationCheckTableV2Table,
          MigrationCheckTableV2Data
        >,
      ),
      MigrationCheckTableV2Data,
      PrefetchHooks Function()
    >;

class $MigrationCheckDbV2Manager {
  final _$MigrationCheckDbV2 _db;
  $MigrationCheckDbV2Manager(this._db);
  $$MigrationCheckTableV2TableTableManager get migrationCheckTableV2 =>
      $$MigrationCheckTableV2TableTableManager(_db, _db.migrationCheckTableV2);
}
