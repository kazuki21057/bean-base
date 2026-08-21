// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CoffeeDataTableTable extends CoffeeDataTable
    with TableInfo<$CoffeeDataTableTable, CoffeeDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoffeeDataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brewedAtMeta = const VerificationMeta(
    'brewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> brewedAt = GeneratedColumn<DateTime>(
    'brewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grinderIdMeta = const VerificationMeta(
    'grinderId',
  );
  @override
  late final GeneratedColumn<String> grinderId = GeneratedColumn<String>(
    'grinder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dripperIdMeta = const VerificationMeta(
    'dripperId',
  );
  @override
  late final GeneratedColumn<String> dripperId = GeneratedColumn<String>(
    'dripper_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _filterIdMeta = const VerificationMeta(
    'filterId',
  );
  @override
  late final GeneratedColumn<String> filterId = GeneratedColumn<String>(
    'filter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<String> beanId = GeneratedColumn<String>(
    'bean_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roastLevelMeta = const VerificationMeta(
    'roastLevel',
  );
  @override
  late final GeneratedColumn<String> roastLevel = GeneratedColumn<String>(
    'roast_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originIdMeta = const VerificationMeta(
    'originId',
  );
  @override
  late final GeneratedColumn<String> originId = GeneratedColumn<String>(
    'origin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _beanWeightMeta = const VerificationMeta(
    'beanWeight',
  );
  @override
  late final GeneratedColumn<double> beanWeight = GeneratedColumn<double>(
    'bean_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _grindSizeMeta = const VerificationMeta(
    'grindSize',
  );
  @override
  late final GeneratedColumn<String> grindSize = GeneratedColumn<String>(
    'grind_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<String> methodId = GeneratedColumn<String>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tasteMeta = const VerificationMeta('taste');
  @override
  late final GeneratedColumn<String> taste = GeneratedColumn<String>(
    'taste',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _concentrationMeta = const VerificationMeta(
    'concentration',
  );
  @override
  late final GeneratedColumn<String> concentration = GeneratedColumn<String>(
    'concentration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bloomingWaterMeta = const VerificationMeta(
    'bloomingWater',
  );
  @override
  late final GeneratedColumn<double> bloomingWater = GeneratedColumn<double>(
    'blooming_water',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalWaterMeta = const VerificationMeta(
    'totalWater',
  );
  @override
  late final GeneratedColumn<double> totalWater = GeneratedColumn<double>(
    'total_water',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bloomingTimeMeta = const VerificationMeta(
    'bloomingTime',
  );
  @override
  late final GeneratedColumn<int> bloomingTime = GeneratedColumn<int>(
    'blooming_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalTimeMeta = const VerificationMeta(
    'totalTime',
  );
  @override
  late final GeneratedColumn<int> totalTime = GeneratedColumn<int>(
    'total_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreFragranceMeta = const VerificationMeta(
    'scoreFragrance',
  );
  @override
  late final GeneratedColumn<int> scoreFragrance = GeneratedColumn<int>(
    'score_fragrance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreAcidityMeta = const VerificationMeta(
    'scoreAcidity',
  );
  @override
  late final GeneratedColumn<int> scoreAcidity = GeneratedColumn<int>(
    'score_acidity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreBitternessMeta = const VerificationMeta(
    'scoreBitterness',
  );
  @override
  late final GeneratedColumn<int> scoreBitterness = GeneratedColumn<int>(
    'score_bitterness',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreSweetnessMeta = const VerificationMeta(
    'scoreSweetness',
  );
  @override
  late final GeneratedColumn<int> scoreSweetness = GeneratedColumn<int>(
    'score_sweetness',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreComplexityMeta = const VerificationMeta(
    'scoreComplexity',
  );
  @override
  late final GeneratedColumn<int> scoreComplexity = GeneratedColumn<int>(
    'score_complexity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreFlavorMeta = const VerificationMeta(
    'scoreFlavor',
  );
  @override
  late final GeneratedColumn<int> scoreFlavor = GeneratedColumn<int>(
    'score_flavor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scoreOverallMeta = const VerificationMeta(
    'scoreOverall',
  );
  @override
  late final GeneratedColumn<int> scoreOverall = GeneratedColumn<int>(
    'score_overall',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _grinderImageUrlMeta = const VerificationMeta(
    'grinderImageUrl',
  );
  @override
  late final GeneratedColumn<String> grinderImageUrl = GeneratedColumn<String>(
    'grinder_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dripperImageUrlMeta = const VerificationMeta(
    'dripperImageUrl',
  );
  @override
  late final GeneratedColumn<String> dripperImageUrl = GeneratedColumn<String>(
    'dripper_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterImageUrlMeta = const VerificationMeta(
    'filterImageUrl',
  );
  @override
  late final GeneratedColumn<String> filterImageUrl = GeneratedColumn<String>(
    'filter_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beanImageUrlMeta = const VerificationMeta(
    'beanImageUrl',
  );
  @override
  late final GeneratedColumn<String> beanImageUrl = GeneratedColumn<String>(
    'bean_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brewedAt,
    grinderId,
    dripperId,
    filterId,
    beanId,
    roastLevel,
    origin,
    originId,
    beanWeight,
    grindSize,
    methodId,
    taste,
    concentration,
    temperature,
    bloomingWater,
    totalWater,
    bloomingTime,
    totalTime,
    scoreFragrance,
    scoreAcidity,
    scoreBitterness,
    scoreSweetness,
    scoreComplexity,
    scoreFlavor,
    scoreOverall,
    comment,
    grinderImageUrl,
    dripperImageUrl,
    filterImageUrl,
    beanImageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coffee_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoffeeDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('brewed_at')) {
      context.handle(
        _brewedAtMeta,
        brewedAt.isAcceptableOrUnknown(data['brewed_at']!, _brewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_brewedAtMeta);
    }
    if (data.containsKey('grinder_id')) {
      context.handle(
        _grinderIdMeta,
        grinderId.isAcceptableOrUnknown(data['grinder_id']!, _grinderIdMeta),
      );
    }
    if (data.containsKey('dripper_id')) {
      context.handle(
        _dripperIdMeta,
        dripperId.isAcceptableOrUnknown(data['dripper_id']!, _dripperIdMeta),
      );
    }
    if (data.containsKey('filter_id')) {
      context.handle(
        _filterIdMeta,
        filterId.isAcceptableOrUnknown(data['filter_id']!, _filterIdMeta),
      );
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('roast_level')) {
      context.handle(
        _roastLevelMeta,
        roastLevel.isAcceptableOrUnknown(data['roast_level']!, _roastLevelMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('origin_id')) {
      context.handle(
        _originIdMeta,
        originId.isAcceptableOrUnknown(data['origin_id']!, _originIdMeta),
      );
    }
    if (data.containsKey('bean_weight')) {
      context.handle(
        _beanWeightMeta,
        beanWeight.isAcceptableOrUnknown(data['bean_weight']!, _beanWeightMeta),
      );
    }
    if (data.containsKey('grind_size')) {
      context.handle(
        _grindSizeMeta,
        grindSize.isAcceptableOrUnknown(data['grind_size']!, _grindSizeMeta),
      );
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    }
    if (data.containsKey('taste')) {
      context.handle(
        _tasteMeta,
        taste.isAcceptableOrUnknown(data['taste']!, _tasteMeta),
      );
    }
    if (data.containsKey('concentration')) {
      context.handle(
        _concentrationMeta,
        concentration.isAcceptableOrUnknown(
          data['concentration']!,
          _concentrationMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('blooming_water')) {
      context.handle(
        _bloomingWaterMeta,
        bloomingWater.isAcceptableOrUnknown(
          data['blooming_water']!,
          _bloomingWaterMeta,
        ),
      );
    }
    if (data.containsKey('total_water')) {
      context.handle(
        _totalWaterMeta,
        totalWater.isAcceptableOrUnknown(data['total_water']!, _totalWaterMeta),
      );
    }
    if (data.containsKey('blooming_time')) {
      context.handle(
        _bloomingTimeMeta,
        bloomingTime.isAcceptableOrUnknown(
          data['blooming_time']!,
          _bloomingTimeMeta,
        ),
      );
    }
    if (data.containsKey('total_time')) {
      context.handle(
        _totalTimeMeta,
        totalTime.isAcceptableOrUnknown(data['total_time']!, _totalTimeMeta),
      );
    }
    if (data.containsKey('score_fragrance')) {
      context.handle(
        _scoreFragranceMeta,
        scoreFragrance.isAcceptableOrUnknown(
          data['score_fragrance']!,
          _scoreFragranceMeta,
        ),
      );
    }
    if (data.containsKey('score_acidity')) {
      context.handle(
        _scoreAcidityMeta,
        scoreAcidity.isAcceptableOrUnknown(
          data['score_acidity']!,
          _scoreAcidityMeta,
        ),
      );
    }
    if (data.containsKey('score_bitterness')) {
      context.handle(
        _scoreBitternessMeta,
        scoreBitterness.isAcceptableOrUnknown(
          data['score_bitterness']!,
          _scoreBitternessMeta,
        ),
      );
    }
    if (data.containsKey('score_sweetness')) {
      context.handle(
        _scoreSweetnessMeta,
        scoreSweetness.isAcceptableOrUnknown(
          data['score_sweetness']!,
          _scoreSweetnessMeta,
        ),
      );
    }
    if (data.containsKey('score_complexity')) {
      context.handle(
        _scoreComplexityMeta,
        scoreComplexity.isAcceptableOrUnknown(
          data['score_complexity']!,
          _scoreComplexityMeta,
        ),
      );
    }
    if (data.containsKey('score_flavor')) {
      context.handle(
        _scoreFlavorMeta,
        scoreFlavor.isAcceptableOrUnknown(
          data['score_flavor']!,
          _scoreFlavorMeta,
        ),
      );
    }
    if (data.containsKey('score_overall')) {
      context.handle(
        _scoreOverallMeta,
        scoreOverall.isAcceptableOrUnknown(
          data['score_overall']!,
          _scoreOverallMeta,
        ),
      );
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('grinder_image_url')) {
      context.handle(
        _grinderImageUrlMeta,
        grinderImageUrl.isAcceptableOrUnknown(
          data['grinder_image_url']!,
          _grinderImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('dripper_image_url')) {
      context.handle(
        _dripperImageUrlMeta,
        dripperImageUrl.isAcceptableOrUnknown(
          data['dripper_image_url']!,
          _dripperImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('filter_image_url')) {
      context.handle(
        _filterImageUrlMeta,
        filterImageUrl.isAcceptableOrUnknown(
          data['filter_image_url']!,
          _filterImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('bean_image_url')) {
      context.handle(
        _beanImageUrlMeta,
        beanImageUrl.isAcceptableOrUnknown(
          data['bean_image_url']!,
          _beanImageUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoffeeDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoffeeDataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      brewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}brewed_at'],
      )!,
      grinderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grinder_id'],
      )!,
      dripperId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dripper_id'],
      )!,
      filterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_id'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_id'],
      )!,
      roastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roast_level'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      originId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_id'],
      )!,
      beanWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bean_weight'],
      )!,
      grindSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grind_size'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_id'],
      )!,
      taste: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taste'],
      )!,
      concentration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concentration'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      bloomingWater: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blooming_water'],
      )!,
      totalWater: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_water'],
      )!,
      bloomingTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blooming_time'],
      )!,
      totalTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time'],
      )!,
      scoreFragrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_fragrance'],
      )!,
      scoreAcidity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_acidity'],
      )!,
      scoreBitterness: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_bitterness'],
      )!,
      scoreSweetness: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_sweetness'],
      )!,
      scoreComplexity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_complexity'],
      )!,
      scoreFlavor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_flavor'],
      )!,
      scoreOverall: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_overall'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
      grinderImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grinder_image_url'],
      ),
      dripperImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dripper_image_url'],
      ),
      filterImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_image_url'],
      ),
      beanImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_image_url'],
      ),
    );
  }

  @override
  $CoffeeDataTableTable createAlias(String alias) {
    return $CoffeeDataTableTable(attachedDatabase, alias);
  }
}

class CoffeeDataRow extends DataClass implements Insertable<CoffeeDataRow> {
  final String id;
  final DateTime brewedAt;
  final String grinderId;
  final String dripperId;
  final String filterId;
  final String beanId;
  final String roastLevel;
  final String origin;
  final String originId;
  final double beanWeight;
  final String grindSize;
  final String methodId;
  final String taste;
  final String concentration;
  final double temperature;
  final double bloomingWater;
  final double totalWater;
  final int bloomingTime;
  final int totalTime;
  final int scoreFragrance;
  final int scoreAcidity;
  final int scoreBitterness;
  final int scoreSweetness;
  final int scoreComplexity;
  final int scoreFlavor;
  final int scoreOverall;
  final String comment;
  final String? grinderImageUrl;
  final String? dripperImageUrl;
  final String? filterImageUrl;
  final String? beanImageUrl;
  const CoffeeDataRow({
    required this.id,
    required this.brewedAt,
    required this.grinderId,
    required this.dripperId,
    required this.filterId,
    required this.beanId,
    required this.roastLevel,
    required this.origin,
    required this.originId,
    required this.beanWeight,
    required this.grindSize,
    required this.methodId,
    required this.taste,
    required this.concentration,
    required this.temperature,
    required this.bloomingWater,
    required this.totalWater,
    required this.bloomingTime,
    required this.totalTime,
    required this.scoreFragrance,
    required this.scoreAcidity,
    required this.scoreBitterness,
    required this.scoreSweetness,
    required this.scoreComplexity,
    required this.scoreFlavor,
    required this.scoreOverall,
    required this.comment,
    this.grinderImageUrl,
    this.dripperImageUrl,
    this.filterImageUrl,
    this.beanImageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['brewed_at'] = Variable<DateTime>(brewedAt);
    map['grinder_id'] = Variable<String>(grinderId);
    map['dripper_id'] = Variable<String>(dripperId);
    map['filter_id'] = Variable<String>(filterId);
    map['bean_id'] = Variable<String>(beanId);
    map['roast_level'] = Variable<String>(roastLevel);
    map['origin'] = Variable<String>(origin);
    map['origin_id'] = Variable<String>(originId);
    map['bean_weight'] = Variable<double>(beanWeight);
    map['grind_size'] = Variable<String>(grindSize);
    map['method_id'] = Variable<String>(methodId);
    map['taste'] = Variable<String>(taste);
    map['concentration'] = Variable<String>(concentration);
    map['temperature'] = Variable<double>(temperature);
    map['blooming_water'] = Variable<double>(bloomingWater);
    map['total_water'] = Variable<double>(totalWater);
    map['blooming_time'] = Variable<int>(bloomingTime);
    map['total_time'] = Variable<int>(totalTime);
    map['score_fragrance'] = Variable<int>(scoreFragrance);
    map['score_acidity'] = Variable<int>(scoreAcidity);
    map['score_bitterness'] = Variable<int>(scoreBitterness);
    map['score_sweetness'] = Variable<int>(scoreSweetness);
    map['score_complexity'] = Variable<int>(scoreComplexity);
    map['score_flavor'] = Variable<int>(scoreFlavor);
    map['score_overall'] = Variable<int>(scoreOverall);
    map['comment'] = Variable<String>(comment);
    if (!nullToAbsent || grinderImageUrl != null) {
      map['grinder_image_url'] = Variable<String>(grinderImageUrl);
    }
    if (!nullToAbsent || dripperImageUrl != null) {
      map['dripper_image_url'] = Variable<String>(dripperImageUrl);
    }
    if (!nullToAbsent || filterImageUrl != null) {
      map['filter_image_url'] = Variable<String>(filterImageUrl);
    }
    if (!nullToAbsent || beanImageUrl != null) {
      map['bean_image_url'] = Variable<String>(beanImageUrl);
    }
    return map;
  }

  CoffeeDataTableCompanion toCompanion(bool nullToAbsent) {
    return CoffeeDataTableCompanion(
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
      grinderImageUrl: grinderImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(grinderImageUrl),
      dripperImageUrl: dripperImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(dripperImageUrl),
      filterImageUrl: filterImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(filterImageUrl),
      beanImageUrl: beanImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(beanImageUrl),
    );
  }

  factory CoffeeDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoffeeDataRow(
      id: serializer.fromJson<String>(json['id']),
      brewedAt: serializer.fromJson<DateTime>(json['brewedAt']),
      grinderId: serializer.fromJson<String>(json['grinderId']),
      dripperId: serializer.fromJson<String>(json['dripperId']),
      filterId: serializer.fromJson<String>(json['filterId']),
      beanId: serializer.fromJson<String>(json['beanId']),
      roastLevel: serializer.fromJson<String>(json['roastLevel']),
      origin: serializer.fromJson<String>(json['origin']),
      originId: serializer.fromJson<String>(json['originId']),
      beanWeight: serializer.fromJson<double>(json['beanWeight']),
      grindSize: serializer.fromJson<String>(json['grindSize']),
      methodId: serializer.fromJson<String>(json['methodId']),
      taste: serializer.fromJson<String>(json['taste']),
      concentration: serializer.fromJson<String>(json['concentration']),
      temperature: serializer.fromJson<double>(json['temperature']),
      bloomingWater: serializer.fromJson<double>(json['bloomingWater']),
      totalWater: serializer.fromJson<double>(json['totalWater']),
      bloomingTime: serializer.fromJson<int>(json['bloomingTime']),
      totalTime: serializer.fromJson<int>(json['totalTime']),
      scoreFragrance: serializer.fromJson<int>(json['scoreFragrance']),
      scoreAcidity: serializer.fromJson<int>(json['scoreAcidity']),
      scoreBitterness: serializer.fromJson<int>(json['scoreBitterness']),
      scoreSweetness: serializer.fromJson<int>(json['scoreSweetness']),
      scoreComplexity: serializer.fromJson<int>(json['scoreComplexity']),
      scoreFlavor: serializer.fromJson<int>(json['scoreFlavor']),
      scoreOverall: serializer.fromJson<int>(json['scoreOverall']),
      comment: serializer.fromJson<String>(json['comment']),
      grinderImageUrl: serializer.fromJson<String?>(json['grinderImageUrl']),
      dripperImageUrl: serializer.fromJson<String?>(json['dripperImageUrl']),
      filterImageUrl: serializer.fromJson<String?>(json['filterImageUrl']),
      beanImageUrl: serializer.fromJson<String?>(json['beanImageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'brewedAt': serializer.toJson<DateTime>(brewedAt),
      'grinderId': serializer.toJson<String>(grinderId),
      'dripperId': serializer.toJson<String>(dripperId),
      'filterId': serializer.toJson<String>(filterId),
      'beanId': serializer.toJson<String>(beanId),
      'roastLevel': serializer.toJson<String>(roastLevel),
      'origin': serializer.toJson<String>(origin),
      'originId': serializer.toJson<String>(originId),
      'beanWeight': serializer.toJson<double>(beanWeight),
      'grindSize': serializer.toJson<String>(grindSize),
      'methodId': serializer.toJson<String>(methodId),
      'taste': serializer.toJson<String>(taste),
      'concentration': serializer.toJson<String>(concentration),
      'temperature': serializer.toJson<double>(temperature),
      'bloomingWater': serializer.toJson<double>(bloomingWater),
      'totalWater': serializer.toJson<double>(totalWater),
      'bloomingTime': serializer.toJson<int>(bloomingTime),
      'totalTime': serializer.toJson<int>(totalTime),
      'scoreFragrance': serializer.toJson<int>(scoreFragrance),
      'scoreAcidity': serializer.toJson<int>(scoreAcidity),
      'scoreBitterness': serializer.toJson<int>(scoreBitterness),
      'scoreSweetness': serializer.toJson<int>(scoreSweetness),
      'scoreComplexity': serializer.toJson<int>(scoreComplexity),
      'scoreFlavor': serializer.toJson<int>(scoreFlavor),
      'scoreOverall': serializer.toJson<int>(scoreOverall),
      'comment': serializer.toJson<String>(comment),
      'grinderImageUrl': serializer.toJson<String?>(grinderImageUrl),
      'dripperImageUrl': serializer.toJson<String?>(dripperImageUrl),
      'filterImageUrl': serializer.toJson<String?>(filterImageUrl),
      'beanImageUrl': serializer.toJson<String?>(beanImageUrl),
    };
  }

  CoffeeDataRow copyWith({
    String? id,
    DateTime? brewedAt,
    String? grinderId,
    String? dripperId,
    String? filterId,
    String? beanId,
    String? roastLevel,
    String? origin,
    String? originId,
    double? beanWeight,
    String? grindSize,
    String? methodId,
    String? taste,
    String? concentration,
    double? temperature,
    double? bloomingWater,
    double? totalWater,
    int? bloomingTime,
    int? totalTime,
    int? scoreFragrance,
    int? scoreAcidity,
    int? scoreBitterness,
    int? scoreSweetness,
    int? scoreComplexity,
    int? scoreFlavor,
    int? scoreOverall,
    String? comment,
    Value<String?> grinderImageUrl = const Value.absent(),
    Value<String?> dripperImageUrl = const Value.absent(),
    Value<String?> filterImageUrl = const Value.absent(),
    Value<String?> beanImageUrl = const Value.absent(),
  }) => CoffeeDataRow(
    id: id ?? this.id,
    brewedAt: brewedAt ?? this.brewedAt,
    grinderId: grinderId ?? this.grinderId,
    dripperId: dripperId ?? this.dripperId,
    filterId: filterId ?? this.filterId,
    beanId: beanId ?? this.beanId,
    roastLevel: roastLevel ?? this.roastLevel,
    origin: origin ?? this.origin,
    originId: originId ?? this.originId,
    beanWeight: beanWeight ?? this.beanWeight,
    grindSize: grindSize ?? this.grindSize,
    methodId: methodId ?? this.methodId,
    taste: taste ?? this.taste,
    concentration: concentration ?? this.concentration,
    temperature: temperature ?? this.temperature,
    bloomingWater: bloomingWater ?? this.bloomingWater,
    totalWater: totalWater ?? this.totalWater,
    bloomingTime: bloomingTime ?? this.bloomingTime,
    totalTime: totalTime ?? this.totalTime,
    scoreFragrance: scoreFragrance ?? this.scoreFragrance,
    scoreAcidity: scoreAcidity ?? this.scoreAcidity,
    scoreBitterness: scoreBitterness ?? this.scoreBitterness,
    scoreSweetness: scoreSweetness ?? this.scoreSweetness,
    scoreComplexity: scoreComplexity ?? this.scoreComplexity,
    scoreFlavor: scoreFlavor ?? this.scoreFlavor,
    scoreOverall: scoreOverall ?? this.scoreOverall,
    comment: comment ?? this.comment,
    grinderImageUrl: grinderImageUrl.present
        ? grinderImageUrl.value
        : this.grinderImageUrl,
    dripperImageUrl: dripperImageUrl.present
        ? dripperImageUrl.value
        : this.dripperImageUrl,
    filterImageUrl: filterImageUrl.present
        ? filterImageUrl.value
        : this.filterImageUrl,
    beanImageUrl: beanImageUrl.present ? beanImageUrl.value : this.beanImageUrl,
  );
  CoffeeDataRow copyWithCompanion(CoffeeDataTableCompanion data) {
    return CoffeeDataRow(
      id: data.id.present ? data.id.value : this.id,
      brewedAt: data.brewedAt.present ? data.brewedAt.value : this.brewedAt,
      grinderId: data.grinderId.present ? data.grinderId.value : this.grinderId,
      dripperId: data.dripperId.present ? data.dripperId.value : this.dripperId,
      filterId: data.filterId.present ? data.filterId.value : this.filterId,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      origin: data.origin.present ? data.origin.value : this.origin,
      originId: data.originId.present ? data.originId.value : this.originId,
      beanWeight: data.beanWeight.present
          ? data.beanWeight.value
          : this.beanWeight,
      grindSize: data.grindSize.present ? data.grindSize.value : this.grindSize,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      taste: data.taste.present ? data.taste.value : this.taste,
      concentration: data.concentration.present
          ? data.concentration.value
          : this.concentration,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      bloomingWater: data.bloomingWater.present
          ? data.bloomingWater.value
          : this.bloomingWater,
      totalWater: data.totalWater.present
          ? data.totalWater.value
          : this.totalWater,
      bloomingTime: data.bloomingTime.present
          ? data.bloomingTime.value
          : this.bloomingTime,
      totalTime: data.totalTime.present ? data.totalTime.value : this.totalTime,
      scoreFragrance: data.scoreFragrance.present
          ? data.scoreFragrance.value
          : this.scoreFragrance,
      scoreAcidity: data.scoreAcidity.present
          ? data.scoreAcidity.value
          : this.scoreAcidity,
      scoreBitterness: data.scoreBitterness.present
          ? data.scoreBitterness.value
          : this.scoreBitterness,
      scoreSweetness: data.scoreSweetness.present
          ? data.scoreSweetness.value
          : this.scoreSweetness,
      scoreComplexity: data.scoreComplexity.present
          ? data.scoreComplexity.value
          : this.scoreComplexity,
      scoreFlavor: data.scoreFlavor.present
          ? data.scoreFlavor.value
          : this.scoreFlavor,
      scoreOverall: data.scoreOverall.present
          ? data.scoreOverall.value
          : this.scoreOverall,
      comment: data.comment.present ? data.comment.value : this.comment,
      grinderImageUrl: data.grinderImageUrl.present
          ? data.grinderImageUrl.value
          : this.grinderImageUrl,
      dripperImageUrl: data.dripperImageUrl.present
          ? data.dripperImageUrl.value
          : this.dripperImageUrl,
      filterImageUrl: data.filterImageUrl.present
          ? data.filterImageUrl.value
          : this.filterImageUrl,
      beanImageUrl: data.beanImageUrl.present
          ? data.beanImageUrl.value
          : this.beanImageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeDataRow(')
          ..write('id: $id, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('grinderId: $grinderId, ')
          ..write('dripperId: $dripperId, ')
          ..write('filterId: $filterId, ')
          ..write('beanId: $beanId, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('origin: $origin, ')
          ..write('originId: $originId, ')
          ..write('beanWeight: $beanWeight, ')
          ..write('grindSize: $grindSize, ')
          ..write('methodId: $methodId, ')
          ..write('taste: $taste, ')
          ..write('concentration: $concentration, ')
          ..write('temperature: $temperature, ')
          ..write('bloomingWater: $bloomingWater, ')
          ..write('totalWater: $totalWater, ')
          ..write('bloomingTime: $bloomingTime, ')
          ..write('totalTime: $totalTime, ')
          ..write('scoreFragrance: $scoreFragrance, ')
          ..write('scoreAcidity: $scoreAcidity, ')
          ..write('scoreBitterness: $scoreBitterness, ')
          ..write('scoreSweetness: $scoreSweetness, ')
          ..write('scoreComplexity: $scoreComplexity, ')
          ..write('scoreFlavor: $scoreFlavor, ')
          ..write('scoreOverall: $scoreOverall, ')
          ..write('comment: $comment, ')
          ..write('grinderImageUrl: $grinderImageUrl, ')
          ..write('dripperImageUrl: $dripperImageUrl, ')
          ..write('filterImageUrl: $filterImageUrl, ')
          ..write('beanImageUrl: $beanImageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    brewedAt,
    grinderId,
    dripperId,
    filterId,
    beanId,
    roastLevel,
    origin,
    originId,
    beanWeight,
    grindSize,
    methodId,
    taste,
    concentration,
    temperature,
    bloomingWater,
    totalWater,
    bloomingTime,
    totalTime,
    scoreFragrance,
    scoreAcidity,
    scoreBitterness,
    scoreSweetness,
    scoreComplexity,
    scoreFlavor,
    scoreOverall,
    comment,
    grinderImageUrl,
    dripperImageUrl,
    filterImageUrl,
    beanImageUrl,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoffeeDataRow &&
          other.id == this.id &&
          other.brewedAt == this.brewedAt &&
          other.grinderId == this.grinderId &&
          other.dripperId == this.dripperId &&
          other.filterId == this.filterId &&
          other.beanId == this.beanId &&
          other.roastLevel == this.roastLevel &&
          other.origin == this.origin &&
          other.originId == this.originId &&
          other.beanWeight == this.beanWeight &&
          other.grindSize == this.grindSize &&
          other.methodId == this.methodId &&
          other.taste == this.taste &&
          other.concentration == this.concentration &&
          other.temperature == this.temperature &&
          other.bloomingWater == this.bloomingWater &&
          other.totalWater == this.totalWater &&
          other.bloomingTime == this.bloomingTime &&
          other.totalTime == this.totalTime &&
          other.scoreFragrance == this.scoreFragrance &&
          other.scoreAcidity == this.scoreAcidity &&
          other.scoreBitterness == this.scoreBitterness &&
          other.scoreSweetness == this.scoreSweetness &&
          other.scoreComplexity == this.scoreComplexity &&
          other.scoreFlavor == this.scoreFlavor &&
          other.scoreOverall == this.scoreOverall &&
          other.comment == this.comment &&
          other.grinderImageUrl == this.grinderImageUrl &&
          other.dripperImageUrl == this.dripperImageUrl &&
          other.filterImageUrl == this.filterImageUrl &&
          other.beanImageUrl == this.beanImageUrl);
}

class CoffeeDataTableCompanion extends UpdateCompanion<CoffeeDataRow> {
  final Value<String> id;
  final Value<DateTime> brewedAt;
  final Value<String> grinderId;
  final Value<String> dripperId;
  final Value<String> filterId;
  final Value<String> beanId;
  final Value<String> roastLevel;
  final Value<String> origin;
  final Value<String> originId;
  final Value<double> beanWeight;
  final Value<String> grindSize;
  final Value<String> methodId;
  final Value<String> taste;
  final Value<String> concentration;
  final Value<double> temperature;
  final Value<double> bloomingWater;
  final Value<double> totalWater;
  final Value<int> bloomingTime;
  final Value<int> totalTime;
  final Value<int> scoreFragrance;
  final Value<int> scoreAcidity;
  final Value<int> scoreBitterness;
  final Value<int> scoreSweetness;
  final Value<int> scoreComplexity;
  final Value<int> scoreFlavor;
  final Value<int> scoreOverall;
  final Value<String> comment;
  final Value<String?> grinderImageUrl;
  final Value<String?> dripperImageUrl;
  final Value<String?> filterImageUrl;
  final Value<String?> beanImageUrl;
  final Value<int> rowid;
  const CoffeeDataTableCompanion({
    this.id = const Value.absent(),
    this.brewedAt = const Value.absent(),
    this.grinderId = const Value.absent(),
    this.dripperId = const Value.absent(),
    this.filterId = const Value.absent(),
    this.beanId = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.origin = const Value.absent(),
    this.originId = const Value.absent(),
    this.beanWeight = const Value.absent(),
    this.grindSize = const Value.absent(),
    this.methodId = const Value.absent(),
    this.taste = const Value.absent(),
    this.concentration = const Value.absent(),
    this.temperature = const Value.absent(),
    this.bloomingWater = const Value.absent(),
    this.totalWater = const Value.absent(),
    this.bloomingTime = const Value.absent(),
    this.totalTime = const Value.absent(),
    this.scoreFragrance = const Value.absent(),
    this.scoreAcidity = const Value.absent(),
    this.scoreBitterness = const Value.absent(),
    this.scoreSweetness = const Value.absent(),
    this.scoreComplexity = const Value.absent(),
    this.scoreFlavor = const Value.absent(),
    this.scoreOverall = const Value.absent(),
    this.comment = const Value.absent(),
    this.grinderImageUrl = const Value.absent(),
    this.dripperImageUrl = const Value.absent(),
    this.filterImageUrl = const Value.absent(),
    this.beanImageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoffeeDataTableCompanion.insert({
    required String id,
    required DateTime brewedAt,
    this.grinderId = const Value.absent(),
    this.dripperId = const Value.absent(),
    this.filterId = const Value.absent(),
    this.beanId = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.origin = const Value.absent(),
    this.originId = const Value.absent(),
    this.beanWeight = const Value.absent(),
    this.grindSize = const Value.absent(),
    this.methodId = const Value.absent(),
    this.taste = const Value.absent(),
    this.concentration = const Value.absent(),
    this.temperature = const Value.absent(),
    this.bloomingWater = const Value.absent(),
    this.totalWater = const Value.absent(),
    this.bloomingTime = const Value.absent(),
    this.totalTime = const Value.absent(),
    this.scoreFragrance = const Value.absent(),
    this.scoreAcidity = const Value.absent(),
    this.scoreBitterness = const Value.absent(),
    this.scoreSweetness = const Value.absent(),
    this.scoreComplexity = const Value.absent(),
    this.scoreFlavor = const Value.absent(),
    this.scoreOverall = const Value.absent(),
    this.comment = const Value.absent(),
    this.grinderImageUrl = const Value.absent(),
    this.dripperImageUrl = const Value.absent(),
    this.filterImageUrl = const Value.absent(),
    this.beanImageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       brewedAt = Value(brewedAt);
  static Insertable<CoffeeDataRow> custom({
    Expression<String>? id,
    Expression<DateTime>? brewedAt,
    Expression<String>? grinderId,
    Expression<String>? dripperId,
    Expression<String>? filterId,
    Expression<String>? beanId,
    Expression<String>? roastLevel,
    Expression<String>? origin,
    Expression<String>? originId,
    Expression<double>? beanWeight,
    Expression<String>? grindSize,
    Expression<String>? methodId,
    Expression<String>? taste,
    Expression<String>? concentration,
    Expression<double>? temperature,
    Expression<double>? bloomingWater,
    Expression<double>? totalWater,
    Expression<int>? bloomingTime,
    Expression<int>? totalTime,
    Expression<int>? scoreFragrance,
    Expression<int>? scoreAcidity,
    Expression<int>? scoreBitterness,
    Expression<int>? scoreSweetness,
    Expression<int>? scoreComplexity,
    Expression<int>? scoreFlavor,
    Expression<int>? scoreOverall,
    Expression<String>? comment,
    Expression<String>? grinderImageUrl,
    Expression<String>? dripperImageUrl,
    Expression<String>? filterImageUrl,
    Expression<String>? beanImageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brewedAt != null) 'brewed_at': brewedAt,
      if (grinderId != null) 'grinder_id': grinderId,
      if (dripperId != null) 'dripper_id': dripperId,
      if (filterId != null) 'filter_id': filterId,
      if (beanId != null) 'bean_id': beanId,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (origin != null) 'origin': origin,
      if (originId != null) 'origin_id': originId,
      if (beanWeight != null) 'bean_weight': beanWeight,
      if (grindSize != null) 'grind_size': grindSize,
      if (methodId != null) 'method_id': methodId,
      if (taste != null) 'taste': taste,
      if (concentration != null) 'concentration': concentration,
      if (temperature != null) 'temperature': temperature,
      if (bloomingWater != null) 'blooming_water': bloomingWater,
      if (totalWater != null) 'total_water': totalWater,
      if (bloomingTime != null) 'blooming_time': bloomingTime,
      if (totalTime != null) 'total_time': totalTime,
      if (scoreFragrance != null) 'score_fragrance': scoreFragrance,
      if (scoreAcidity != null) 'score_acidity': scoreAcidity,
      if (scoreBitterness != null) 'score_bitterness': scoreBitterness,
      if (scoreSweetness != null) 'score_sweetness': scoreSweetness,
      if (scoreComplexity != null) 'score_complexity': scoreComplexity,
      if (scoreFlavor != null) 'score_flavor': scoreFlavor,
      if (scoreOverall != null) 'score_overall': scoreOverall,
      if (comment != null) 'comment': comment,
      if (grinderImageUrl != null) 'grinder_image_url': grinderImageUrl,
      if (dripperImageUrl != null) 'dripper_image_url': dripperImageUrl,
      if (filterImageUrl != null) 'filter_image_url': filterImageUrl,
      if (beanImageUrl != null) 'bean_image_url': beanImageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoffeeDataTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? brewedAt,
    Value<String>? grinderId,
    Value<String>? dripperId,
    Value<String>? filterId,
    Value<String>? beanId,
    Value<String>? roastLevel,
    Value<String>? origin,
    Value<String>? originId,
    Value<double>? beanWeight,
    Value<String>? grindSize,
    Value<String>? methodId,
    Value<String>? taste,
    Value<String>? concentration,
    Value<double>? temperature,
    Value<double>? bloomingWater,
    Value<double>? totalWater,
    Value<int>? bloomingTime,
    Value<int>? totalTime,
    Value<int>? scoreFragrance,
    Value<int>? scoreAcidity,
    Value<int>? scoreBitterness,
    Value<int>? scoreSweetness,
    Value<int>? scoreComplexity,
    Value<int>? scoreFlavor,
    Value<int>? scoreOverall,
    Value<String>? comment,
    Value<String?>? grinderImageUrl,
    Value<String?>? dripperImageUrl,
    Value<String?>? filterImageUrl,
    Value<String?>? beanImageUrl,
    Value<int>? rowid,
  }) {
    return CoffeeDataTableCompanion(
      id: id ?? this.id,
      brewedAt: brewedAt ?? this.brewedAt,
      grinderId: grinderId ?? this.grinderId,
      dripperId: dripperId ?? this.dripperId,
      filterId: filterId ?? this.filterId,
      beanId: beanId ?? this.beanId,
      roastLevel: roastLevel ?? this.roastLevel,
      origin: origin ?? this.origin,
      originId: originId ?? this.originId,
      beanWeight: beanWeight ?? this.beanWeight,
      grindSize: grindSize ?? this.grindSize,
      methodId: methodId ?? this.methodId,
      taste: taste ?? this.taste,
      concentration: concentration ?? this.concentration,
      temperature: temperature ?? this.temperature,
      bloomingWater: bloomingWater ?? this.bloomingWater,
      totalWater: totalWater ?? this.totalWater,
      bloomingTime: bloomingTime ?? this.bloomingTime,
      totalTime: totalTime ?? this.totalTime,
      scoreFragrance: scoreFragrance ?? this.scoreFragrance,
      scoreAcidity: scoreAcidity ?? this.scoreAcidity,
      scoreBitterness: scoreBitterness ?? this.scoreBitterness,
      scoreSweetness: scoreSweetness ?? this.scoreSweetness,
      scoreComplexity: scoreComplexity ?? this.scoreComplexity,
      scoreFlavor: scoreFlavor ?? this.scoreFlavor,
      scoreOverall: scoreOverall ?? this.scoreOverall,
      comment: comment ?? this.comment,
      grinderImageUrl: grinderImageUrl ?? this.grinderImageUrl,
      dripperImageUrl: dripperImageUrl ?? this.dripperImageUrl,
      filterImageUrl: filterImageUrl ?? this.filterImageUrl,
      beanImageUrl: beanImageUrl ?? this.beanImageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (brewedAt.present) {
      map['brewed_at'] = Variable<DateTime>(brewedAt.value);
    }
    if (grinderId.present) {
      map['grinder_id'] = Variable<String>(grinderId.value);
    }
    if (dripperId.present) {
      map['dripper_id'] = Variable<String>(dripperId.value);
    }
    if (filterId.present) {
      map['filter_id'] = Variable<String>(filterId.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<String>(beanId.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(roastLevel.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (originId.present) {
      map['origin_id'] = Variable<String>(originId.value);
    }
    if (beanWeight.present) {
      map['bean_weight'] = Variable<double>(beanWeight.value);
    }
    if (grindSize.present) {
      map['grind_size'] = Variable<String>(grindSize.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<String>(methodId.value);
    }
    if (taste.present) {
      map['taste'] = Variable<String>(taste.value);
    }
    if (concentration.present) {
      map['concentration'] = Variable<String>(concentration.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (bloomingWater.present) {
      map['blooming_water'] = Variable<double>(bloomingWater.value);
    }
    if (totalWater.present) {
      map['total_water'] = Variable<double>(totalWater.value);
    }
    if (bloomingTime.present) {
      map['blooming_time'] = Variable<int>(bloomingTime.value);
    }
    if (totalTime.present) {
      map['total_time'] = Variable<int>(totalTime.value);
    }
    if (scoreFragrance.present) {
      map['score_fragrance'] = Variable<int>(scoreFragrance.value);
    }
    if (scoreAcidity.present) {
      map['score_acidity'] = Variable<int>(scoreAcidity.value);
    }
    if (scoreBitterness.present) {
      map['score_bitterness'] = Variable<int>(scoreBitterness.value);
    }
    if (scoreSweetness.present) {
      map['score_sweetness'] = Variable<int>(scoreSweetness.value);
    }
    if (scoreComplexity.present) {
      map['score_complexity'] = Variable<int>(scoreComplexity.value);
    }
    if (scoreFlavor.present) {
      map['score_flavor'] = Variable<int>(scoreFlavor.value);
    }
    if (scoreOverall.present) {
      map['score_overall'] = Variable<int>(scoreOverall.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (grinderImageUrl.present) {
      map['grinder_image_url'] = Variable<String>(grinderImageUrl.value);
    }
    if (dripperImageUrl.present) {
      map['dripper_image_url'] = Variable<String>(dripperImageUrl.value);
    }
    if (filterImageUrl.present) {
      map['filter_image_url'] = Variable<String>(filterImageUrl.value);
    }
    if (beanImageUrl.present) {
      map['bean_image_url'] = Variable<String>(beanImageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoffeeDataTableCompanion(')
          ..write('id: $id, ')
          ..write('brewedAt: $brewedAt, ')
          ..write('grinderId: $grinderId, ')
          ..write('dripperId: $dripperId, ')
          ..write('filterId: $filterId, ')
          ..write('beanId: $beanId, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('origin: $origin, ')
          ..write('originId: $originId, ')
          ..write('beanWeight: $beanWeight, ')
          ..write('grindSize: $grindSize, ')
          ..write('methodId: $methodId, ')
          ..write('taste: $taste, ')
          ..write('concentration: $concentration, ')
          ..write('temperature: $temperature, ')
          ..write('bloomingWater: $bloomingWater, ')
          ..write('totalWater: $totalWater, ')
          ..write('bloomingTime: $bloomingTime, ')
          ..write('totalTime: $totalTime, ')
          ..write('scoreFragrance: $scoreFragrance, ')
          ..write('scoreAcidity: $scoreAcidity, ')
          ..write('scoreBitterness: $scoreBitterness, ')
          ..write('scoreSweetness: $scoreSweetness, ')
          ..write('scoreComplexity: $scoreComplexity, ')
          ..write('scoreFlavor: $scoreFlavor, ')
          ..write('scoreOverall: $scoreOverall, ')
          ..write('comment: $comment, ')
          ..write('grinderImageUrl: $grinderImageUrl, ')
          ..write('dripperImageUrl: $dripperImageUrl, ')
          ..write('filterImageUrl: $filterImageUrl, ')
          ..write('beanImageUrl: $beanImageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BeanMasterTableTable extends BeanMasterTable
    with TableInfo<$BeanMasterTableTable, BeanMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeanMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _roastLevelMeta = const VerificationMeta(
    'roastLevel',
  );
  @override
  late final GeneratedColumn<String> roastLevel = GeneratedColumn<String>(
    'roast_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storeMeta = const VerificationMeta('store');
  @override
  late final GeneratedColumn<String> store = GeneratedColumn<String>(
    'store',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beanImageUrlMeta = const VerificationMeta(
    'beanImageUrl',
  );
  @override
  late final GeneratedColumn<String> beanImageUrl = GeneratedColumn<String>(
    'bean_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _infoImageUrlMeta = const VerificationMeta(
    'infoImageUrl',
  );
  @override
  late final GeneratedColumn<String> infoImageUrl = GeneratedColumn<String>(
    'info_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstUseDateMeta = const VerificationMeta(
    'firstUseDate',
  );
  @override
  late final GeneratedColumn<DateTime> firstUseDate = GeneratedColumn<DateTime>(
    'first_use_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUseDateMeta = const VerificationMeta(
    'lastUseDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastUseDate = GeneratedColumn<DateTime>(
    'last_use_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInStockMeta = const VerificationMeta(
    'isInStock',
  );
  @override
  late final GeneratedColumn<bool> isInStock = GeneratedColumn<bool>(
    'is_in_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_in_stock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _initialQuantityGramsMeta =
      const VerificationMeta('initialQuantityGrams');
  @override
  late final GeneratedColumn<double> initialQuantityGrams =
      GeneratedColumn<double>(
        'initial_quantity_grams',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _originIdMeta = const VerificationMeta(
    'originId',
  );
  @override
  late final GeneratedColumn<String> originId = GeneratedColumn<String>(
    'origin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roastDateMeta = const VerificationMeta(
    'roastDate',
  );
  @override
  late final GeneratedColumn<DateTime> roastDate = GeneratedColumn<DateTime>(
    'roast_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockBaselineGramsMeta =
      const VerificationMeta('stockBaselineGrams');
  @override
  late final GeneratedColumn<double> stockBaselineGrams =
      GeneratedColumn<double>(
        'stock_baseline_grams',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _stockBaselineAtMeta = const VerificationMeta(
    'stockBaselineAt',
  );
  @override
  late final GeneratedColumn<DateTime> stockBaselineAt =
      GeneratedColumn<DateTime>(
        'stock_baseline_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _storageLocationMeta = const VerificationMeta(
    'storageLocation',
  );
  @override
  late final GeneratedColumn<String> storageLocation = GeneratedColumn<String>(
    'storage_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _seekOptimalConditionsMeta =
      const VerificationMeta('seekOptimalConditions');
  @override
  late final GeneratedColumn<bool> seekOptimalConditions =
      GeneratedColumn<bool>(
        'seek_optimal_conditions',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("seek_optimal_conditions" IN (0, 1))',
        ),
      );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    roastLevel,
    origin,
    store,
    type,
    imageUrl,
    beanImageUrl,
    infoImageUrl,
    purchaseDate,
    firstUseDate,
    lastUseDate,
    isInStock,
    initialQuantityGrams,
    originId,
    roastDate,
    stockBaselineGrams,
    stockBaselineAt,
    storageLocation,
    seekOptimalConditions,
    storeId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bean_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeanMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('roast_level')) {
      context.handle(
        _roastLevelMeta,
        roastLevel.isAcceptableOrUnknown(data['roast_level']!, _roastLevelMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('store')) {
      context.handle(
        _storeMeta,
        store.isAcceptableOrUnknown(data['store']!, _storeMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('bean_image_url')) {
      context.handle(
        _beanImageUrlMeta,
        beanImageUrl.isAcceptableOrUnknown(
          data['bean_image_url']!,
          _beanImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('info_image_url')) {
      context.handle(
        _infoImageUrlMeta,
        infoImageUrl.isAcceptableOrUnknown(
          data['info_image_url']!,
          _infoImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('first_use_date')) {
      context.handle(
        _firstUseDateMeta,
        firstUseDate.isAcceptableOrUnknown(
          data['first_use_date']!,
          _firstUseDateMeta,
        ),
      );
    }
    if (data.containsKey('last_use_date')) {
      context.handle(
        _lastUseDateMeta,
        lastUseDate.isAcceptableOrUnknown(
          data['last_use_date']!,
          _lastUseDateMeta,
        ),
      );
    }
    if (data.containsKey('is_in_stock')) {
      context.handle(
        _isInStockMeta,
        isInStock.isAcceptableOrUnknown(data['is_in_stock']!, _isInStockMeta),
      );
    }
    if (data.containsKey('initial_quantity_grams')) {
      context.handle(
        _initialQuantityGramsMeta,
        initialQuantityGrams.isAcceptableOrUnknown(
          data['initial_quantity_grams']!,
          _initialQuantityGramsMeta,
        ),
      );
    }
    if (data.containsKey('origin_id')) {
      context.handle(
        _originIdMeta,
        originId.isAcceptableOrUnknown(data['origin_id']!, _originIdMeta),
      );
    }
    if (data.containsKey('roast_date')) {
      context.handle(
        _roastDateMeta,
        roastDate.isAcceptableOrUnknown(data['roast_date']!, _roastDateMeta),
      );
    }
    if (data.containsKey('stock_baseline_grams')) {
      context.handle(
        _stockBaselineGramsMeta,
        stockBaselineGrams.isAcceptableOrUnknown(
          data['stock_baseline_grams']!,
          _stockBaselineGramsMeta,
        ),
      );
    }
    if (data.containsKey('stock_baseline_at')) {
      context.handle(
        _stockBaselineAtMeta,
        stockBaselineAt.isAcceptableOrUnknown(
          data['stock_baseline_at']!,
          _stockBaselineAtMeta,
        ),
      );
    }
    if (data.containsKey('storage_location')) {
      context.handle(
        _storageLocationMeta,
        storageLocation.isAcceptableOrUnknown(
          data['storage_location']!,
          _storageLocationMeta,
        ),
      );
    }
    if (data.containsKey('seek_optimal_conditions')) {
      context.handle(
        _seekOptimalConditionsMeta,
        seekOptimalConditions.isAcceptableOrUnknown(
          data['seek_optimal_conditions']!,
          _seekOptimalConditionsMeta,
        ),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeanMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeanMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      roastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roast_level'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      store: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      beanImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_image_url'],
      ),
      infoImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}info_image_url'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      firstUseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_use_date'],
      ),
      lastUseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_use_date'],
      ),
      isInStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_in_stock'],
      )!,
      initialQuantityGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_quantity_grams'],
      ),
      originId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_id'],
      )!,
      roastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roast_date'],
      ),
      stockBaselineGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_baseline_grams'],
      ),
      stockBaselineAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stock_baseline_at'],
      ),
      storageLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_location'],
      )!,
      seekOptimalConditions: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seek_optimal_conditions'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
    );
  }

  @override
  $BeanMasterTableTable createAlias(String alias) {
    return $BeanMasterTableTable(attachedDatabase, alias);
  }
}

class BeanMasterRow extends DataClass implements Insertable<BeanMasterRow> {
  final String id;
  final String name;
  final String roastLevel;
  final String origin;
  final String store;
  final String type;
  final String? imageUrl;
  final String? beanImageUrl;
  final String? infoImageUrl;
  final DateTime? purchaseDate;
  final DateTime? firstUseDate;
  final DateTime? lastUseDate;
  final bool isInStock;
  final double? initialQuantityGrams;
  final String originId;
  final DateTime? roastDate;
  final double? stockBaselineGrams;
  final DateTime? stockBaselineAt;
  final String storageLocation;
  final bool? seekOptimalConditions;
  final String storeId;
  const BeanMasterRow({
    required this.id,
    required this.name,
    required this.roastLevel,
    required this.origin,
    required this.store,
    required this.type,
    this.imageUrl,
    this.beanImageUrl,
    this.infoImageUrl,
    this.purchaseDate,
    this.firstUseDate,
    this.lastUseDate,
    required this.isInStock,
    this.initialQuantityGrams,
    required this.originId,
    this.roastDate,
    this.stockBaselineGrams,
    this.stockBaselineAt,
    required this.storageLocation,
    this.seekOptimalConditions,
    required this.storeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['roast_level'] = Variable<String>(roastLevel);
    map['origin'] = Variable<String>(origin);
    map['store'] = Variable<String>(store);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || beanImageUrl != null) {
      map['bean_image_url'] = Variable<String>(beanImageUrl);
    }
    if (!nullToAbsent || infoImageUrl != null) {
      map['info_image_url'] = Variable<String>(infoImageUrl);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || firstUseDate != null) {
      map['first_use_date'] = Variable<DateTime>(firstUseDate);
    }
    if (!nullToAbsent || lastUseDate != null) {
      map['last_use_date'] = Variable<DateTime>(lastUseDate);
    }
    map['is_in_stock'] = Variable<bool>(isInStock);
    if (!nullToAbsent || initialQuantityGrams != null) {
      map['initial_quantity_grams'] = Variable<double>(initialQuantityGrams);
    }
    map['origin_id'] = Variable<String>(originId);
    if (!nullToAbsent || roastDate != null) {
      map['roast_date'] = Variable<DateTime>(roastDate);
    }
    if (!nullToAbsent || stockBaselineGrams != null) {
      map['stock_baseline_grams'] = Variable<double>(stockBaselineGrams);
    }
    if (!nullToAbsent || stockBaselineAt != null) {
      map['stock_baseline_at'] = Variable<DateTime>(stockBaselineAt);
    }
    map['storage_location'] = Variable<String>(storageLocation);
    if (!nullToAbsent || seekOptimalConditions != null) {
      map['seek_optimal_conditions'] = Variable<bool>(seekOptimalConditions);
    }
    map['store_id'] = Variable<String>(storeId);
    return map;
  }

  BeanMasterTableCompanion toCompanion(bool nullToAbsent) {
    return BeanMasterTableCompanion(
      id: Value(id),
      name: Value(name),
      roastLevel: Value(roastLevel),
      origin: Value(origin),
      store: Value(store),
      type: Value(type),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      beanImageUrl: beanImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(beanImageUrl),
      infoImageUrl: infoImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(infoImageUrl),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      firstUseDate: firstUseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(firstUseDate),
      lastUseDate: lastUseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUseDate),
      isInStock: Value(isInStock),
      initialQuantityGrams: initialQuantityGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(initialQuantityGrams),
      originId: Value(originId),
      roastDate: roastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDate),
      stockBaselineGrams: stockBaselineGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(stockBaselineGrams),
      stockBaselineAt: stockBaselineAt == null && nullToAbsent
          ? const Value.absent()
          : Value(stockBaselineAt),
      storageLocation: Value(storageLocation),
      seekOptimalConditions: seekOptimalConditions == null && nullToAbsent
          ? const Value.absent()
          : Value(seekOptimalConditions),
      storeId: Value(storeId),
    );
  }

  factory BeanMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeanMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      roastLevel: serializer.fromJson<String>(json['roastLevel']),
      origin: serializer.fromJson<String>(json['origin']),
      store: serializer.fromJson<String>(json['store']),
      type: serializer.fromJson<String>(json['type']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      beanImageUrl: serializer.fromJson<String?>(json['beanImageUrl']),
      infoImageUrl: serializer.fromJson<String?>(json['infoImageUrl']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      firstUseDate: serializer.fromJson<DateTime?>(json['firstUseDate']),
      lastUseDate: serializer.fromJson<DateTime?>(json['lastUseDate']),
      isInStock: serializer.fromJson<bool>(json['isInStock']),
      initialQuantityGrams: serializer.fromJson<double?>(
        json['initialQuantityGrams'],
      ),
      originId: serializer.fromJson<String>(json['originId']),
      roastDate: serializer.fromJson<DateTime?>(json['roastDate']),
      stockBaselineGrams: serializer.fromJson<double?>(
        json['stockBaselineGrams'],
      ),
      stockBaselineAt: serializer.fromJson<DateTime?>(json['stockBaselineAt']),
      storageLocation: serializer.fromJson<String>(json['storageLocation']),
      seekOptimalConditions: serializer.fromJson<bool?>(
        json['seekOptimalConditions'],
      ),
      storeId: serializer.fromJson<String>(json['storeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'roastLevel': serializer.toJson<String>(roastLevel),
      'origin': serializer.toJson<String>(origin),
      'store': serializer.toJson<String>(store),
      'type': serializer.toJson<String>(type),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'beanImageUrl': serializer.toJson<String?>(beanImageUrl),
      'infoImageUrl': serializer.toJson<String?>(infoImageUrl),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'firstUseDate': serializer.toJson<DateTime?>(firstUseDate),
      'lastUseDate': serializer.toJson<DateTime?>(lastUseDate),
      'isInStock': serializer.toJson<bool>(isInStock),
      'initialQuantityGrams': serializer.toJson<double?>(initialQuantityGrams),
      'originId': serializer.toJson<String>(originId),
      'roastDate': serializer.toJson<DateTime?>(roastDate),
      'stockBaselineGrams': serializer.toJson<double?>(stockBaselineGrams),
      'stockBaselineAt': serializer.toJson<DateTime?>(stockBaselineAt),
      'storageLocation': serializer.toJson<String>(storageLocation),
      'seekOptimalConditions': serializer.toJson<bool?>(seekOptimalConditions),
      'storeId': serializer.toJson<String>(storeId),
    };
  }

  BeanMasterRow copyWith({
    String? id,
    String? name,
    String? roastLevel,
    String? origin,
    String? store,
    String? type,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> beanImageUrl = const Value.absent(),
    Value<String?> infoImageUrl = const Value.absent(),
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<DateTime?> firstUseDate = const Value.absent(),
    Value<DateTime?> lastUseDate = const Value.absent(),
    bool? isInStock,
    Value<double?> initialQuantityGrams = const Value.absent(),
    String? originId,
    Value<DateTime?> roastDate = const Value.absent(),
    Value<double?> stockBaselineGrams = const Value.absent(),
    Value<DateTime?> stockBaselineAt = const Value.absent(),
    String? storageLocation,
    Value<bool?> seekOptimalConditions = const Value.absent(),
    String? storeId,
  }) => BeanMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    roastLevel: roastLevel ?? this.roastLevel,
    origin: origin ?? this.origin,
    store: store ?? this.store,
    type: type ?? this.type,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    beanImageUrl: beanImageUrl.present ? beanImageUrl.value : this.beanImageUrl,
    infoImageUrl: infoImageUrl.present ? infoImageUrl.value : this.infoImageUrl,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    firstUseDate: firstUseDate.present ? firstUseDate.value : this.firstUseDate,
    lastUseDate: lastUseDate.present ? lastUseDate.value : this.lastUseDate,
    isInStock: isInStock ?? this.isInStock,
    initialQuantityGrams: initialQuantityGrams.present
        ? initialQuantityGrams.value
        : this.initialQuantityGrams,
    originId: originId ?? this.originId,
    roastDate: roastDate.present ? roastDate.value : this.roastDate,
    stockBaselineGrams: stockBaselineGrams.present
        ? stockBaselineGrams.value
        : this.stockBaselineGrams,
    stockBaselineAt: stockBaselineAt.present
        ? stockBaselineAt.value
        : this.stockBaselineAt,
    storageLocation: storageLocation ?? this.storageLocation,
    seekOptimalConditions: seekOptimalConditions.present
        ? seekOptimalConditions.value
        : this.seekOptimalConditions,
    storeId: storeId ?? this.storeId,
  );
  BeanMasterRow copyWithCompanion(BeanMasterTableCompanion data) {
    return BeanMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      origin: data.origin.present ? data.origin.value : this.origin,
      store: data.store.present ? data.store.value : this.store,
      type: data.type.present ? data.type.value : this.type,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      beanImageUrl: data.beanImageUrl.present
          ? data.beanImageUrl.value
          : this.beanImageUrl,
      infoImageUrl: data.infoImageUrl.present
          ? data.infoImageUrl.value
          : this.infoImageUrl,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      firstUseDate: data.firstUseDate.present
          ? data.firstUseDate.value
          : this.firstUseDate,
      lastUseDate: data.lastUseDate.present
          ? data.lastUseDate.value
          : this.lastUseDate,
      isInStock: data.isInStock.present ? data.isInStock.value : this.isInStock,
      initialQuantityGrams: data.initialQuantityGrams.present
          ? data.initialQuantityGrams.value
          : this.initialQuantityGrams,
      originId: data.originId.present ? data.originId.value : this.originId,
      roastDate: data.roastDate.present ? data.roastDate.value : this.roastDate,
      stockBaselineGrams: data.stockBaselineGrams.present
          ? data.stockBaselineGrams.value
          : this.stockBaselineGrams,
      stockBaselineAt: data.stockBaselineAt.present
          ? data.stockBaselineAt.value
          : this.stockBaselineAt,
      storageLocation: data.storageLocation.present
          ? data.storageLocation.value
          : this.storageLocation,
      seekOptimalConditions: data.seekOptimalConditions.present
          ? data.seekOptimalConditions.value
          : this.seekOptimalConditions,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeanMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('origin: $origin, ')
          ..write('store: $store, ')
          ..write('type: $type, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('beanImageUrl: $beanImageUrl, ')
          ..write('infoImageUrl: $infoImageUrl, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('firstUseDate: $firstUseDate, ')
          ..write('lastUseDate: $lastUseDate, ')
          ..write('isInStock: $isInStock, ')
          ..write('initialQuantityGrams: $initialQuantityGrams, ')
          ..write('originId: $originId, ')
          ..write('roastDate: $roastDate, ')
          ..write('stockBaselineGrams: $stockBaselineGrams, ')
          ..write('stockBaselineAt: $stockBaselineAt, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('seekOptimalConditions: $seekOptimalConditions, ')
          ..write('storeId: $storeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    roastLevel,
    origin,
    store,
    type,
    imageUrl,
    beanImageUrl,
    infoImageUrl,
    purchaseDate,
    firstUseDate,
    lastUseDate,
    isInStock,
    initialQuantityGrams,
    originId,
    roastDate,
    stockBaselineGrams,
    stockBaselineAt,
    storageLocation,
    seekOptimalConditions,
    storeId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeanMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.roastLevel == this.roastLevel &&
          other.origin == this.origin &&
          other.store == this.store &&
          other.type == this.type &&
          other.imageUrl == this.imageUrl &&
          other.beanImageUrl == this.beanImageUrl &&
          other.infoImageUrl == this.infoImageUrl &&
          other.purchaseDate == this.purchaseDate &&
          other.firstUseDate == this.firstUseDate &&
          other.lastUseDate == this.lastUseDate &&
          other.isInStock == this.isInStock &&
          other.initialQuantityGrams == this.initialQuantityGrams &&
          other.originId == this.originId &&
          other.roastDate == this.roastDate &&
          other.stockBaselineGrams == this.stockBaselineGrams &&
          other.stockBaselineAt == this.stockBaselineAt &&
          other.storageLocation == this.storageLocation &&
          other.seekOptimalConditions == this.seekOptimalConditions &&
          other.storeId == this.storeId);
}

class BeanMasterTableCompanion extends UpdateCompanion<BeanMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> roastLevel;
  final Value<String> origin;
  final Value<String> store;
  final Value<String> type;
  final Value<String?> imageUrl;
  final Value<String?> beanImageUrl;
  final Value<String?> infoImageUrl;
  final Value<DateTime?> purchaseDate;
  final Value<DateTime?> firstUseDate;
  final Value<DateTime?> lastUseDate;
  final Value<bool> isInStock;
  final Value<double?> initialQuantityGrams;
  final Value<String> originId;
  final Value<DateTime?> roastDate;
  final Value<double?> stockBaselineGrams;
  final Value<DateTime?> stockBaselineAt;
  final Value<String> storageLocation;
  final Value<bool?> seekOptimalConditions;
  final Value<String> storeId;
  final Value<int> rowid;
  const BeanMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.origin = const Value.absent(),
    this.store = const Value.absent(),
    this.type = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.beanImageUrl = const Value.absent(),
    this.infoImageUrl = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.firstUseDate = const Value.absent(),
    this.lastUseDate = const Value.absent(),
    this.isInStock = const Value.absent(),
    this.initialQuantityGrams = const Value.absent(),
    this.originId = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.stockBaselineGrams = const Value.absent(),
    this.stockBaselineAt = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.seekOptimalConditions = const Value.absent(),
    this.storeId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeanMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.origin = const Value.absent(),
    this.store = const Value.absent(),
    this.type = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.beanImageUrl = const Value.absent(),
    this.infoImageUrl = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.firstUseDate = const Value.absent(),
    this.lastUseDate = const Value.absent(),
    this.isInStock = const Value.absent(),
    this.initialQuantityGrams = const Value.absent(),
    this.originId = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.stockBaselineGrams = const Value.absent(),
    this.stockBaselineAt = const Value.absent(),
    this.storageLocation = const Value.absent(),
    this.seekOptimalConditions = const Value.absent(),
    this.storeId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BeanMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? roastLevel,
    Expression<String>? origin,
    Expression<String>? store,
    Expression<String>? type,
    Expression<String>? imageUrl,
    Expression<String>? beanImageUrl,
    Expression<String>? infoImageUrl,
    Expression<DateTime>? purchaseDate,
    Expression<DateTime>? firstUseDate,
    Expression<DateTime>? lastUseDate,
    Expression<bool>? isInStock,
    Expression<double>? initialQuantityGrams,
    Expression<String>? originId,
    Expression<DateTime>? roastDate,
    Expression<double>? stockBaselineGrams,
    Expression<DateTime>? stockBaselineAt,
    Expression<String>? storageLocation,
    Expression<bool>? seekOptimalConditions,
    Expression<String>? storeId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (origin != null) 'origin': origin,
      if (store != null) 'store': store,
      if (type != null) 'type': type,
      if (imageUrl != null) 'image_url': imageUrl,
      if (beanImageUrl != null) 'bean_image_url': beanImageUrl,
      if (infoImageUrl != null) 'info_image_url': infoImageUrl,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (firstUseDate != null) 'first_use_date': firstUseDate,
      if (lastUseDate != null) 'last_use_date': lastUseDate,
      if (isInStock != null) 'is_in_stock': isInStock,
      if (initialQuantityGrams != null)
        'initial_quantity_grams': initialQuantityGrams,
      if (originId != null) 'origin_id': originId,
      if (roastDate != null) 'roast_date': roastDate,
      if (stockBaselineGrams != null)
        'stock_baseline_grams': stockBaselineGrams,
      if (stockBaselineAt != null) 'stock_baseline_at': stockBaselineAt,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (seekOptimalConditions != null)
        'seek_optimal_conditions': seekOptimalConditions,
      if (storeId != null) 'store_id': storeId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeanMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? roastLevel,
    Value<String>? origin,
    Value<String>? store,
    Value<String>? type,
    Value<String?>? imageUrl,
    Value<String?>? beanImageUrl,
    Value<String?>? infoImageUrl,
    Value<DateTime?>? purchaseDate,
    Value<DateTime?>? firstUseDate,
    Value<DateTime?>? lastUseDate,
    Value<bool>? isInStock,
    Value<double?>? initialQuantityGrams,
    Value<String>? originId,
    Value<DateTime?>? roastDate,
    Value<double?>? stockBaselineGrams,
    Value<DateTime?>? stockBaselineAt,
    Value<String>? storageLocation,
    Value<bool?>? seekOptimalConditions,
    Value<String>? storeId,
    Value<int>? rowid,
  }) {
    return BeanMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      roastLevel: roastLevel ?? this.roastLevel,
      origin: origin ?? this.origin,
      store: store ?? this.store,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      beanImageUrl: beanImageUrl ?? this.beanImageUrl,
      infoImageUrl: infoImageUrl ?? this.infoImageUrl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      firstUseDate: firstUseDate ?? this.firstUseDate,
      lastUseDate: lastUseDate ?? this.lastUseDate,
      isInStock: isInStock ?? this.isInStock,
      initialQuantityGrams: initialQuantityGrams ?? this.initialQuantityGrams,
      originId: originId ?? this.originId,
      roastDate: roastDate ?? this.roastDate,
      stockBaselineGrams: stockBaselineGrams ?? this.stockBaselineGrams,
      stockBaselineAt: stockBaselineAt ?? this.stockBaselineAt,
      storageLocation: storageLocation ?? this.storageLocation,
      seekOptimalConditions:
          seekOptimalConditions ?? this.seekOptimalConditions,
      storeId: storeId ?? this.storeId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(roastLevel.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (store.present) {
      map['store'] = Variable<String>(store.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (beanImageUrl.present) {
      map['bean_image_url'] = Variable<String>(beanImageUrl.value);
    }
    if (infoImageUrl.present) {
      map['info_image_url'] = Variable<String>(infoImageUrl.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (firstUseDate.present) {
      map['first_use_date'] = Variable<DateTime>(firstUseDate.value);
    }
    if (lastUseDate.present) {
      map['last_use_date'] = Variable<DateTime>(lastUseDate.value);
    }
    if (isInStock.present) {
      map['is_in_stock'] = Variable<bool>(isInStock.value);
    }
    if (initialQuantityGrams.present) {
      map['initial_quantity_grams'] = Variable<double>(
        initialQuantityGrams.value,
      );
    }
    if (originId.present) {
      map['origin_id'] = Variable<String>(originId.value);
    }
    if (roastDate.present) {
      map['roast_date'] = Variable<DateTime>(roastDate.value);
    }
    if (stockBaselineGrams.present) {
      map['stock_baseline_grams'] = Variable<double>(stockBaselineGrams.value);
    }
    if (stockBaselineAt.present) {
      map['stock_baseline_at'] = Variable<DateTime>(stockBaselineAt.value);
    }
    if (storageLocation.present) {
      map['storage_location'] = Variable<String>(storageLocation.value);
    }
    if (seekOptimalConditions.present) {
      map['seek_optimal_conditions'] = Variable<bool>(
        seekOptimalConditions.value,
      );
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeanMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('origin: $origin, ')
          ..write('store: $store, ')
          ..write('type: $type, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('beanImageUrl: $beanImageUrl, ')
          ..write('infoImageUrl: $infoImageUrl, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('firstUseDate: $firstUseDate, ')
          ..write('lastUseDate: $lastUseDate, ')
          ..write('isInStock: $isInStock, ')
          ..write('initialQuantityGrams: $initialQuantityGrams, ')
          ..write('originId: $originId, ')
          ..write('roastDate: $roastDate, ')
          ..write('stockBaselineGrams: $stockBaselineGrams, ')
          ..write('stockBaselineAt: $stockBaselineAt, ')
          ..write('storageLocation: $storageLocation, ')
          ..write('seekOptimalConditions: $seekOptimalConditions, ')
          ..write('storeId: $storeId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MethodsMasterTableTable extends MethodsMasterTable
    with TableInfo<$MethodsMasterTableTable, MethodsMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MethodsMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _baseBeanWeightMeta = const VerificationMeta(
    'baseBeanWeight',
  );
  @override
  late final GeneratedColumn<double> baseBeanWeight = GeneratedColumn<double>(
    'base_bean_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _baseWaterAmountMeta = const VerificationMeta(
    'baseWaterAmount',
  );
  @override
  late final GeneratedColumn<double> baseWaterAmount = GeneratedColumn<double>(
    'base_water_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grindSizeMeta = const VerificationMeta(
    'grindSize',
  );
  @override
  late final GeneratedColumn<String> grindSize = GeneratedColumn<String>(
    'grind_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recommendedEquipmentMeta =
      const VerificationMeta('recommendedEquipment');
  @override
  late final GeneratedColumn<String> recommendedEquipment =
      GeneratedColumn<String>(
        'recommended_equipment',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedRoastLevelMeta =
      const VerificationMeta('recommendedRoastLevel');
  @override
  late final GeneratedColumn<String> recommendedRoastLevel =
      GeneratedColumn<String>(
        'recommended_roast_level',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recommendedRoastMinMeta =
      const VerificationMeta('recommendedRoastMin');
  @override
  late final GeneratedColumn<String> recommendedRoastMin =
      GeneratedColumn<String>(
        'recommended_roast_min',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recommendedRoastMaxMeta =
      const VerificationMeta('recommendedRoastMax');
  @override
  late final GeneratedColumn<String> recommendedRoastMax =
      GeneratedColumn<String>(
        'recommended_roast_max',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    author,
    baseBeanWeight,
    baseWaterAmount,
    temperature,
    grindSize,
    description,
    recommendedEquipment,
    sourceUrl,
    recommendedRoastLevel,
    recommendedRoastMin,
    recommendedRoastMax,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'methods_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<MethodsMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('base_bean_weight')) {
      context.handle(
        _baseBeanWeightMeta,
        baseBeanWeight.isAcceptableOrUnknown(
          data['base_bean_weight']!,
          _baseBeanWeightMeta,
        ),
      );
    }
    if (data.containsKey('base_water_amount')) {
      context.handle(
        _baseWaterAmountMeta,
        baseWaterAmount.isAcceptableOrUnknown(
          data['base_water_amount']!,
          _baseWaterAmountMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('grind_size')) {
      context.handle(
        _grindSizeMeta,
        grindSize.isAcceptableOrUnknown(data['grind_size']!, _grindSizeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('recommended_equipment')) {
      context.handle(
        _recommendedEquipmentMeta,
        recommendedEquipment.isAcceptableOrUnknown(
          data['recommended_equipment']!,
          _recommendedEquipmentMeta,
        ),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('recommended_roast_level')) {
      context.handle(
        _recommendedRoastLevelMeta,
        recommendedRoastLevel.isAcceptableOrUnknown(
          data['recommended_roast_level']!,
          _recommendedRoastLevelMeta,
        ),
      );
    }
    if (data.containsKey('recommended_roast_min')) {
      context.handle(
        _recommendedRoastMinMeta,
        recommendedRoastMin.isAcceptableOrUnknown(
          data['recommended_roast_min']!,
          _recommendedRoastMinMeta,
        ),
      );
    }
    if (data.containsKey('recommended_roast_max')) {
      context.handle(
        _recommendedRoastMaxMeta,
        recommendedRoastMax.isAcceptableOrUnknown(
          data['recommended_roast_max']!,
          _recommendedRoastMaxMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MethodsMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MethodsMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      baseBeanWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_bean_weight'],
      )!,
      baseWaterAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_water_amount'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      grindSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grind_size'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      recommendedEquipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_equipment'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      recommendedRoastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_roast_level'],
      ),
      recommendedRoastMin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_roast_min'],
      ),
      recommendedRoastMax: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommended_roast_max'],
      ),
    );
  }

  @override
  $MethodsMasterTableTable createAlias(String alias) {
    return $MethodsMasterTableTable(attachedDatabase, alias);
  }
}

class MethodsMasterRow extends DataClass
    implements Insertable<MethodsMasterRow> {
  final String id;
  final String name;
  final String author;
  final double baseBeanWeight;
  final double baseWaterAmount;
  final double? temperature;
  final String? grindSize;
  final String description;
  final String recommendedEquipment;
  final String? sourceUrl;
  final String? recommendedRoastLevel;
  final String? recommendedRoastMin;
  final String? recommendedRoastMax;
  const MethodsMasterRow({
    required this.id,
    required this.name,
    required this.author,
    required this.baseBeanWeight,
    required this.baseWaterAmount,
    this.temperature,
    this.grindSize,
    required this.description,
    required this.recommendedEquipment,
    this.sourceUrl,
    this.recommendedRoastLevel,
    this.recommendedRoastMin,
    this.recommendedRoastMax,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['author'] = Variable<String>(author);
    map['base_bean_weight'] = Variable<double>(baseBeanWeight);
    map['base_water_amount'] = Variable<double>(baseWaterAmount);
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || grindSize != null) {
      map['grind_size'] = Variable<String>(grindSize);
    }
    map['description'] = Variable<String>(description);
    map['recommended_equipment'] = Variable<String>(recommendedEquipment);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || recommendedRoastLevel != null) {
      map['recommended_roast_level'] = Variable<String>(recommendedRoastLevel);
    }
    if (!nullToAbsent || recommendedRoastMin != null) {
      map['recommended_roast_min'] = Variable<String>(recommendedRoastMin);
    }
    if (!nullToAbsent || recommendedRoastMax != null) {
      map['recommended_roast_max'] = Variable<String>(recommendedRoastMax);
    }
    return map;
  }

  MethodsMasterTableCompanion toCompanion(bool nullToAbsent) {
    return MethodsMasterTableCompanion(
      id: Value(id),
      name: Value(name),
      author: Value(author),
      baseBeanWeight: Value(baseBeanWeight),
      baseWaterAmount: Value(baseWaterAmount),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      grindSize: grindSize == null && nullToAbsent
          ? const Value.absent()
          : Value(grindSize),
      description: Value(description),
      recommendedEquipment: Value(recommendedEquipment),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      recommendedRoastLevel: recommendedRoastLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedRoastLevel),
      recommendedRoastMin: recommendedRoastMin == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedRoastMin),
      recommendedRoastMax: recommendedRoastMax == null && nullToAbsent
          ? const Value.absent()
          : Value(recommendedRoastMax),
    );
  }

  factory MethodsMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MethodsMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String>(json['author']),
      baseBeanWeight: serializer.fromJson<double>(json['baseBeanWeight']),
      baseWaterAmount: serializer.fromJson<double>(json['baseWaterAmount']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      grindSize: serializer.fromJson<String?>(json['grindSize']),
      description: serializer.fromJson<String>(json['description']),
      recommendedEquipment: serializer.fromJson<String>(
        json['recommendedEquipment'],
      ),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      recommendedRoastLevel: serializer.fromJson<String?>(
        json['recommendedRoastLevel'],
      ),
      recommendedRoastMin: serializer.fromJson<String?>(
        json['recommendedRoastMin'],
      ),
      recommendedRoastMax: serializer.fromJson<String?>(
        json['recommendedRoastMax'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String>(author),
      'baseBeanWeight': serializer.toJson<double>(baseBeanWeight),
      'baseWaterAmount': serializer.toJson<double>(baseWaterAmount),
      'temperature': serializer.toJson<double?>(temperature),
      'grindSize': serializer.toJson<String?>(grindSize),
      'description': serializer.toJson<String>(description),
      'recommendedEquipment': serializer.toJson<String>(recommendedEquipment),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'recommendedRoastLevel': serializer.toJson<String?>(
        recommendedRoastLevel,
      ),
      'recommendedRoastMin': serializer.toJson<String?>(recommendedRoastMin),
      'recommendedRoastMax': serializer.toJson<String?>(recommendedRoastMax),
    };
  }

  MethodsMasterRow copyWith({
    String? id,
    String? name,
    String? author,
    double? baseBeanWeight,
    double? baseWaterAmount,
    Value<double?> temperature = const Value.absent(),
    Value<String?> grindSize = const Value.absent(),
    String? description,
    String? recommendedEquipment,
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> recommendedRoastLevel = const Value.absent(),
    Value<String?> recommendedRoastMin = const Value.absent(),
    Value<String?> recommendedRoastMax = const Value.absent(),
  }) => MethodsMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    author: author ?? this.author,
    baseBeanWeight: baseBeanWeight ?? this.baseBeanWeight,
    baseWaterAmount: baseWaterAmount ?? this.baseWaterAmount,
    temperature: temperature.present ? temperature.value : this.temperature,
    grindSize: grindSize.present ? grindSize.value : this.grindSize,
    description: description ?? this.description,
    recommendedEquipment: recommendedEquipment ?? this.recommendedEquipment,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    recommendedRoastLevel: recommendedRoastLevel.present
        ? recommendedRoastLevel.value
        : this.recommendedRoastLevel,
    recommendedRoastMin: recommendedRoastMin.present
        ? recommendedRoastMin.value
        : this.recommendedRoastMin,
    recommendedRoastMax: recommendedRoastMax.present
        ? recommendedRoastMax.value
        : this.recommendedRoastMax,
  );
  MethodsMasterRow copyWithCompanion(MethodsMasterTableCompanion data) {
    return MethodsMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      baseBeanWeight: data.baseBeanWeight.present
          ? data.baseBeanWeight.value
          : this.baseBeanWeight,
      baseWaterAmount: data.baseWaterAmount.present
          ? data.baseWaterAmount.value
          : this.baseWaterAmount,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      grindSize: data.grindSize.present ? data.grindSize.value : this.grindSize,
      description: data.description.present
          ? data.description.value
          : this.description,
      recommendedEquipment: data.recommendedEquipment.present
          ? data.recommendedEquipment.value
          : this.recommendedEquipment,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      recommendedRoastLevel: data.recommendedRoastLevel.present
          ? data.recommendedRoastLevel.value
          : this.recommendedRoastLevel,
      recommendedRoastMin: data.recommendedRoastMin.present
          ? data.recommendedRoastMin.value
          : this.recommendedRoastMin,
      recommendedRoastMax: data.recommendedRoastMax.present
          ? data.recommendedRoastMax.value
          : this.recommendedRoastMax,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MethodsMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('baseBeanWeight: $baseBeanWeight, ')
          ..write('baseWaterAmount: $baseWaterAmount, ')
          ..write('temperature: $temperature, ')
          ..write('grindSize: $grindSize, ')
          ..write('description: $description, ')
          ..write('recommendedEquipment: $recommendedEquipment, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('recommendedRoastLevel: $recommendedRoastLevel, ')
          ..write('recommendedRoastMin: $recommendedRoastMin, ')
          ..write('recommendedRoastMax: $recommendedRoastMax')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    author,
    baseBeanWeight,
    baseWaterAmount,
    temperature,
    grindSize,
    description,
    recommendedEquipment,
    sourceUrl,
    recommendedRoastLevel,
    recommendedRoastMin,
    recommendedRoastMax,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MethodsMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.author == this.author &&
          other.baseBeanWeight == this.baseBeanWeight &&
          other.baseWaterAmount == this.baseWaterAmount &&
          other.temperature == this.temperature &&
          other.grindSize == this.grindSize &&
          other.description == this.description &&
          other.recommendedEquipment == this.recommendedEquipment &&
          other.sourceUrl == this.sourceUrl &&
          other.recommendedRoastLevel == this.recommendedRoastLevel &&
          other.recommendedRoastMin == this.recommendedRoastMin &&
          other.recommendedRoastMax == this.recommendedRoastMax);
}

class MethodsMasterTableCompanion extends UpdateCompanion<MethodsMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> author;
  final Value<double> baseBeanWeight;
  final Value<double> baseWaterAmount;
  final Value<double?> temperature;
  final Value<String?> grindSize;
  final Value<String> description;
  final Value<String> recommendedEquipment;
  final Value<String?> sourceUrl;
  final Value<String?> recommendedRoastLevel;
  final Value<String?> recommendedRoastMin;
  final Value<String?> recommendedRoastMax;
  final Value<int> rowid;
  const MethodsMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.baseBeanWeight = const Value.absent(),
    this.baseWaterAmount = const Value.absent(),
    this.temperature = const Value.absent(),
    this.grindSize = const Value.absent(),
    this.description = const Value.absent(),
    this.recommendedEquipment = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.recommendedRoastLevel = const Value.absent(),
    this.recommendedRoastMin = const Value.absent(),
    this.recommendedRoastMax = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MethodsMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.author = const Value.absent(),
    this.baseBeanWeight = const Value.absent(),
    this.baseWaterAmount = const Value.absent(),
    this.temperature = const Value.absent(),
    this.grindSize = const Value.absent(),
    this.description = const Value.absent(),
    this.recommendedEquipment = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.recommendedRoastLevel = const Value.absent(),
    this.recommendedRoastMin = const Value.absent(),
    this.recommendedRoastMax = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MethodsMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? author,
    Expression<double>? baseBeanWeight,
    Expression<double>? baseWaterAmount,
    Expression<double>? temperature,
    Expression<String>? grindSize,
    Expression<String>? description,
    Expression<String>? recommendedEquipment,
    Expression<String>? sourceUrl,
    Expression<String>? recommendedRoastLevel,
    Expression<String>? recommendedRoastMin,
    Expression<String>? recommendedRoastMax,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (baseBeanWeight != null) 'base_bean_weight': baseBeanWeight,
      if (baseWaterAmount != null) 'base_water_amount': baseWaterAmount,
      if (temperature != null) 'temperature': temperature,
      if (grindSize != null) 'grind_size': grindSize,
      if (description != null) 'description': description,
      if (recommendedEquipment != null)
        'recommended_equipment': recommendedEquipment,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (recommendedRoastLevel != null)
        'recommended_roast_level': recommendedRoastLevel,
      if (recommendedRoastMin != null)
        'recommended_roast_min': recommendedRoastMin,
      if (recommendedRoastMax != null)
        'recommended_roast_max': recommendedRoastMax,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MethodsMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? author,
    Value<double>? baseBeanWeight,
    Value<double>? baseWaterAmount,
    Value<double?>? temperature,
    Value<String?>? grindSize,
    Value<String>? description,
    Value<String>? recommendedEquipment,
    Value<String?>? sourceUrl,
    Value<String?>? recommendedRoastLevel,
    Value<String?>? recommendedRoastMin,
    Value<String?>? recommendedRoastMax,
    Value<int>? rowid,
  }) {
    return MethodsMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      baseBeanWeight: baseBeanWeight ?? this.baseBeanWeight,
      baseWaterAmount: baseWaterAmount ?? this.baseWaterAmount,
      temperature: temperature ?? this.temperature,
      grindSize: grindSize ?? this.grindSize,
      description: description ?? this.description,
      recommendedEquipment: recommendedEquipment ?? this.recommendedEquipment,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      recommendedRoastLevel:
          recommendedRoastLevel ?? this.recommendedRoastLevel,
      recommendedRoastMin: recommendedRoastMin ?? this.recommendedRoastMin,
      recommendedRoastMax: recommendedRoastMax ?? this.recommendedRoastMax,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (baseBeanWeight.present) {
      map['base_bean_weight'] = Variable<double>(baseBeanWeight.value);
    }
    if (baseWaterAmount.present) {
      map['base_water_amount'] = Variable<double>(baseWaterAmount.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (grindSize.present) {
      map['grind_size'] = Variable<String>(grindSize.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (recommendedEquipment.present) {
      map['recommended_equipment'] = Variable<String>(
        recommendedEquipment.value,
      );
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (recommendedRoastLevel.present) {
      map['recommended_roast_level'] = Variable<String>(
        recommendedRoastLevel.value,
      );
    }
    if (recommendedRoastMin.present) {
      map['recommended_roast_min'] = Variable<String>(
        recommendedRoastMin.value,
      );
    }
    if (recommendedRoastMax.present) {
      map['recommended_roast_max'] = Variable<String>(
        recommendedRoastMax.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MethodsMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('baseBeanWeight: $baseBeanWeight, ')
          ..write('baseWaterAmount: $baseWaterAmount, ')
          ..write('temperature: $temperature, ')
          ..write('grindSize: $grindSize, ')
          ..write('description: $description, ')
          ..write('recommendedEquipment: $recommendedEquipment, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('recommendedRoastLevel: $recommendedRoastLevel, ')
          ..write('recommendedRoastMin: $recommendedRoastMin, ')
          ..write('recommendedRoastMax: $recommendedRoastMax, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PouringStepsTableTable extends PouringStepsTable
    with TableInfo<$PouringStepsTableTable, PouringStepRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PouringStepsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<String> methodId = GeneratedColumn<String>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stepOrderMeta = const VerificationMeta(
    'stepOrder',
  );
  @override
  late final GeneratedColumn<int> stepOrder = GeneratedColumn<int>(
    'step_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _waterAmountMeta = const VerificationMeta(
    'waterAmount',
  );
  @override
  late final GeneratedColumn<double> waterAmount = GeneratedColumn<double>(
    'water_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _waterReferenceMeta = const VerificationMeta(
    'waterReference',
  );
  @override
  late final GeneratedColumn<double> waterReference = GeneratedColumn<double>(
    'water_reference',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _waterRatioMeta = const VerificationMeta(
    'waterRatio',
  );
  @override
  late final GeneratedColumn<double> waterRatio = GeneratedColumn<double>(
    'water_ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    methodId,
    stepOrder,
    duration,
    waterAmount,
    waterReference,
    waterRatio,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pouring_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<PouringStepRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    }
    if (data.containsKey('step_order')) {
      context.handle(
        _stepOrderMeta,
        stepOrder.isAcceptableOrUnknown(data['step_order']!, _stepOrderMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('water_amount')) {
      context.handle(
        _waterAmountMeta,
        waterAmount.isAcceptableOrUnknown(
          data['water_amount']!,
          _waterAmountMeta,
        ),
      );
    }
    if (data.containsKey('water_reference')) {
      context.handle(
        _waterReferenceMeta,
        waterReference.isAcceptableOrUnknown(
          data['water_reference']!,
          _waterReferenceMeta,
        ),
      );
    }
    if (data.containsKey('water_ratio')) {
      context.handle(
        _waterRatioMeta,
        waterRatio.isAcceptableOrUnknown(data['water_ratio']!, _waterRatioMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PouringStepRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PouringStepRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_id'],
      )!,
      stepOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_order'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      waterAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_amount'],
      )!,
      waterReference: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_reference'],
      )!,
      waterRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_ratio'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
    );
  }

  @override
  $PouringStepsTableTable createAlias(String alias) {
    return $PouringStepsTableTable(attachedDatabase, alias);
  }
}

class PouringStepRow extends DataClass implements Insertable<PouringStepRow> {
  final String id;
  final String methodId;
  final int stepOrder;
  final int duration;
  final double waterAmount;
  final double waterReference;
  final double? waterRatio;
  final String description;
  const PouringStepRow({
    required this.id,
    required this.methodId,
    required this.stepOrder,
    required this.duration,
    required this.waterAmount,
    required this.waterReference,
    this.waterRatio,
    required this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['method_id'] = Variable<String>(methodId);
    map['step_order'] = Variable<int>(stepOrder);
    map['duration'] = Variable<int>(duration);
    map['water_amount'] = Variable<double>(waterAmount);
    map['water_reference'] = Variable<double>(waterReference);
    if (!nullToAbsent || waterRatio != null) {
      map['water_ratio'] = Variable<double>(waterRatio);
    }
    map['description'] = Variable<String>(description);
    return map;
  }

  PouringStepsTableCompanion toCompanion(bool nullToAbsent) {
    return PouringStepsTableCompanion(
      id: Value(id),
      methodId: Value(methodId),
      stepOrder: Value(stepOrder),
      duration: Value(duration),
      waterAmount: Value(waterAmount),
      waterReference: Value(waterReference),
      waterRatio: waterRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(waterRatio),
      description: Value(description),
    );
  }

  factory PouringStepRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PouringStepRow(
      id: serializer.fromJson<String>(json['id']),
      methodId: serializer.fromJson<String>(json['methodId']),
      stepOrder: serializer.fromJson<int>(json['stepOrder']),
      duration: serializer.fromJson<int>(json['duration']),
      waterAmount: serializer.fromJson<double>(json['waterAmount']),
      waterReference: serializer.fromJson<double>(json['waterReference']),
      waterRatio: serializer.fromJson<double?>(json['waterRatio']),
      description: serializer.fromJson<String>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'methodId': serializer.toJson<String>(methodId),
      'stepOrder': serializer.toJson<int>(stepOrder),
      'duration': serializer.toJson<int>(duration),
      'waterAmount': serializer.toJson<double>(waterAmount),
      'waterReference': serializer.toJson<double>(waterReference),
      'waterRatio': serializer.toJson<double?>(waterRatio),
      'description': serializer.toJson<String>(description),
    };
  }

  PouringStepRow copyWith({
    String? id,
    String? methodId,
    int? stepOrder,
    int? duration,
    double? waterAmount,
    double? waterReference,
    Value<double?> waterRatio = const Value.absent(),
    String? description,
  }) => PouringStepRow(
    id: id ?? this.id,
    methodId: methodId ?? this.methodId,
    stepOrder: stepOrder ?? this.stepOrder,
    duration: duration ?? this.duration,
    waterAmount: waterAmount ?? this.waterAmount,
    waterReference: waterReference ?? this.waterReference,
    waterRatio: waterRatio.present ? waterRatio.value : this.waterRatio,
    description: description ?? this.description,
  );
  PouringStepRow copyWithCompanion(PouringStepsTableCompanion data) {
    return PouringStepRow(
      id: data.id.present ? data.id.value : this.id,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      stepOrder: data.stepOrder.present ? data.stepOrder.value : this.stepOrder,
      duration: data.duration.present ? data.duration.value : this.duration,
      waterAmount: data.waterAmount.present
          ? data.waterAmount.value
          : this.waterAmount,
      waterReference: data.waterReference.present
          ? data.waterReference.value
          : this.waterReference,
      waterRatio: data.waterRatio.present
          ? data.waterRatio.value
          : this.waterRatio,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PouringStepRow(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('duration: $duration, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('waterReference: $waterReference, ')
          ..write('waterRatio: $waterRatio, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    methodId,
    stepOrder,
    duration,
    waterAmount,
    waterReference,
    waterRatio,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PouringStepRow &&
          other.id == this.id &&
          other.methodId == this.methodId &&
          other.stepOrder == this.stepOrder &&
          other.duration == this.duration &&
          other.waterAmount == this.waterAmount &&
          other.waterReference == this.waterReference &&
          other.waterRatio == this.waterRatio &&
          other.description == this.description);
}

class PouringStepsTableCompanion extends UpdateCompanion<PouringStepRow> {
  final Value<String> id;
  final Value<String> methodId;
  final Value<int> stepOrder;
  final Value<int> duration;
  final Value<double> waterAmount;
  final Value<double> waterReference;
  final Value<double?> waterRatio;
  final Value<String> description;
  final Value<int> rowid;
  const PouringStepsTableCompanion({
    this.id = const Value.absent(),
    this.methodId = const Value.absent(),
    this.stepOrder = const Value.absent(),
    this.duration = const Value.absent(),
    this.waterAmount = const Value.absent(),
    this.waterReference = const Value.absent(),
    this.waterRatio = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PouringStepsTableCompanion.insert({
    required String id,
    this.methodId = const Value.absent(),
    this.stepOrder = const Value.absent(),
    this.duration = const Value.absent(),
    this.waterAmount = const Value.absent(),
    this.waterReference = const Value.absent(),
    this.waterRatio = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<PouringStepRow> custom({
    Expression<String>? id,
    Expression<String>? methodId,
    Expression<int>? stepOrder,
    Expression<int>? duration,
    Expression<double>? waterAmount,
    Expression<double>? waterReference,
    Expression<double>? waterRatio,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (methodId != null) 'method_id': methodId,
      if (stepOrder != null) 'step_order': stepOrder,
      if (duration != null) 'duration': duration,
      if (waterAmount != null) 'water_amount': waterAmount,
      if (waterReference != null) 'water_reference': waterReference,
      if (waterRatio != null) 'water_ratio': waterRatio,
      if (description != null) 'description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PouringStepsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? methodId,
    Value<int>? stepOrder,
    Value<int>? duration,
    Value<double>? waterAmount,
    Value<double>? waterReference,
    Value<double?>? waterRatio,
    Value<String>? description,
    Value<int>? rowid,
  }) {
    return PouringStepsTableCompanion(
      id: id ?? this.id,
      methodId: methodId ?? this.methodId,
      stepOrder: stepOrder ?? this.stepOrder,
      duration: duration ?? this.duration,
      waterAmount: waterAmount ?? this.waterAmount,
      waterReference: waterReference ?? this.waterReference,
      waterRatio: waterRatio ?? this.waterRatio,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<String>(methodId.value);
    }
    if (stepOrder.present) {
      map['step_order'] = Variable<int>(stepOrder.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (waterAmount.present) {
      map['water_amount'] = Variable<double>(waterAmount.value);
    }
    if (waterReference.present) {
      map['water_reference'] = Variable<double>(waterReference.value);
    }
    if (waterRatio.present) {
      map['water_ratio'] = Variable<double>(waterRatio.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PouringStepsTableCompanion(')
          ..write('id: $id, ')
          ..write('methodId: $methodId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('duration: $duration, ')
          ..write('waterAmount: $waterAmount, ')
          ..write('waterReference: $waterReference, ')
          ..write('waterRatio: $waterRatio, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MillMasterTableTable extends MillMasterTable
    with TableInfo<$MillMasterTableTable, MillMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MillMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _grindRangeMeta = const VerificationMeta(
    'grindRange',
  );
  @override
  late final GeneratedColumn<String> grindRange = GeneratedColumn<String>(
    'grind_range',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    grindRange,
    description,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mill_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<MillMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('grind_range')) {
      context.handle(
        _grindRangeMeta,
        grindRange.isAcceptableOrUnknown(data['grind_range']!, _grindRangeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MillMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MillMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      grindRange: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grind_range'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $MillMasterTableTable createAlias(String alias) {
    return $MillMasterTableTable(attachedDatabase, alias);
  }
}

class MillMasterRow extends DataClass implements Insertable<MillMasterRow> {
  final String id;
  final String name;
  final String? grindRange;
  final String? description;
  final String? imageUrl;
  const MillMasterRow({
    required this.id,
    required this.name,
    this.grindRange,
    this.description,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || grindRange != null) {
      map['grind_range'] = Variable<String>(grindRange);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  MillMasterTableCompanion toCompanion(bool nullToAbsent) {
    return MillMasterTableCompanion(
      id: Value(id),
      name: Value(name),
      grindRange: grindRange == null && nullToAbsent
          ? const Value.absent()
          : Value(grindRange),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory MillMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MillMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      grindRange: serializer.fromJson<String?>(json['grindRange']),
      description: serializer.fromJson<String?>(json['description']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'grindRange': serializer.toJson<String?>(grindRange),
      'description': serializer.toJson<String?>(description),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  MillMasterRow copyWith({
    String? id,
    String? name,
    Value<String?> grindRange = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => MillMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    grindRange: grindRange.present ? grindRange.value : this.grindRange,
    description: description.present ? description.value : this.description,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  MillMasterRow copyWithCompanion(MillMasterTableCompanion data) {
    return MillMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      grindRange: data.grindRange.present
          ? data.grindRange.value
          : this.grindRange,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MillMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('grindRange: $grindRange, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, grindRange, description, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MillMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.grindRange == this.grindRange &&
          other.description == this.description &&
          other.imageUrl == this.imageUrl);
}

class MillMasterTableCompanion extends UpdateCompanion<MillMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> grindRange;
  final Value<String?> description;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const MillMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.grindRange = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MillMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.grindRange = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<MillMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? grindRange,
    Expression<String>? description,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (grindRange != null) 'grind_range': grindRange,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MillMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? grindRange,
    Value<String?>? description,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return MillMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      grindRange: grindRange ?? this.grindRange,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (grindRange.present) {
      map['grind_range'] = Variable<String>(grindRange.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MillMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('grindRange: $grindRange, ')
          ..write('description: $description, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DripperMasterTableTable extends DripperMasterTable
    with TableInfo<$DripperMasterTableTable, DripperMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DripperMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _materialMeta = const VerificationMeta(
    'material',
  );
  @override
  late final GeneratedColumn<String> material = GeneratedColumn<String>(
    'material',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  @override
  late final GeneratedColumn<String> shape = GeneratedColumn<String>(
    'shape',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, material, shape, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dripper_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<DripperMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('material')) {
      context.handle(
        _materialMeta,
        material.isAcceptableOrUnknown(data['material']!, _materialMeta),
      );
    }
    if (data.containsKey('shape')) {
      context.handle(
        _shapeMeta,
        shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DripperMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DripperMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      material: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material'],
      ),
      shape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $DripperMasterTableTable createAlias(String alias) {
    return $DripperMasterTableTable(attachedDatabase, alias);
  }
}

class DripperMasterRow extends DataClass
    implements Insertable<DripperMasterRow> {
  final String id;
  final String name;
  final String? material;
  final String? shape;
  final String? imageUrl;
  const DripperMasterRow({
    required this.id,
    required this.name,
    this.material,
    this.shape,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || material != null) {
      map['material'] = Variable<String>(material);
    }
    if (!nullToAbsent || shape != null) {
      map['shape'] = Variable<String>(shape);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  DripperMasterTableCompanion toCompanion(bool nullToAbsent) {
    return DripperMasterTableCompanion(
      id: Value(id),
      name: Value(name),
      material: material == null && nullToAbsent
          ? const Value.absent()
          : Value(material),
      shape: shape == null && nullToAbsent
          ? const Value.absent()
          : Value(shape),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory DripperMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DripperMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      material: serializer.fromJson<String?>(json['material']),
      shape: serializer.fromJson<String?>(json['shape']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'material': serializer.toJson<String?>(material),
      'shape': serializer.toJson<String?>(shape),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  DripperMasterRow copyWith({
    String? id,
    String? name,
    Value<String?> material = const Value.absent(),
    Value<String?> shape = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => DripperMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    material: material.present ? material.value : this.material,
    shape: shape.present ? shape.value : this.shape,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  DripperMasterRow copyWithCompanion(DripperMasterTableCompanion data) {
    return DripperMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      material: data.material.present ? data.material.value : this.material,
      shape: data.shape.present ? data.shape.value : this.shape,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DripperMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('material: $material, ')
          ..write('shape: $shape, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, material, shape, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DripperMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.material == this.material &&
          other.shape == this.shape &&
          other.imageUrl == this.imageUrl);
}

class DripperMasterTableCompanion extends UpdateCompanion<DripperMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> material;
  final Value<String?> shape;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const DripperMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.material = const Value.absent(),
    this.shape = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DripperMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.material = const Value.absent(),
    this.shape = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<DripperMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? material,
    Expression<String>? shape,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (material != null) 'material': material,
      if (shape != null) 'shape': shape,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DripperMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? material,
    Value<String?>? shape,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return DripperMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      shape: shape ?? this.shape,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (material.present) {
      map['material'] = Variable<String>(material.value);
    }
    if (shape.present) {
      map['shape'] = Variable<String>(shape.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DripperMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('material: $material, ')
          ..write('shape: $shape, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilterMasterTableTable extends FilterMasterTable
    with TableInfo<$FilterMasterTableTable, FilterMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilterMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _materialMeta = const VerificationMeta(
    'material',
  );
  @override
  late final GeneratedColumn<String> material = GeneratedColumn<String>(
    'material',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, material, size, imageUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filter_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilterMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('material')) {
      context.handle(
        _materialMeta,
        material.isAcceptableOrUnknown(data['material']!, _materialMeta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilterMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilterMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      material: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}material'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $FilterMasterTableTable createAlias(String alias) {
    return $FilterMasterTableTable(attachedDatabase, alias);
  }
}

class FilterMasterRow extends DataClass implements Insertable<FilterMasterRow> {
  final String id;
  final String name;
  final String? material;
  final String? size;
  final String? imageUrl;
  const FilterMasterRow({
    required this.id,
    required this.name,
    this.material,
    this.size,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || material != null) {
      map['material'] = Variable<String>(material);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<String>(size);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  FilterMasterTableCompanion toCompanion(bool nullToAbsent) {
    return FilterMasterTableCompanion(
      id: Value(id),
      name: Value(name),
      material: material == null && nullToAbsent
          ? const Value.absent()
          : Value(material),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory FilterMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilterMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      material: serializer.fromJson<String?>(json['material']),
      size: serializer.fromJson<String?>(json['size']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'material': serializer.toJson<String?>(material),
      'size': serializer.toJson<String?>(size),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  FilterMasterRow copyWith({
    String? id,
    String? name,
    Value<String?> material = const Value.absent(),
    Value<String?> size = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => FilterMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    material: material.present ? material.value : this.material,
    size: size.present ? size.value : this.size,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  FilterMasterRow copyWithCompanion(FilterMasterTableCompanion data) {
    return FilterMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      material: data.material.present ? data.material.value : this.material,
      size: data.size.present ? data.size.value : this.size,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilterMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('material: $material, ')
          ..write('size: $size, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, material, size, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilterMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.material == this.material &&
          other.size == this.size &&
          other.imageUrl == this.imageUrl);
}

class FilterMasterTableCompanion extends UpdateCompanion<FilterMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> material;
  final Value<String?> size;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const FilterMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.material = const Value.absent(),
    this.size = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FilterMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.material = const Value.absent(),
    this.size = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<FilterMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? material,
    Expression<String>? size,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (material != null) 'material': material,
      if (size != null) 'size': size,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FilterMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? material,
    Value<String?>? size,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return FilterMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      material: material ?? this.material,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (material.present) {
      map['material'] = Variable<String>(material.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilterMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('material: $material, ')
          ..write('size: $size, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OriginMasterTableTable extends OriginMasterTable
    with TableInfo<$OriginMasterTableTable, OriginMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OriginMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameJaMeta = const VerificationMeta('nameJa');
  @override
  late final GeneratedColumn<String> nameJa = GeneratedColumn<String>(
    'name_ja',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
    'region',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    countryCode,
    nameJa,
    nameEn,
    region,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'origin_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<OriginMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('name_ja')) {
      context.handle(
        _nameJaMeta,
        nameJa.isAcceptableOrUnknown(data['name_ja']!, _nameJaMeta),
      );
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('region')) {
      context.handle(
        _regionMeta,
        region.isAcceptableOrUnknown(data['region']!, _regionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OriginMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OriginMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      nameJa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ja'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      region: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region'],
      )!,
    );
  }

  @override
  $OriginMasterTableTable createAlias(String alias) {
    return $OriginMasterTableTable(attachedDatabase, alias);
  }
}

class OriginMasterRow extends DataClass implements Insertable<OriginMasterRow> {
  final String id;
  final String countryCode;
  final String nameJa;
  final String nameEn;
  final String region;
  const OriginMasterRow({
    required this.id,
    required this.countryCode,
    required this.nameJa,
    required this.nameEn,
    required this.region,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['country_code'] = Variable<String>(countryCode);
    map['name_ja'] = Variable<String>(nameJa);
    map['name_en'] = Variable<String>(nameEn);
    map['region'] = Variable<String>(region);
    return map;
  }

  OriginMasterTableCompanion toCompanion(bool nullToAbsent) {
    return OriginMasterTableCompanion(
      id: Value(id),
      countryCode: Value(countryCode),
      nameJa: Value(nameJa),
      nameEn: Value(nameEn),
      region: Value(region),
    );
  }

  factory OriginMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OriginMasterRow(
      id: serializer.fromJson<String>(json['id']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      nameJa: serializer.fromJson<String>(json['nameJa']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      region: serializer.fromJson<String>(json['region']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'countryCode': serializer.toJson<String>(countryCode),
      'nameJa': serializer.toJson<String>(nameJa),
      'nameEn': serializer.toJson<String>(nameEn),
      'region': serializer.toJson<String>(region),
    };
  }

  OriginMasterRow copyWith({
    String? id,
    String? countryCode,
    String? nameJa,
    String? nameEn,
    String? region,
  }) => OriginMasterRow(
    id: id ?? this.id,
    countryCode: countryCode ?? this.countryCode,
    nameJa: nameJa ?? this.nameJa,
    nameEn: nameEn ?? this.nameEn,
    region: region ?? this.region,
  );
  OriginMasterRow copyWithCompanion(OriginMasterTableCompanion data) {
    return OriginMasterRow(
      id: data.id.present ? data.id.value : this.id,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      nameJa: data.nameJa.present ? data.nameJa.value : this.nameJa,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      region: data.region.present ? data.region.value : this.region,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OriginMasterRow(')
          ..write('id: $id, ')
          ..write('countryCode: $countryCode, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameEn: $nameEn, ')
          ..write('region: $region')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, countryCode, nameJa, nameEn, region);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OriginMasterRow &&
          other.id == this.id &&
          other.countryCode == this.countryCode &&
          other.nameJa == this.nameJa &&
          other.nameEn == this.nameEn &&
          other.region == this.region);
}

class OriginMasterTableCompanion extends UpdateCompanion<OriginMasterRow> {
  final Value<String> id;
  final Value<String> countryCode;
  final Value<String> nameJa;
  final Value<String> nameEn;
  final Value<String> region;
  final Value<int> rowid;
  const OriginMasterTableCompanion({
    this.id = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OriginMasterTableCompanion.insert({
    required String id,
    this.countryCode = const Value.absent(),
    this.nameJa = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.region = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<OriginMasterRow> custom({
    Expression<String>? id,
    Expression<String>? countryCode,
    Expression<String>? nameJa,
    Expression<String>? nameEn,
    Expression<String>? region,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (countryCode != null) 'country_code': countryCode,
      if (nameJa != null) 'name_ja': nameJa,
      if (nameEn != null) 'name_en': nameEn,
      if (region != null) 'region': region,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OriginMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? countryCode,
    Value<String>? nameJa,
    Value<String>? nameEn,
    Value<String>? region,
    Value<int>? rowid,
  }) {
    return OriginMasterTableCompanion(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      nameJa: nameJa ?? this.nameJa,
      nameEn: nameEn ?? this.nameEn,
      region: region ?? this.region,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (nameJa.present) {
      map['name_ja'] = Variable<String>(nameJa.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OriginMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('countryCode: $countryCode, ')
          ..write('nameJa: $nameJa, ')
          ..write('nameEn: $nameEn, ')
          ..write('region: $region, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoreMasterTableTable extends StoreMasterTable
    with TableInfo<$StoreMasterTableTable, StoreMasterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoreMasterTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('-'),
  );
  static const VerificationMeta _formalNameMeta = const VerificationMeta(
    'formalName',
  );
  @override
  late final GeneratedColumn<String> formalName = GeneratedColumn<String>(
    'formal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _prefectureMeta = const VerificationMeta(
    'prefecture',
  );
  @override
  late final GeneratedColumn<String> prefecture = GeneratedColumn<String>(
    'prefecture',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hasOnlineShopMeta = const VerificationMeta(
    'hasOnlineShop',
  );
  @override
  late final GeneratedColumn<bool> hasOnlineShop = GeneratedColumn<bool>(
    'has_online_shop',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_online_shop" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasPhysicalStoreMeta = const VerificationMeta(
    'hasPhysicalStore',
  );
  @override
  late final GeneratedColumn<bool> hasPhysicalStore = GeneratedColumn<bool>(
    'has_physical_store',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_physical_store" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasRoasteryMeta = const VerificationMeta(
    'hasRoastery',
  );
  @override
  late final GeneratedColumn<bool> hasRoastery = GeneratedColumn<bool>(
    'has_roastery',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_roastery" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _beanTendencyMeta = const VerificationMeta(
    'beanTendency',
  );
  @override
  late final GeneratedColumn<String> beanTendency = GeneratedColumn<String>(
    'bean_tendency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snsUrlMeta = const VerificationMeta('snsUrl');
  @override
  late final GeneratedColumn<String> snsUrl = GeneratedColumn<String>(
    'sns_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _businessHoursMeta = const VerificationMeta(
    'businessHours',
  );
  @override
  late final GeneratedColumn<String> businessHours = GeneratedColumn<String>(
    'business_hours',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _closedDaysMeta = const VerificationMeta(
    'closedDays',
  );
  @override
  late final GeneratedColumn<String> closedDays = GeneratedColumn<String>(
    'closed_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _openedYearMeta = const VerificationMeta(
    'openedYear',
  );
  @override
  late final GeneratedColumn<String> openedYear = GeneratedColumn<String>(
    'opened_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _infoFetchedAtMeta = const VerificationMeta(
    'infoFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> infoFetchedAt =
      GeneratedColumn<DateTime>(
        'info_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    formalName,
    url,
    prefecture,
    address,
    hasOnlineShop,
    hasPhysicalStore,
    hasRoastery,
    beanTendency,
    memo,
    imageUrl,
    snsUrl,
    businessHours,
    closedDays,
    phone,
    openedYear,
    sourceUrl,
    infoFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoreMasterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('formal_name')) {
      context.handle(
        _formalNameMeta,
        formalName.isAcceptableOrUnknown(data['formal_name']!, _formalNameMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('prefecture')) {
      context.handle(
        _prefectureMeta,
        prefecture.isAcceptableOrUnknown(data['prefecture']!, _prefectureMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('has_online_shop')) {
      context.handle(
        _hasOnlineShopMeta,
        hasOnlineShop.isAcceptableOrUnknown(
          data['has_online_shop']!,
          _hasOnlineShopMeta,
        ),
      );
    }
    if (data.containsKey('has_physical_store')) {
      context.handle(
        _hasPhysicalStoreMeta,
        hasPhysicalStore.isAcceptableOrUnknown(
          data['has_physical_store']!,
          _hasPhysicalStoreMeta,
        ),
      );
    }
    if (data.containsKey('has_roastery')) {
      context.handle(
        _hasRoasteryMeta,
        hasRoastery.isAcceptableOrUnknown(
          data['has_roastery']!,
          _hasRoasteryMeta,
        ),
      );
    }
    if (data.containsKey('bean_tendency')) {
      context.handle(
        _beanTendencyMeta,
        beanTendency.isAcceptableOrUnknown(
          data['bean_tendency']!,
          _beanTendencyMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('sns_url')) {
      context.handle(
        _snsUrlMeta,
        snsUrl.isAcceptableOrUnknown(data['sns_url']!, _snsUrlMeta),
      );
    }
    if (data.containsKey('business_hours')) {
      context.handle(
        _businessHoursMeta,
        businessHours.isAcceptableOrUnknown(
          data['business_hours']!,
          _businessHoursMeta,
        ),
      );
    }
    if (data.containsKey('closed_days')) {
      context.handle(
        _closedDaysMeta,
        closedDays.isAcceptableOrUnknown(data['closed_days']!, _closedDaysMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('opened_year')) {
      context.handle(
        _openedYearMeta,
        openedYear.isAcceptableOrUnknown(data['opened_year']!, _openedYearMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('info_fetched_at')) {
      context.handle(
        _infoFetchedAtMeta,
        infoFetchedAt.isAcceptableOrUnknown(
          data['info_fetched_at']!,
          _infoFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoreMasterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoreMasterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      formalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formal_name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      prefecture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefecture'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      hasOnlineShop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_online_shop'],
      )!,
      hasPhysicalStore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_physical_store'],
      )!,
      hasRoastery: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_roastery'],
      )!,
      beanTendency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_tendency'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      snsUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sns_url'],
      )!,
      businessHours: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_hours'],
      )!,
      closedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_days'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      openedYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opened_year'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      infoFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}info_fetched_at'],
      ),
    );
  }

  @override
  $StoreMasterTableTable createAlias(String alias) {
    return $StoreMasterTableTable(attachedDatabase, alias);
  }
}

class StoreMasterRow extends DataClass implements Insertable<StoreMasterRow> {
  final String id;
  final String name;
  final String formalName;
  final String url;
  final String prefecture;
  final String address;
  final bool hasOnlineShop;
  final bool hasPhysicalStore;
  final bool hasRoastery;
  final String beanTendency;
  final String memo;
  final String? imageUrl;
  final String snsUrl;
  final String businessHours;
  final String closedDays;
  final String phone;
  final String openedYear;
  final String sourceUrl;
  final DateTime? infoFetchedAt;
  const StoreMasterRow({
    required this.id,
    required this.name,
    required this.formalName,
    required this.url,
    required this.prefecture,
    required this.address,
    required this.hasOnlineShop,
    required this.hasPhysicalStore,
    required this.hasRoastery,
    required this.beanTendency,
    required this.memo,
    this.imageUrl,
    required this.snsUrl,
    required this.businessHours,
    required this.closedDays,
    required this.phone,
    required this.openedYear,
    required this.sourceUrl,
    this.infoFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['formal_name'] = Variable<String>(formalName);
    map['url'] = Variable<String>(url);
    map['prefecture'] = Variable<String>(prefecture);
    map['address'] = Variable<String>(address);
    map['has_online_shop'] = Variable<bool>(hasOnlineShop);
    map['has_physical_store'] = Variable<bool>(hasPhysicalStore);
    map['has_roastery'] = Variable<bool>(hasRoastery);
    map['bean_tendency'] = Variable<String>(beanTendency);
    map['memo'] = Variable<String>(memo);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['sns_url'] = Variable<String>(snsUrl);
    map['business_hours'] = Variable<String>(businessHours);
    map['closed_days'] = Variable<String>(closedDays);
    map['phone'] = Variable<String>(phone);
    map['opened_year'] = Variable<String>(openedYear);
    map['source_url'] = Variable<String>(sourceUrl);
    if (!nullToAbsent || infoFetchedAt != null) {
      map['info_fetched_at'] = Variable<DateTime>(infoFetchedAt);
    }
    return map;
  }

  StoreMasterTableCompanion toCompanion(bool nullToAbsent) {
    return StoreMasterTableCompanion(
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
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      snsUrl: Value(snsUrl),
      businessHours: Value(businessHours),
      closedDays: Value(closedDays),
      phone: Value(phone),
      openedYear: Value(openedYear),
      sourceUrl: Value(sourceUrl),
      infoFetchedAt: infoFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(infoFetchedAt),
    );
  }

  factory StoreMasterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoreMasterRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      formalName: serializer.fromJson<String>(json['formalName']),
      url: serializer.fromJson<String>(json['url']),
      prefecture: serializer.fromJson<String>(json['prefecture']),
      address: serializer.fromJson<String>(json['address']),
      hasOnlineShop: serializer.fromJson<bool>(json['hasOnlineShop']),
      hasPhysicalStore: serializer.fromJson<bool>(json['hasPhysicalStore']),
      hasRoastery: serializer.fromJson<bool>(json['hasRoastery']),
      beanTendency: serializer.fromJson<String>(json['beanTendency']),
      memo: serializer.fromJson<String>(json['memo']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      snsUrl: serializer.fromJson<String>(json['snsUrl']),
      businessHours: serializer.fromJson<String>(json['businessHours']),
      closedDays: serializer.fromJson<String>(json['closedDays']),
      phone: serializer.fromJson<String>(json['phone']),
      openedYear: serializer.fromJson<String>(json['openedYear']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      infoFetchedAt: serializer.fromJson<DateTime?>(json['infoFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'formalName': serializer.toJson<String>(formalName),
      'url': serializer.toJson<String>(url),
      'prefecture': serializer.toJson<String>(prefecture),
      'address': serializer.toJson<String>(address),
      'hasOnlineShop': serializer.toJson<bool>(hasOnlineShop),
      'hasPhysicalStore': serializer.toJson<bool>(hasPhysicalStore),
      'hasRoastery': serializer.toJson<bool>(hasRoastery),
      'beanTendency': serializer.toJson<String>(beanTendency),
      'memo': serializer.toJson<String>(memo),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'snsUrl': serializer.toJson<String>(snsUrl),
      'businessHours': serializer.toJson<String>(businessHours),
      'closedDays': serializer.toJson<String>(closedDays),
      'phone': serializer.toJson<String>(phone),
      'openedYear': serializer.toJson<String>(openedYear),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'infoFetchedAt': serializer.toJson<DateTime?>(infoFetchedAt),
    };
  }

  StoreMasterRow copyWith({
    String? id,
    String? name,
    String? formalName,
    String? url,
    String? prefecture,
    String? address,
    bool? hasOnlineShop,
    bool? hasPhysicalStore,
    bool? hasRoastery,
    String? beanTendency,
    String? memo,
    Value<String?> imageUrl = const Value.absent(),
    String? snsUrl,
    String? businessHours,
    String? closedDays,
    String? phone,
    String? openedYear,
    String? sourceUrl,
    Value<DateTime?> infoFetchedAt = const Value.absent(),
  }) => StoreMasterRow(
    id: id ?? this.id,
    name: name ?? this.name,
    formalName: formalName ?? this.formalName,
    url: url ?? this.url,
    prefecture: prefecture ?? this.prefecture,
    address: address ?? this.address,
    hasOnlineShop: hasOnlineShop ?? this.hasOnlineShop,
    hasPhysicalStore: hasPhysicalStore ?? this.hasPhysicalStore,
    hasRoastery: hasRoastery ?? this.hasRoastery,
    beanTendency: beanTendency ?? this.beanTendency,
    memo: memo ?? this.memo,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    snsUrl: snsUrl ?? this.snsUrl,
    businessHours: businessHours ?? this.businessHours,
    closedDays: closedDays ?? this.closedDays,
    phone: phone ?? this.phone,
    openedYear: openedYear ?? this.openedYear,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    infoFetchedAt: infoFetchedAt.present
        ? infoFetchedAt.value
        : this.infoFetchedAt,
  );
  StoreMasterRow copyWithCompanion(StoreMasterTableCompanion data) {
    return StoreMasterRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      formalName: data.formalName.present
          ? data.formalName.value
          : this.formalName,
      url: data.url.present ? data.url.value : this.url,
      prefecture: data.prefecture.present
          ? data.prefecture.value
          : this.prefecture,
      address: data.address.present ? data.address.value : this.address,
      hasOnlineShop: data.hasOnlineShop.present
          ? data.hasOnlineShop.value
          : this.hasOnlineShop,
      hasPhysicalStore: data.hasPhysicalStore.present
          ? data.hasPhysicalStore.value
          : this.hasPhysicalStore,
      hasRoastery: data.hasRoastery.present
          ? data.hasRoastery.value
          : this.hasRoastery,
      beanTendency: data.beanTendency.present
          ? data.beanTendency.value
          : this.beanTendency,
      memo: data.memo.present ? data.memo.value : this.memo,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      snsUrl: data.snsUrl.present ? data.snsUrl.value : this.snsUrl,
      businessHours: data.businessHours.present
          ? data.businessHours.value
          : this.businessHours,
      closedDays: data.closedDays.present
          ? data.closedDays.value
          : this.closedDays,
      phone: data.phone.present ? data.phone.value : this.phone,
      openedYear: data.openedYear.present
          ? data.openedYear.value
          : this.openedYear,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      infoFetchedAt: data.infoFetchedAt.present
          ? data.infoFetchedAt.value
          : this.infoFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoreMasterRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('formalName: $formalName, ')
          ..write('url: $url, ')
          ..write('prefecture: $prefecture, ')
          ..write('address: $address, ')
          ..write('hasOnlineShop: $hasOnlineShop, ')
          ..write('hasPhysicalStore: $hasPhysicalStore, ')
          ..write('hasRoastery: $hasRoastery, ')
          ..write('beanTendency: $beanTendency, ')
          ..write('memo: $memo, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('snsUrl: $snsUrl, ')
          ..write('businessHours: $businessHours, ')
          ..write('closedDays: $closedDays, ')
          ..write('phone: $phone, ')
          ..write('openedYear: $openedYear, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('infoFetchedAt: $infoFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    formalName,
    url,
    prefecture,
    address,
    hasOnlineShop,
    hasPhysicalStore,
    hasRoastery,
    beanTendency,
    memo,
    imageUrl,
    snsUrl,
    businessHours,
    closedDays,
    phone,
    openedYear,
    sourceUrl,
    infoFetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreMasterRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.formalName == this.formalName &&
          other.url == this.url &&
          other.prefecture == this.prefecture &&
          other.address == this.address &&
          other.hasOnlineShop == this.hasOnlineShop &&
          other.hasPhysicalStore == this.hasPhysicalStore &&
          other.hasRoastery == this.hasRoastery &&
          other.beanTendency == this.beanTendency &&
          other.memo == this.memo &&
          other.imageUrl == this.imageUrl &&
          other.snsUrl == this.snsUrl &&
          other.businessHours == this.businessHours &&
          other.closedDays == this.closedDays &&
          other.phone == this.phone &&
          other.openedYear == this.openedYear &&
          other.sourceUrl == this.sourceUrl &&
          other.infoFetchedAt == this.infoFetchedAt);
}

class StoreMasterTableCompanion extends UpdateCompanion<StoreMasterRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> formalName;
  final Value<String> url;
  final Value<String> prefecture;
  final Value<String> address;
  final Value<bool> hasOnlineShop;
  final Value<bool> hasPhysicalStore;
  final Value<bool> hasRoastery;
  final Value<String> beanTendency;
  final Value<String> memo;
  final Value<String?> imageUrl;
  final Value<String> snsUrl;
  final Value<String> businessHours;
  final Value<String> closedDays;
  final Value<String> phone;
  final Value<String> openedYear;
  final Value<String> sourceUrl;
  final Value<DateTime?> infoFetchedAt;
  final Value<int> rowid;
  const StoreMasterTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.formalName = const Value.absent(),
    this.url = const Value.absent(),
    this.prefecture = const Value.absent(),
    this.address = const Value.absent(),
    this.hasOnlineShop = const Value.absent(),
    this.hasPhysicalStore = const Value.absent(),
    this.hasRoastery = const Value.absent(),
    this.beanTendency = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.snsUrl = const Value.absent(),
    this.businessHours = const Value.absent(),
    this.closedDays = const Value.absent(),
    this.phone = const Value.absent(),
    this.openedYear = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.infoFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoreMasterTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.formalName = const Value.absent(),
    this.url = const Value.absent(),
    this.prefecture = const Value.absent(),
    this.address = const Value.absent(),
    this.hasOnlineShop = const Value.absent(),
    this.hasPhysicalStore = const Value.absent(),
    this.hasRoastery = const Value.absent(),
    this.beanTendency = const Value.absent(),
    this.memo = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.snsUrl = const Value.absent(),
    this.businessHours = const Value.absent(),
    this.closedDays = const Value.absent(),
    this.phone = const Value.absent(),
    this.openedYear = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.infoFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<StoreMasterRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? formalName,
    Expression<String>? url,
    Expression<String>? prefecture,
    Expression<String>? address,
    Expression<bool>? hasOnlineShop,
    Expression<bool>? hasPhysicalStore,
    Expression<bool>? hasRoastery,
    Expression<String>? beanTendency,
    Expression<String>? memo,
    Expression<String>? imageUrl,
    Expression<String>? snsUrl,
    Expression<String>? businessHours,
    Expression<String>? closedDays,
    Expression<String>? phone,
    Expression<String>? openedYear,
    Expression<String>? sourceUrl,
    Expression<DateTime>? infoFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (formalName != null) 'formal_name': formalName,
      if (url != null) 'url': url,
      if (prefecture != null) 'prefecture': prefecture,
      if (address != null) 'address': address,
      if (hasOnlineShop != null) 'has_online_shop': hasOnlineShop,
      if (hasPhysicalStore != null) 'has_physical_store': hasPhysicalStore,
      if (hasRoastery != null) 'has_roastery': hasRoastery,
      if (beanTendency != null) 'bean_tendency': beanTendency,
      if (memo != null) 'memo': memo,
      if (imageUrl != null) 'image_url': imageUrl,
      if (snsUrl != null) 'sns_url': snsUrl,
      if (businessHours != null) 'business_hours': businessHours,
      if (closedDays != null) 'closed_days': closedDays,
      if (phone != null) 'phone': phone,
      if (openedYear != null) 'opened_year': openedYear,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (infoFetchedAt != null) 'info_fetched_at': infoFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoreMasterTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? formalName,
    Value<String>? url,
    Value<String>? prefecture,
    Value<String>? address,
    Value<bool>? hasOnlineShop,
    Value<bool>? hasPhysicalStore,
    Value<bool>? hasRoastery,
    Value<String>? beanTendency,
    Value<String>? memo,
    Value<String?>? imageUrl,
    Value<String>? snsUrl,
    Value<String>? businessHours,
    Value<String>? closedDays,
    Value<String>? phone,
    Value<String>? openedYear,
    Value<String>? sourceUrl,
    Value<DateTime?>? infoFetchedAt,
    Value<int>? rowid,
  }) {
    return StoreMasterTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      formalName: formalName ?? this.formalName,
      url: url ?? this.url,
      prefecture: prefecture ?? this.prefecture,
      address: address ?? this.address,
      hasOnlineShop: hasOnlineShop ?? this.hasOnlineShop,
      hasPhysicalStore: hasPhysicalStore ?? this.hasPhysicalStore,
      hasRoastery: hasRoastery ?? this.hasRoastery,
      beanTendency: beanTendency ?? this.beanTendency,
      memo: memo ?? this.memo,
      imageUrl: imageUrl ?? this.imageUrl,
      snsUrl: snsUrl ?? this.snsUrl,
      businessHours: businessHours ?? this.businessHours,
      closedDays: closedDays ?? this.closedDays,
      phone: phone ?? this.phone,
      openedYear: openedYear ?? this.openedYear,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      infoFetchedAt: infoFetchedAt ?? this.infoFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (formalName.present) {
      map['formal_name'] = Variable<String>(formalName.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (prefecture.present) {
      map['prefecture'] = Variable<String>(prefecture.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (hasOnlineShop.present) {
      map['has_online_shop'] = Variable<bool>(hasOnlineShop.value);
    }
    if (hasPhysicalStore.present) {
      map['has_physical_store'] = Variable<bool>(hasPhysicalStore.value);
    }
    if (hasRoastery.present) {
      map['has_roastery'] = Variable<bool>(hasRoastery.value);
    }
    if (beanTendency.present) {
      map['bean_tendency'] = Variable<String>(beanTendency.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (snsUrl.present) {
      map['sns_url'] = Variable<String>(snsUrl.value);
    }
    if (businessHours.present) {
      map['business_hours'] = Variable<String>(businessHours.value);
    }
    if (closedDays.present) {
      map['closed_days'] = Variable<String>(closedDays.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (openedYear.present) {
      map['opened_year'] = Variable<String>(openedYear.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (infoFetchedAt.present) {
      map['info_fetched_at'] = Variable<DateTime>(infoFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoreMasterTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('formalName: $formalName, ')
          ..write('url: $url, ')
          ..write('prefecture: $prefecture, ')
          ..write('address: $address, ')
          ..write('hasOnlineShop: $hasOnlineShop, ')
          ..write('hasPhysicalStore: $hasPhysicalStore, ')
          ..write('hasRoastery: $hasRoastery, ')
          ..write('beanTendency: $beanTendency, ')
          ..write('memo: $memo, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('snsUrl: $snsUrl, ')
          ..write('businessHours: $businessHours, ')
          ..write('closedDays: $closedDays, ')
          ..write('phone: $phone, ')
          ..write('openedYear: $openedYear, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('infoFetchedAt: $infoFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BeanPurchasesTableTable extends BeanPurchasesTable
    with TableInfo<$BeanPurchasesTableTable, BeanPurchaseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeanPurchasesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<String> beanId = GeneratedColumn<String>(
    'bean_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
    'purchased_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roastDateMeta = const VerificationMeta(
    'roastDate',
  );
  @override
  late final GeneratedColumn<DateTime> roastDate = GeneratedColumn<DateTime>(
    'roast_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityGramsMeta = const VerificationMeta(
    'quantityGrams',
  );
  @override
  late final GeneratedColumn<double> quantityGrams = GeneratedColumn<double>(
    'quantity_grams',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    beanId,
    purchasedAt,
    roastDate,
    quantityGrams,
    storeId,
    storeName,
    memo,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bean_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeanPurchaseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    }
    if (data.containsKey('roast_date')) {
      context.handle(
        _roastDateMeta,
        roastDate.isAcceptableOrUnknown(data['roast_date']!, _roastDateMeta),
      );
    }
    if (data.containsKey('quantity_grams')) {
      context.handle(
        _quantityGramsMeta,
        quantityGrams.isAcceptableOrUnknown(
          data['quantity_grams']!,
          _quantityGramsMeta,
        ),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeanPurchaseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeanPurchaseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_id'],
      )!,
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchased_at'],
      ),
      roastDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}roast_date'],
      ),
      quantityGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_grams'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $BeanPurchasesTableTable createAlias(String alias) {
    return $BeanPurchasesTableTable(attachedDatabase, alias);
  }
}

class BeanPurchaseRow extends DataClass implements Insertable<BeanPurchaseRow> {
  final String id;
  final String beanId;
  final DateTime? purchasedAt;
  final DateTime? roastDate;
  final double? quantityGrams;
  final String storeId;
  final String storeName;
  final String memo;
  final DateTime? createdAt;
  const BeanPurchaseRow({
    required this.id,
    required this.beanId,
    this.purchasedAt,
    this.roastDate,
    this.quantityGrams,
    required this.storeId,
    required this.storeName,
    required this.memo,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bean_id'] = Variable<String>(beanId);
    if (!nullToAbsent || purchasedAt != null) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt);
    }
    if (!nullToAbsent || roastDate != null) {
      map['roast_date'] = Variable<DateTime>(roastDate);
    }
    if (!nullToAbsent || quantityGrams != null) {
      map['quantity_grams'] = Variable<double>(quantityGrams);
    }
    map['store_id'] = Variable<String>(storeId);
    map['store_name'] = Variable<String>(storeName);
    map['memo'] = Variable<String>(memo);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  BeanPurchasesTableCompanion toCompanion(bool nullToAbsent) {
    return BeanPurchasesTableCompanion(
      id: Value(id),
      beanId: Value(beanId),
      purchasedAt: purchasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasedAt),
      roastDate: roastDate == null && nullToAbsent
          ? const Value.absent()
          : Value(roastDate),
      quantityGrams: quantityGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityGrams),
      storeId: Value(storeId),
      storeName: Value(storeName),
      memo: Value(memo),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory BeanPurchaseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeanPurchaseRow(
      id: serializer.fromJson<String>(json['id']),
      beanId: serializer.fromJson<String>(json['beanId']),
      purchasedAt: serializer.fromJson<DateTime?>(json['purchasedAt']),
      roastDate: serializer.fromJson<DateTime?>(json['roastDate']),
      quantityGrams: serializer.fromJson<double?>(json['quantityGrams']),
      storeId: serializer.fromJson<String>(json['storeId']),
      storeName: serializer.fromJson<String>(json['storeName']),
      memo: serializer.fromJson<String>(json['memo']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'beanId': serializer.toJson<String>(beanId),
      'purchasedAt': serializer.toJson<DateTime?>(purchasedAt),
      'roastDate': serializer.toJson<DateTime?>(roastDate),
      'quantityGrams': serializer.toJson<double?>(quantityGrams),
      'storeId': serializer.toJson<String>(storeId),
      'storeName': serializer.toJson<String>(storeName),
      'memo': serializer.toJson<String>(memo),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  BeanPurchaseRow copyWith({
    String? id,
    String? beanId,
    Value<DateTime?> purchasedAt = const Value.absent(),
    Value<DateTime?> roastDate = const Value.absent(),
    Value<double?> quantityGrams = const Value.absent(),
    String? storeId,
    String? storeName,
    String? memo,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => BeanPurchaseRow(
    id: id ?? this.id,
    beanId: beanId ?? this.beanId,
    purchasedAt: purchasedAt.present ? purchasedAt.value : this.purchasedAt,
    roastDate: roastDate.present ? roastDate.value : this.roastDate,
    quantityGrams: quantityGrams.present
        ? quantityGrams.value
        : this.quantityGrams,
    storeId: storeId ?? this.storeId,
    storeName: storeName ?? this.storeName,
    memo: memo ?? this.memo,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  BeanPurchaseRow copyWithCompanion(BeanPurchasesTableCompanion data) {
    return BeanPurchaseRow(
      id: data.id.present ? data.id.value : this.id,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      roastDate: data.roastDate.present ? data.roastDate.value : this.roastDate,
      quantityGrams: data.quantityGrams.present
          ? data.quantityGrams.value
          : this.quantityGrams,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeanPurchaseRow(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('roastDate: $roastDate, ')
          ..write('quantityGrams: $quantityGrams, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    beanId,
    purchasedAt,
    roastDate,
    quantityGrams,
    storeId,
    storeName,
    memo,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeanPurchaseRow &&
          other.id == this.id &&
          other.beanId == this.beanId &&
          other.purchasedAt == this.purchasedAt &&
          other.roastDate == this.roastDate &&
          other.quantityGrams == this.quantityGrams &&
          other.storeId == this.storeId &&
          other.storeName == this.storeName &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt);
}

class BeanPurchasesTableCompanion extends UpdateCompanion<BeanPurchaseRow> {
  final Value<String> id;
  final Value<String> beanId;
  final Value<DateTime?> purchasedAt;
  final Value<DateTime?> roastDate;
  final Value<double?> quantityGrams;
  final Value<String> storeId;
  final Value<String> storeName;
  final Value<String> memo;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const BeanPurchasesTableCompanion({
    this.id = const Value.absent(),
    this.beanId = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.quantityGrams = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BeanPurchasesTableCompanion.insert({
    required String id,
    this.beanId = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.roastDate = const Value.absent(),
    this.quantityGrams = const Value.absent(),
    this.storeId = const Value.absent(),
    this.storeName = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BeanPurchaseRow> custom({
    Expression<String>? id,
    Expression<String>? beanId,
    Expression<DateTime>? purchasedAt,
    Expression<DateTime>? roastDate,
    Expression<double>? quantityGrams,
    Expression<String>? storeId,
    Expression<String>? storeName,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (beanId != null) 'bean_id': beanId,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (roastDate != null) 'roast_date': roastDate,
      if (quantityGrams != null) 'quantity_grams': quantityGrams,
      if (storeId != null) 'store_id': storeId,
      if (storeName != null) 'store_name': storeName,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BeanPurchasesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? beanId,
    Value<DateTime?>? purchasedAt,
    Value<DateTime?>? roastDate,
    Value<double?>? quantityGrams,
    Value<String>? storeId,
    Value<String>? storeName,
    Value<String>? memo,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return BeanPurchasesTableCompanion(
      id: id ?? this.id,
      beanId: beanId ?? this.beanId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      roastDate: roastDate ?? this.roastDate,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<String>(beanId.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (roastDate.present) {
      map['roast_date'] = Variable<DateTime>(roastDate.value);
    }
    if (quantityGrams.present) {
      map['quantity_grams'] = Variable<double>(quantityGrams.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeanPurchasesTableCompanion(')
          ..write('id: $id, ')
          ..write('beanId: $beanId, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('roastDate: $roastDate, ')
          ..write('quantityGrams: $quantityGrams, ')
          ..write('storeId: $storeId, ')
          ..write('storeName: $storeName, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysisHistoryTableTable extends AnalysisHistoryTable
    with TableInfo<$AnalysisHistoryTableTable, AnalysisHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dataCountMeta = const VerificationMeta(
    'dataCount',
  );
  @override
  late final GeneratedColumn<int> dataCount = GeneratedColumn<int>(
    'data_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    type,
    dataCount,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalysisHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('data_count')) {
      context.handle(
        _dataCountMeta,
        dataCount.isAcceptableOrUnknown(data['data_count']!, _dataCountMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      dataCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_count'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $AnalysisHistoryTableTable createAlias(String alias) {
    return $AnalysisHistoryTableTable(attachedDatabase, alias);
  }
}

class AnalysisHistoryRow extends DataClass
    implements Insertable<AnalysisHistoryRow> {
  final String id;
  final DateTime createdAt;
  final String type;
  final int dataCount;
  final String payloadJson;
  const AnalysisHistoryRow({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.dataCount,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<String>(type);
    map['data_count'] = Variable<int>(dataCount);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  AnalysisHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return AnalysisHistoryTableCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      type: Value(type),
      dataCount: Value(dataCount),
      payloadJson: Value(payloadJson),
    );
  }

  factory AnalysisHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<String>(json['type']),
      dataCount: serializer.fromJson<int>(json['dataCount']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<String>(type),
      'dataCount': serializer.toJson<int>(dataCount),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  AnalysisHistoryRow copyWith({
    String? id,
    DateTime? createdAt,
    String? type,
    int? dataCount,
    String? payloadJson,
  }) => AnalysisHistoryRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    dataCount: dataCount ?? this.dataCount,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  AnalysisHistoryRow copyWithCompanion(AnalysisHistoryTableCompanion data) {
    return AnalysisHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      dataCount: data.dataCount.present ? data.dataCount.value : this.dataCount,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisHistoryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('dataCount: $dataCount, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, type, dataCount, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisHistoryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.dataCount == this.dataCount &&
          other.payloadJson == this.payloadJson);
}

class AnalysisHistoryTableCompanion
    extends UpdateCompanion<AnalysisHistoryRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> type;
  final Value<int> dataCount;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const AnalysisHistoryTableCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.dataCount = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisHistoryTableCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.type = const Value.absent(),
    this.dataCount = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<AnalysisHistoryRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? type,
    Expression<int>? dataCount,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (dataCount != null) 'data_count': dataCount,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisHistoryTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? type,
    Value<int>? dataCount,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return AnalysisHistoryTableCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      dataCount: dataCount ?? this.dataCount,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (dataCount.present) {
      map['data_count'] = Variable<int>(dataCount.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('dataCount: $dataCount, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeSuggestionsTableTable extends RecipeSuggestionsTable
    with TableInfo<$RecipeSuggestionsTableTable, RecipeSuggestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeSuggestionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beanIdMeta = const VerificationMeta('beanId');
  @override
  late final GeneratedColumn<String> beanId = GeneratedColumn<String>(
    'bean_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originIdMeta = const VerificationMeta(
    'originId',
  );
  @override
  late final GeneratedColumn<String> originId = GeneratedColumn<String>(
    'origin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _roastLevelMeta = const VerificationMeta(
    'roastLevel',
  );
  @override
  late final GeneratedColumn<String> roastLevel = GeneratedColumn<String>(
    'roast_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _methodIdMeta = const VerificationMeta(
    'methodId',
  );
  @override
  late final GeneratedColumn<String> methodId = GeneratedColumn<String>(
    'method_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _brewRatioMeta = const VerificationMeta(
    'brewRatio',
  );
  @override
  late final GeneratedColumn<double> brewRatio = GeneratedColumn<double>(
    'brew_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalTimeSecMeta = const VerificationMeta(
    'totalTimeSec',
  );
  @override
  late final GeneratedColumn<int> totalTimeSec = GeneratedColumn<int>(
    'total_time_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rationaleMeta = const VerificationMeta(
    'rationale',
  );
  @override
  late final GeneratedColumn<String> rationale = GeneratedColumn<String>(
    'rationale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _acceptedMeta = const VerificationMeta(
    'accepted',
  );
  @override
  late final GeneratedColumn<String> accepted = GeneratedColumn<String>(
    'accepted',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _resultRecordIdMeta = const VerificationMeta(
    'resultRecordId',
  );
  @override
  late final GeneratedColumn<String> resultRecordId = GeneratedColumn<String>(
    'result_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    beanId,
    originId,
    roastLevel,
    methodId,
    temperature,
    brewRatio,
    totalTimeSec,
    rationale,
    accepted,
    resultRecordId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_suggestions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeSuggestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('bean_id')) {
      context.handle(
        _beanIdMeta,
        beanId.isAcceptableOrUnknown(data['bean_id']!, _beanIdMeta),
      );
    }
    if (data.containsKey('origin_id')) {
      context.handle(
        _originIdMeta,
        originId.isAcceptableOrUnknown(data['origin_id']!, _originIdMeta),
      );
    }
    if (data.containsKey('roast_level')) {
      context.handle(
        _roastLevelMeta,
        roastLevel.isAcceptableOrUnknown(data['roast_level']!, _roastLevelMeta),
      );
    }
    if (data.containsKey('method_id')) {
      context.handle(
        _methodIdMeta,
        methodId.isAcceptableOrUnknown(data['method_id']!, _methodIdMeta),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('brew_ratio')) {
      context.handle(
        _brewRatioMeta,
        brewRatio.isAcceptableOrUnknown(data['brew_ratio']!, _brewRatioMeta),
      );
    }
    if (data.containsKey('total_time_sec')) {
      context.handle(
        _totalTimeSecMeta,
        totalTimeSec.isAcceptableOrUnknown(
          data['total_time_sec']!,
          _totalTimeSecMeta,
        ),
      );
    }
    if (data.containsKey('rationale')) {
      context.handle(
        _rationaleMeta,
        rationale.isAcceptableOrUnknown(data['rationale']!, _rationaleMeta),
      );
    }
    if (data.containsKey('accepted')) {
      context.handle(
        _acceptedMeta,
        accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta),
      );
    }
    if (data.containsKey('result_record_id')) {
      context.handle(
        _resultRecordIdMeta,
        resultRecordId.isAcceptableOrUnknown(
          data['result_record_id']!,
          _resultRecordIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeSuggestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeSuggestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      beanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bean_id'],
      )!,
      originId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_id'],
      )!,
      roastLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roast_level'],
      )!,
      methodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method_id'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      brewRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}brew_ratio'],
      )!,
      totalTimeSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_time_sec'],
      )!,
      rationale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rationale'],
      )!,
      accepted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted'],
      )!,
      resultRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_record_id'],
      )!,
    );
  }

  @override
  $RecipeSuggestionsTableTable createAlias(String alias) {
    return $RecipeSuggestionsTableTable(attachedDatabase, alias);
  }
}

class RecipeSuggestionRow extends DataClass
    implements Insertable<RecipeSuggestionRow> {
  final String id;
  final DateTime createdAt;
  final String beanId;
  final String originId;
  final String roastLevel;
  final String methodId;
  final double temperature;
  final double brewRatio;
  final int totalTimeSec;
  final String rationale;
  final String accepted;
  final String resultRecordId;
  const RecipeSuggestionRow({
    required this.id,
    required this.createdAt,
    required this.beanId,
    required this.originId,
    required this.roastLevel,
    required this.methodId,
    required this.temperature,
    required this.brewRatio,
    required this.totalTimeSec,
    required this.rationale,
    required this.accepted,
    required this.resultRecordId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['bean_id'] = Variable<String>(beanId);
    map['origin_id'] = Variable<String>(originId);
    map['roast_level'] = Variable<String>(roastLevel);
    map['method_id'] = Variable<String>(methodId);
    map['temperature'] = Variable<double>(temperature);
    map['brew_ratio'] = Variable<double>(brewRatio);
    map['total_time_sec'] = Variable<int>(totalTimeSec);
    map['rationale'] = Variable<String>(rationale);
    map['accepted'] = Variable<String>(accepted);
    map['result_record_id'] = Variable<String>(resultRecordId);
    return map;
  }

  RecipeSuggestionsTableCompanion toCompanion(bool nullToAbsent) {
    return RecipeSuggestionsTableCompanion(
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

  factory RecipeSuggestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeSuggestionRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      beanId: serializer.fromJson<String>(json['beanId']),
      originId: serializer.fromJson<String>(json['originId']),
      roastLevel: serializer.fromJson<String>(json['roastLevel']),
      methodId: serializer.fromJson<String>(json['methodId']),
      temperature: serializer.fromJson<double>(json['temperature']),
      brewRatio: serializer.fromJson<double>(json['brewRatio']),
      totalTimeSec: serializer.fromJson<int>(json['totalTimeSec']),
      rationale: serializer.fromJson<String>(json['rationale']),
      accepted: serializer.fromJson<String>(json['accepted']),
      resultRecordId: serializer.fromJson<String>(json['resultRecordId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'beanId': serializer.toJson<String>(beanId),
      'originId': serializer.toJson<String>(originId),
      'roastLevel': serializer.toJson<String>(roastLevel),
      'methodId': serializer.toJson<String>(methodId),
      'temperature': serializer.toJson<double>(temperature),
      'brewRatio': serializer.toJson<double>(brewRatio),
      'totalTimeSec': serializer.toJson<int>(totalTimeSec),
      'rationale': serializer.toJson<String>(rationale),
      'accepted': serializer.toJson<String>(accepted),
      'resultRecordId': serializer.toJson<String>(resultRecordId),
    };
  }

  RecipeSuggestionRow copyWith({
    String? id,
    DateTime? createdAt,
    String? beanId,
    String? originId,
    String? roastLevel,
    String? methodId,
    double? temperature,
    double? brewRatio,
    int? totalTimeSec,
    String? rationale,
    String? accepted,
    String? resultRecordId,
  }) => RecipeSuggestionRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    beanId: beanId ?? this.beanId,
    originId: originId ?? this.originId,
    roastLevel: roastLevel ?? this.roastLevel,
    methodId: methodId ?? this.methodId,
    temperature: temperature ?? this.temperature,
    brewRatio: brewRatio ?? this.brewRatio,
    totalTimeSec: totalTimeSec ?? this.totalTimeSec,
    rationale: rationale ?? this.rationale,
    accepted: accepted ?? this.accepted,
    resultRecordId: resultRecordId ?? this.resultRecordId,
  );
  RecipeSuggestionRow copyWithCompanion(RecipeSuggestionsTableCompanion data) {
    return RecipeSuggestionRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      beanId: data.beanId.present ? data.beanId.value : this.beanId,
      originId: data.originId.present ? data.originId.value : this.originId,
      roastLevel: data.roastLevel.present
          ? data.roastLevel.value
          : this.roastLevel,
      methodId: data.methodId.present ? data.methodId.value : this.methodId,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      brewRatio: data.brewRatio.present ? data.brewRatio.value : this.brewRatio,
      totalTimeSec: data.totalTimeSec.present
          ? data.totalTimeSec.value
          : this.totalTimeSec,
      rationale: data.rationale.present ? data.rationale.value : this.rationale,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      resultRecordId: data.resultRecordId.present
          ? data.resultRecordId.value
          : this.resultRecordId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSuggestionRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('beanId: $beanId, ')
          ..write('originId: $originId, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('methodId: $methodId, ')
          ..write('temperature: $temperature, ')
          ..write('brewRatio: $brewRatio, ')
          ..write('totalTimeSec: $totalTimeSec, ')
          ..write('rationale: $rationale, ')
          ..write('accepted: $accepted, ')
          ..write('resultRecordId: $resultRecordId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    beanId,
    originId,
    roastLevel,
    methodId,
    temperature,
    brewRatio,
    totalTimeSec,
    rationale,
    accepted,
    resultRecordId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeSuggestionRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.beanId == this.beanId &&
          other.originId == this.originId &&
          other.roastLevel == this.roastLevel &&
          other.methodId == this.methodId &&
          other.temperature == this.temperature &&
          other.brewRatio == this.brewRatio &&
          other.totalTimeSec == this.totalTimeSec &&
          other.rationale == this.rationale &&
          other.accepted == this.accepted &&
          other.resultRecordId == this.resultRecordId);
}

class RecipeSuggestionsTableCompanion
    extends UpdateCompanion<RecipeSuggestionRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<String> beanId;
  final Value<String> originId;
  final Value<String> roastLevel;
  final Value<String> methodId;
  final Value<double> temperature;
  final Value<double> brewRatio;
  final Value<int> totalTimeSec;
  final Value<String> rationale;
  final Value<String> accepted;
  final Value<String> resultRecordId;
  final Value<int> rowid;
  const RecipeSuggestionsTableCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.beanId = const Value.absent(),
    this.originId = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.methodId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.brewRatio = const Value.absent(),
    this.totalTimeSec = const Value.absent(),
    this.rationale = const Value.absent(),
    this.accepted = const Value.absent(),
    this.resultRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeSuggestionsTableCompanion.insert({
    required String id,
    required DateTime createdAt,
    this.beanId = const Value.absent(),
    this.originId = const Value.absent(),
    this.roastLevel = const Value.absent(),
    this.methodId = const Value.absent(),
    this.temperature = const Value.absent(),
    this.brewRatio = const Value.absent(),
    this.totalTimeSec = const Value.absent(),
    this.rationale = const Value.absent(),
    this.accepted = const Value.absent(),
    this.resultRecordId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt);
  static Insertable<RecipeSuggestionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? beanId,
    Expression<String>? originId,
    Expression<String>? roastLevel,
    Expression<String>? methodId,
    Expression<double>? temperature,
    Expression<double>? brewRatio,
    Expression<int>? totalTimeSec,
    Expression<String>? rationale,
    Expression<String>? accepted,
    Expression<String>? resultRecordId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (beanId != null) 'bean_id': beanId,
      if (originId != null) 'origin_id': originId,
      if (roastLevel != null) 'roast_level': roastLevel,
      if (methodId != null) 'method_id': methodId,
      if (temperature != null) 'temperature': temperature,
      if (brewRatio != null) 'brew_ratio': brewRatio,
      if (totalTimeSec != null) 'total_time_sec': totalTimeSec,
      if (rationale != null) 'rationale': rationale,
      if (accepted != null) 'accepted': accepted,
      if (resultRecordId != null) 'result_record_id': resultRecordId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeSuggestionsTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<String>? beanId,
    Value<String>? originId,
    Value<String>? roastLevel,
    Value<String>? methodId,
    Value<double>? temperature,
    Value<double>? brewRatio,
    Value<int>? totalTimeSec,
    Value<String>? rationale,
    Value<String>? accepted,
    Value<String>? resultRecordId,
    Value<int>? rowid,
  }) {
    return RecipeSuggestionsTableCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      beanId: beanId ?? this.beanId,
      originId: originId ?? this.originId,
      roastLevel: roastLevel ?? this.roastLevel,
      methodId: methodId ?? this.methodId,
      temperature: temperature ?? this.temperature,
      brewRatio: brewRatio ?? this.brewRatio,
      totalTimeSec: totalTimeSec ?? this.totalTimeSec,
      rationale: rationale ?? this.rationale,
      accepted: accepted ?? this.accepted,
      resultRecordId: resultRecordId ?? this.resultRecordId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (beanId.present) {
      map['bean_id'] = Variable<String>(beanId.value);
    }
    if (originId.present) {
      map['origin_id'] = Variable<String>(originId.value);
    }
    if (roastLevel.present) {
      map['roast_level'] = Variable<String>(roastLevel.value);
    }
    if (methodId.present) {
      map['method_id'] = Variable<String>(methodId.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (brewRatio.present) {
      map['brew_ratio'] = Variable<double>(brewRatio.value);
    }
    if (totalTimeSec.present) {
      map['total_time_sec'] = Variable<int>(totalTimeSec.value);
    }
    if (rationale.present) {
      map['rationale'] = Variable<String>(rationale.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<String>(accepted.value);
    }
    if (resultRecordId.present) {
      map['result_record_id'] = Variable<String>(resultRecordId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeSuggestionsTableCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('beanId: $beanId, ')
          ..write('originId: $originId, ')
          ..write('roastLevel: $roastLevel, ')
          ..write('methodId: $methodId, ')
          ..write('temperature: $temperature, ')
          ..write('brewRatio: $brewRatio, ')
          ..write('totalTimeSec: $totalTimeSec, ')
          ..write('rationale: $rationale, ')
          ..write('accepted: $accepted, ')
          ..write('resultRecordId: $resultRecordId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $CoffeeDataTableTable coffeeDataTable = $CoffeeDataTableTable(
    this,
  );
  late final $BeanMasterTableTable beanMasterTable = $BeanMasterTableTable(
    this,
  );
  late final $MethodsMasterTableTable methodsMasterTable =
      $MethodsMasterTableTable(this);
  late final $PouringStepsTableTable pouringStepsTable =
      $PouringStepsTableTable(this);
  late final $MillMasterTableTable millMasterTable = $MillMasterTableTable(
    this,
  );
  late final $DripperMasterTableTable dripperMasterTable =
      $DripperMasterTableTable(this);
  late final $FilterMasterTableTable filterMasterTable =
      $FilterMasterTableTable(this);
  late final $OriginMasterTableTable originMasterTable =
      $OriginMasterTableTable(this);
  late final $StoreMasterTableTable storeMasterTable = $StoreMasterTableTable(
    this,
  );
  late final $BeanPurchasesTableTable beanPurchasesTable =
      $BeanPurchasesTableTable(this);
  late final $AnalysisHistoryTableTable analysisHistoryTable =
      $AnalysisHistoryTableTable(this);
  late final $RecipeSuggestionsTableTable recipeSuggestionsTable =
      $RecipeSuggestionsTableTable(this);
  late final Index idxCoffeeDataBrewedAt = Index(
    'idx_coffee_data_brewed_at',
    'CREATE INDEX idx_coffee_data_brewed_at ON coffee_data (brewed_at)',
  );
  late final Index idxCoffeeDataBeanId = Index(
    'idx_coffee_data_bean_id',
    'CREATE INDEX idx_coffee_data_bean_id ON coffee_data (bean_id)',
  );
  late final Index idxCoffeeDataMethodId = Index(
    'idx_coffee_data_method_id',
    'CREATE INDEX idx_coffee_data_method_id ON coffee_data (method_id)',
  );
  late final Index idxBeanMasterStoreId = Index(
    'idx_bean_master_store_id',
    'CREATE INDEX idx_bean_master_store_id ON bean_master (store_id)',
  );
  late final Index idxBeanMasterOriginId = Index(
    'idx_bean_master_origin_id',
    'CREATE INDEX idx_bean_master_origin_id ON bean_master (origin_id)',
  );
  late final Index idxPouringStepsMethodId = Index(
    'idx_pouring_steps_method_id',
    'CREATE INDEX idx_pouring_steps_method_id ON pouring_steps (method_id, step_order)',
  );
  late final Index idxBeanPurchasesBeanId = Index(
    'idx_bean_purchases_bean_id',
    'CREATE INDEX idx_bean_purchases_bean_id ON bean_purchases (bean_id)',
  );
  late final Index idxAnalysisHistoryType = Index(
    'idx_analysis_history_type',
    'CREATE INDEX idx_analysis_history_type ON analysis_history (type)',
  );
  late final Index idxRecipeSuggestionsBeanId = Index(
    'idx_recipe_suggestions_bean_id',
    'CREATE INDEX idx_recipe_suggestions_bean_id ON recipe_suggestions (bean_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    coffeeDataTable,
    beanMasterTable,
    methodsMasterTable,
    pouringStepsTable,
    millMasterTable,
    dripperMasterTable,
    filterMasterTable,
    originMasterTable,
    storeMasterTable,
    beanPurchasesTable,
    analysisHistoryTable,
    recipeSuggestionsTable,
    idxCoffeeDataBrewedAt,
    idxCoffeeDataBeanId,
    idxCoffeeDataMethodId,
    idxBeanMasterStoreId,
    idxBeanMasterOriginId,
    idxPouringStepsMethodId,
    idxBeanPurchasesBeanId,
    idxAnalysisHistoryType,
    idxRecipeSuggestionsBeanId,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CoffeeDataTableTableCreateCompanionBuilder =
    CoffeeDataTableCompanion Function({
      required String id,
      required DateTime brewedAt,
      Value<String> grinderId,
      Value<String> dripperId,
      Value<String> filterId,
      Value<String> beanId,
      Value<String> roastLevel,
      Value<String> origin,
      Value<String> originId,
      Value<double> beanWeight,
      Value<String> grindSize,
      Value<String> methodId,
      Value<String> taste,
      Value<String> concentration,
      Value<double> temperature,
      Value<double> bloomingWater,
      Value<double> totalWater,
      Value<int> bloomingTime,
      Value<int> totalTime,
      Value<int> scoreFragrance,
      Value<int> scoreAcidity,
      Value<int> scoreBitterness,
      Value<int> scoreSweetness,
      Value<int> scoreComplexity,
      Value<int> scoreFlavor,
      Value<int> scoreOverall,
      Value<String> comment,
      Value<String?> grinderImageUrl,
      Value<String?> dripperImageUrl,
      Value<String?> filterImageUrl,
      Value<String?> beanImageUrl,
      Value<int> rowid,
    });
typedef $$CoffeeDataTableTableUpdateCompanionBuilder =
    CoffeeDataTableCompanion Function({
      Value<String> id,
      Value<DateTime> brewedAt,
      Value<String> grinderId,
      Value<String> dripperId,
      Value<String> filterId,
      Value<String> beanId,
      Value<String> roastLevel,
      Value<String> origin,
      Value<String> originId,
      Value<double> beanWeight,
      Value<String> grindSize,
      Value<String> methodId,
      Value<String> taste,
      Value<String> concentration,
      Value<double> temperature,
      Value<double> bloomingWater,
      Value<double> totalWater,
      Value<int> bloomingTime,
      Value<int> totalTime,
      Value<int> scoreFragrance,
      Value<int> scoreAcidity,
      Value<int> scoreBitterness,
      Value<int> scoreSweetness,
      Value<int> scoreComplexity,
      Value<int> scoreFlavor,
      Value<int> scoreOverall,
      Value<String> comment,
      Value<String?> grinderImageUrl,
      Value<String?> dripperImageUrl,
      Value<String?> filterImageUrl,
      Value<String?> beanImageUrl,
      Value<int> rowid,
    });

class $$CoffeeDataTableTableFilterComposer
    extends Composer<_$LocalDatabase, $CoffeeDataTableTable> {
  $$CoffeeDataTableTableFilterComposer({
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

  ColumnFilters<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grinderId => $composableBuilder(
    column: $table.grinderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dripperId => $composableBuilder(
    column: $table.dripperId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterId => $composableBuilder(
    column: $table.filterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get beanWeight => $composableBuilder(
    column: $table.beanWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grindSize => $composableBuilder(
    column: $table.grindSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taste => $composableBuilder(
    column: $table.taste,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concentration => $composableBuilder(
    column: $table.concentration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bloomingWater => $composableBuilder(
    column: $table.bloomingWater,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWater => $composableBuilder(
    column: $table.totalWater,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bloomingTime => $composableBuilder(
    column: $table.bloomingTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTime => $composableBuilder(
    column: $table.totalTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreFragrance => $composableBuilder(
    column: $table.scoreFragrance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreAcidity => $composableBuilder(
    column: $table.scoreAcidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreBitterness => $composableBuilder(
    column: $table.scoreBitterness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreSweetness => $composableBuilder(
    column: $table.scoreSweetness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreComplexity => $composableBuilder(
    column: $table.scoreComplexity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreFlavor => $composableBuilder(
    column: $table.scoreFlavor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreOverall => $composableBuilder(
    column: $table.scoreOverall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grinderImageUrl => $composableBuilder(
    column: $table.grinderImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dripperImageUrl => $composableBuilder(
    column: $table.dripperImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterImageUrl => $composableBuilder(
    column: $table.filterImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoffeeDataTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $CoffeeDataTableTable> {
  $$CoffeeDataTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get brewedAt => $composableBuilder(
    column: $table.brewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grinderId => $composableBuilder(
    column: $table.grinderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dripperId => $composableBuilder(
    column: $table.dripperId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterId => $composableBuilder(
    column: $table.filterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get beanWeight => $composableBuilder(
    column: $table.beanWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grindSize => $composableBuilder(
    column: $table.grindSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taste => $composableBuilder(
    column: $table.taste,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concentration => $composableBuilder(
    column: $table.concentration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bloomingWater => $composableBuilder(
    column: $table.bloomingWater,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWater => $composableBuilder(
    column: $table.totalWater,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bloomingTime => $composableBuilder(
    column: $table.bloomingTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTime => $composableBuilder(
    column: $table.totalTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreFragrance => $composableBuilder(
    column: $table.scoreFragrance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreAcidity => $composableBuilder(
    column: $table.scoreAcidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreBitterness => $composableBuilder(
    column: $table.scoreBitterness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreSweetness => $composableBuilder(
    column: $table.scoreSweetness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreComplexity => $composableBuilder(
    column: $table.scoreComplexity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreFlavor => $composableBuilder(
    column: $table.scoreFlavor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreOverall => $composableBuilder(
    column: $table.scoreOverall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grinderImageUrl => $composableBuilder(
    column: $table.grinderImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dripperImageUrl => $composableBuilder(
    column: $table.dripperImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterImageUrl => $composableBuilder(
    column: $table.filterImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoffeeDataTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CoffeeDataTableTable> {
  $$CoffeeDataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get brewedAt =>
      $composableBuilder(column: $table.brewedAt, builder: (column) => column);

  GeneratedColumn<String> get grinderId =>
      $composableBuilder(column: $table.grinderId, builder: (column) => column);

  GeneratedColumn<String> get dripperId =>
      $composableBuilder(column: $table.dripperId, builder: (column) => column);

  GeneratedColumn<String> get filterId =>
      $composableBuilder(column: $table.filterId, builder: (column) => column);

  GeneratedColumn<String> get beanId =>
      $composableBuilder(column: $table.beanId, builder: (column) => column);

  GeneratedColumn<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get originId =>
      $composableBuilder(column: $table.originId, builder: (column) => column);

  GeneratedColumn<double> get beanWeight => $composableBuilder(
    column: $table.beanWeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grindSize =>
      $composableBuilder(column: $table.grindSize, builder: (column) => column);

  GeneratedColumn<String> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<String> get taste =>
      $composableBuilder(column: $table.taste, builder: (column) => column);

  GeneratedColumn<String> get concentration => $composableBuilder(
    column: $table.concentration,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bloomingWater => $composableBuilder(
    column: $table.bloomingWater,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalWater => $composableBuilder(
    column: $table.totalWater,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bloomingTime => $composableBuilder(
    column: $table.bloomingTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTime =>
      $composableBuilder(column: $table.totalTime, builder: (column) => column);

  GeneratedColumn<int> get scoreFragrance => $composableBuilder(
    column: $table.scoreFragrance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreAcidity => $composableBuilder(
    column: $table.scoreAcidity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreBitterness => $composableBuilder(
    column: $table.scoreBitterness,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreSweetness => $composableBuilder(
    column: $table.scoreSweetness,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreComplexity => $composableBuilder(
    column: $table.scoreComplexity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreFlavor => $composableBuilder(
    column: $table.scoreFlavor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoreOverall => $composableBuilder(
    column: $table.scoreOverall,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<String> get grinderImageUrl => $composableBuilder(
    column: $table.grinderImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dripperImageUrl => $composableBuilder(
    column: $table.dripperImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterImageUrl => $composableBuilder(
    column: $table.filterImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => column,
  );
}

class $$CoffeeDataTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CoffeeDataTableTable,
          CoffeeDataRow,
          $$CoffeeDataTableTableFilterComposer,
          $$CoffeeDataTableTableOrderingComposer,
          $$CoffeeDataTableTableAnnotationComposer,
          $$CoffeeDataTableTableCreateCompanionBuilder,
          $$CoffeeDataTableTableUpdateCompanionBuilder,
          (
            CoffeeDataRow,
            BaseReferences<
              _$LocalDatabase,
              $CoffeeDataTableTable,
              CoffeeDataRow
            >,
          ),
          CoffeeDataRow,
          PrefetchHooks Function()
        > {
  $$CoffeeDataTableTableTableManager(
    _$LocalDatabase db,
    $CoffeeDataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoffeeDataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoffeeDataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoffeeDataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> brewedAt = const Value.absent(),
                Value<String> grinderId = const Value.absent(),
                Value<String> dripperId = const Value.absent(),
                Value<String> filterId = const Value.absent(),
                Value<String> beanId = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<double> beanWeight = const Value.absent(),
                Value<String> grindSize = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<String> taste = const Value.absent(),
                Value<String> concentration = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> bloomingWater = const Value.absent(),
                Value<double> totalWater = const Value.absent(),
                Value<int> bloomingTime = const Value.absent(),
                Value<int> totalTime = const Value.absent(),
                Value<int> scoreFragrance = const Value.absent(),
                Value<int> scoreAcidity = const Value.absent(),
                Value<int> scoreBitterness = const Value.absent(),
                Value<int> scoreSweetness = const Value.absent(),
                Value<int> scoreComplexity = const Value.absent(),
                Value<int> scoreFlavor = const Value.absent(),
                Value<int> scoreOverall = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<String?> grinderImageUrl = const Value.absent(),
                Value<String?> dripperImageUrl = const Value.absent(),
                Value<String?> filterImageUrl = const Value.absent(),
                Value<String?> beanImageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoffeeDataTableCompanion(
                id: id,
                brewedAt: brewedAt,
                grinderId: grinderId,
                dripperId: dripperId,
                filterId: filterId,
                beanId: beanId,
                roastLevel: roastLevel,
                origin: origin,
                originId: originId,
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime brewedAt,
                Value<String> grinderId = const Value.absent(),
                Value<String> dripperId = const Value.absent(),
                Value<String> filterId = const Value.absent(),
                Value<String> beanId = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<double> beanWeight = const Value.absent(),
                Value<String> grindSize = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<String> taste = const Value.absent(),
                Value<String> concentration = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> bloomingWater = const Value.absent(),
                Value<double> totalWater = const Value.absent(),
                Value<int> bloomingTime = const Value.absent(),
                Value<int> totalTime = const Value.absent(),
                Value<int> scoreFragrance = const Value.absent(),
                Value<int> scoreAcidity = const Value.absent(),
                Value<int> scoreBitterness = const Value.absent(),
                Value<int> scoreSweetness = const Value.absent(),
                Value<int> scoreComplexity = const Value.absent(),
                Value<int> scoreFlavor = const Value.absent(),
                Value<int> scoreOverall = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<String?> grinderImageUrl = const Value.absent(),
                Value<String?> dripperImageUrl = const Value.absent(),
                Value<String?> filterImageUrl = const Value.absent(),
                Value<String?> beanImageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoffeeDataTableCompanion.insert(
                id: id,
                brewedAt: brewedAt,
                grinderId: grinderId,
                dripperId: dripperId,
                filterId: filterId,
                beanId: beanId,
                roastLevel: roastLevel,
                origin: origin,
                originId: originId,
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoffeeDataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CoffeeDataTableTable,
      CoffeeDataRow,
      $$CoffeeDataTableTableFilterComposer,
      $$CoffeeDataTableTableOrderingComposer,
      $$CoffeeDataTableTableAnnotationComposer,
      $$CoffeeDataTableTableCreateCompanionBuilder,
      $$CoffeeDataTableTableUpdateCompanionBuilder,
      (
        CoffeeDataRow,
        BaseReferences<_$LocalDatabase, $CoffeeDataTableTable, CoffeeDataRow>,
      ),
      CoffeeDataRow,
      PrefetchHooks Function()
    >;
typedef $$BeanMasterTableTableCreateCompanionBuilder =
    BeanMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String> roastLevel,
      Value<String> origin,
      Value<String> store,
      Value<String> type,
      Value<String?> imageUrl,
      Value<String?> beanImageUrl,
      Value<String?> infoImageUrl,
      Value<DateTime?> purchaseDate,
      Value<DateTime?> firstUseDate,
      Value<DateTime?> lastUseDate,
      Value<bool> isInStock,
      Value<double?> initialQuantityGrams,
      Value<String> originId,
      Value<DateTime?> roastDate,
      Value<double?> stockBaselineGrams,
      Value<DateTime?> stockBaselineAt,
      Value<String> storageLocation,
      Value<bool?> seekOptimalConditions,
      Value<String> storeId,
      Value<int> rowid,
    });
typedef $$BeanMasterTableTableUpdateCompanionBuilder =
    BeanMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> roastLevel,
      Value<String> origin,
      Value<String> store,
      Value<String> type,
      Value<String?> imageUrl,
      Value<String?> beanImageUrl,
      Value<String?> infoImageUrl,
      Value<DateTime?> purchaseDate,
      Value<DateTime?> firstUseDate,
      Value<DateTime?> lastUseDate,
      Value<bool> isInStock,
      Value<double?> initialQuantityGrams,
      Value<String> originId,
      Value<DateTime?> roastDate,
      Value<double?> stockBaselineGrams,
      Value<DateTime?> stockBaselineAt,
      Value<String> storageLocation,
      Value<bool?> seekOptimalConditions,
      Value<String> storeId,
      Value<int> rowid,
    });

class $$BeanMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $BeanMasterTableTable> {
  $$BeanMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get store => $composableBuilder(
    column: $table.store,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get infoImageUrl => $composableBuilder(
    column: $table.infoImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstUseDate => $composableBuilder(
    column: $table.firstUseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUseDate => $composableBuilder(
    column: $table.lastUseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInStock => $composableBuilder(
    column: $table.isInStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialQuantityGrams => $composableBuilder(
    column: $table.initialQuantityGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockBaselineGrams => $composableBuilder(
    column: $table.stockBaselineGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stockBaselineAt => $composableBuilder(
    column: $table.stockBaselineAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seekOptimalConditions => $composableBuilder(
    column: $table.seekOptimalConditions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeanMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $BeanMasterTableTable> {
  $$BeanMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get store => $composableBuilder(
    column: $table.store,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get infoImageUrl => $composableBuilder(
    column: $table.infoImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstUseDate => $composableBuilder(
    column: $table.firstUseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUseDate => $composableBuilder(
    column: $table.lastUseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInStock => $composableBuilder(
    column: $table.isInStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialQuantityGrams => $composableBuilder(
    column: $table.initialQuantityGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockBaselineGrams => $composableBuilder(
    column: $table.stockBaselineGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stockBaselineAt => $composableBuilder(
    column: $table.stockBaselineAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seekOptimalConditions => $composableBuilder(
    column: $table.seekOptimalConditions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeanMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $BeanMasterTableTable> {
  $$BeanMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get store =>
      $composableBuilder(column: $table.store, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get beanImageUrl => $composableBuilder(
    column: $table.beanImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get infoImageUrl => $composableBuilder(
    column: $table.infoImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstUseDate => $composableBuilder(
    column: $table.firstUseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUseDate => $composableBuilder(
    column: $table.lastUseDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInStock =>
      $composableBuilder(column: $table.isInStock, builder: (column) => column);

  GeneratedColumn<double> get initialQuantityGrams => $composableBuilder(
    column: $table.initialQuantityGrams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originId =>
      $composableBuilder(column: $table.originId, builder: (column) => column);

  GeneratedColumn<DateTime> get roastDate =>
      $composableBuilder(column: $table.roastDate, builder: (column) => column);

  GeneratedColumn<double> get stockBaselineGrams => $composableBuilder(
    column: $table.stockBaselineGrams,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get stockBaselineAt => $composableBuilder(
    column: $table.stockBaselineAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageLocation => $composableBuilder(
    column: $table.storageLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get seekOptimalConditions => $composableBuilder(
    column: $table.seekOptimalConditions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);
}

class $$BeanMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $BeanMasterTableTable,
          BeanMasterRow,
          $$BeanMasterTableTableFilterComposer,
          $$BeanMasterTableTableOrderingComposer,
          $$BeanMasterTableTableAnnotationComposer,
          $$BeanMasterTableTableCreateCompanionBuilder,
          $$BeanMasterTableTableUpdateCompanionBuilder,
          (
            BeanMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $BeanMasterTableTable,
              BeanMasterRow
            >,
          ),
          BeanMasterRow,
          PrefetchHooks Function()
        > {
  $$BeanMasterTableTableTableManager(
    _$LocalDatabase db,
    $BeanMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeanMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeanMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeanMasterTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> store = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> beanImageUrl = const Value.absent(),
                Value<String?> infoImageUrl = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<DateTime?> firstUseDate = const Value.absent(),
                Value<DateTime?> lastUseDate = const Value.absent(),
                Value<bool> isInStock = const Value.absent(),
                Value<double?> initialQuantityGrams = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> stockBaselineGrams = const Value.absent(),
                Value<DateTime?> stockBaselineAt = const Value.absent(),
                Value<String> storageLocation = const Value.absent(),
                Value<bool?> seekOptimalConditions = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeanMasterTableCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> store = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> beanImageUrl = const Value.absent(),
                Value<String?> infoImageUrl = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<DateTime?> firstUseDate = const Value.absent(),
                Value<DateTime?> lastUseDate = const Value.absent(),
                Value<bool> isInStock = const Value.absent(),
                Value<double?> initialQuantityGrams = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> stockBaselineGrams = const Value.absent(),
                Value<DateTime?> stockBaselineAt = const Value.absent(),
                Value<String> storageLocation = const Value.absent(),
                Value<bool?> seekOptimalConditions = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeanMasterTableCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeanMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $BeanMasterTableTable,
      BeanMasterRow,
      $$BeanMasterTableTableFilterComposer,
      $$BeanMasterTableTableOrderingComposer,
      $$BeanMasterTableTableAnnotationComposer,
      $$BeanMasterTableTableCreateCompanionBuilder,
      $$BeanMasterTableTableUpdateCompanionBuilder,
      (
        BeanMasterRow,
        BaseReferences<_$LocalDatabase, $BeanMasterTableTable, BeanMasterRow>,
      ),
      BeanMasterRow,
      PrefetchHooks Function()
    >;
typedef $$MethodsMasterTableTableCreateCompanionBuilder =
    MethodsMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String> author,
      Value<double> baseBeanWeight,
      Value<double> baseWaterAmount,
      Value<double?> temperature,
      Value<String?> grindSize,
      Value<String> description,
      Value<String> recommendedEquipment,
      Value<String?> sourceUrl,
      Value<String?> recommendedRoastLevel,
      Value<String?> recommendedRoastMin,
      Value<String?> recommendedRoastMax,
      Value<int> rowid,
    });
typedef $$MethodsMasterTableTableUpdateCompanionBuilder =
    MethodsMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> author,
      Value<double> baseBeanWeight,
      Value<double> baseWaterAmount,
      Value<double?> temperature,
      Value<String?> grindSize,
      Value<String> description,
      Value<String> recommendedEquipment,
      Value<String?> sourceUrl,
      Value<String?> recommendedRoastLevel,
      Value<String?> recommendedRoastMin,
      Value<String?> recommendedRoastMax,
      Value<int> rowid,
    });

class $$MethodsMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $MethodsMasterTableTable> {
  $$MethodsMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseBeanWeight => $composableBuilder(
    column: $table.baseBeanWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseWaterAmount => $composableBuilder(
    column: $table.baseWaterAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grindSize => $composableBuilder(
    column: $table.grindSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedEquipment => $composableBuilder(
    column: $table.recommendedEquipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedRoastLevel => $composableBuilder(
    column: $table.recommendedRoastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedRoastMin => $composableBuilder(
    column: $table.recommendedRoastMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendedRoastMax => $composableBuilder(
    column: $table.recommendedRoastMax,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MethodsMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $MethodsMasterTableTable> {
  $$MethodsMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseBeanWeight => $composableBuilder(
    column: $table.baseBeanWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseWaterAmount => $composableBuilder(
    column: $table.baseWaterAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grindSize => $composableBuilder(
    column: $table.grindSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedEquipment => $composableBuilder(
    column: $table.recommendedEquipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedRoastLevel => $composableBuilder(
    column: $table.recommendedRoastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedRoastMin => $composableBuilder(
    column: $table.recommendedRoastMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendedRoastMax => $composableBuilder(
    column: $table.recommendedRoastMax,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MethodsMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $MethodsMasterTableTable> {
  $$MethodsMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<double> get baseBeanWeight => $composableBuilder(
    column: $table.baseBeanWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseWaterAmount => $composableBuilder(
    column: $table.baseWaterAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grindSize =>
      $composableBuilder(column: $table.grindSize, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedEquipment => $composableBuilder(
    column: $table.recommendedEquipment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get recommendedRoastLevel => $composableBuilder(
    column: $table.recommendedRoastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedRoastMin => $composableBuilder(
    column: $table.recommendedRoastMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendedRoastMax => $composableBuilder(
    column: $table.recommendedRoastMax,
    builder: (column) => column,
  );
}

class $$MethodsMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $MethodsMasterTableTable,
          MethodsMasterRow,
          $$MethodsMasterTableTableFilterComposer,
          $$MethodsMasterTableTableOrderingComposer,
          $$MethodsMasterTableTableAnnotationComposer,
          $$MethodsMasterTableTableCreateCompanionBuilder,
          $$MethodsMasterTableTableUpdateCompanionBuilder,
          (
            MethodsMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $MethodsMasterTableTable,
              MethodsMasterRow
            >,
          ),
          MethodsMasterRow,
          PrefetchHooks Function()
        > {
  $$MethodsMasterTableTableTableManager(
    _$LocalDatabase db,
    $MethodsMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MethodsMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MethodsMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MethodsMasterTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<double> baseBeanWeight = const Value.absent(),
                Value<double> baseWaterAmount = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<String?> grindSize = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> recommendedEquipment = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> recommendedRoastLevel = const Value.absent(),
                Value<String?> recommendedRoastMin = const Value.absent(),
                Value<String?> recommendedRoastMax = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MethodsMasterTableCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<double> baseBeanWeight = const Value.absent(),
                Value<double> baseWaterAmount = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<String?> grindSize = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> recommendedEquipment = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> recommendedRoastLevel = const Value.absent(),
                Value<String?> recommendedRoastMin = const Value.absent(),
                Value<String?> recommendedRoastMax = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MethodsMasterTableCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MethodsMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $MethodsMasterTableTable,
      MethodsMasterRow,
      $$MethodsMasterTableTableFilterComposer,
      $$MethodsMasterTableTableOrderingComposer,
      $$MethodsMasterTableTableAnnotationComposer,
      $$MethodsMasterTableTableCreateCompanionBuilder,
      $$MethodsMasterTableTableUpdateCompanionBuilder,
      (
        MethodsMasterRow,
        BaseReferences<
          _$LocalDatabase,
          $MethodsMasterTableTable,
          MethodsMasterRow
        >,
      ),
      MethodsMasterRow,
      PrefetchHooks Function()
    >;
typedef $$PouringStepsTableTableCreateCompanionBuilder =
    PouringStepsTableCompanion Function({
      required String id,
      Value<String> methodId,
      Value<int> stepOrder,
      Value<int> duration,
      Value<double> waterAmount,
      Value<double> waterReference,
      Value<double?> waterRatio,
      Value<String> description,
      Value<int> rowid,
    });
typedef $$PouringStepsTableTableUpdateCompanionBuilder =
    PouringStepsTableCompanion Function({
      Value<String> id,
      Value<String> methodId,
      Value<int> stepOrder,
      Value<int> duration,
      Value<double> waterAmount,
      Value<double> waterReference,
      Value<double?> waterRatio,
      Value<String> description,
      Value<int> rowid,
    });

class $$PouringStepsTableTableFilterComposer
    extends Composer<_$LocalDatabase, $PouringStepsTableTable> {
  $$PouringStepsTableTableFilterComposer({
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

  ColumnFilters<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterAmount => $composableBuilder(
    column: $table.waterAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterReference => $composableBuilder(
    column: $table.waterReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterRatio => $composableBuilder(
    column: $table.waterRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PouringStepsTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $PouringStepsTableTable> {
  $$PouringStepsTableTableOrderingComposer({
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

  ColumnOrderings<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterAmount => $composableBuilder(
    column: $table.waterAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterReference => $composableBuilder(
    column: $table.waterReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterRatio => $composableBuilder(
    column: $table.waterRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PouringStepsTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PouringStepsTableTable> {
  $$PouringStepsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<int> get stepOrder =>
      $composableBuilder(column: $table.stepOrder, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<double> get waterAmount => $composableBuilder(
    column: $table.waterAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get waterReference => $composableBuilder(
    column: $table.waterReference,
    builder: (column) => column,
  );

  GeneratedColumn<double> get waterRatio => $composableBuilder(
    column: $table.waterRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$PouringStepsTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PouringStepsTableTable,
          PouringStepRow,
          $$PouringStepsTableTableFilterComposer,
          $$PouringStepsTableTableOrderingComposer,
          $$PouringStepsTableTableAnnotationComposer,
          $$PouringStepsTableTableCreateCompanionBuilder,
          $$PouringStepsTableTableUpdateCompanionBuilder,
          (
            PouringStepRow,
            BaseReferences<
              _$LocalDatabase,
              $PouringStepsTableTable,
              PouringStepRow
            >,
          ),
          PouringStepRow,
          PrefetchHooks Function()
        > {
  $$PouringStepsTableTableTableManager(
    _$LocalDatabase db,
    $PouringStepsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PouringStepsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PouringStepsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PouringStepsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<int> stepOrder = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<double> waterAmount = const Value.absent(),
                Value<double> waterReference = const Value.absent(),
                Value<double?> waterRatio = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PouringStepsTableCompanion(
                id: id,
                methodId: methodId,
                stepOrder: stepOrder,
                duration: duration,
                waterAmount: waterAmount,
                waterReference: waterReference,
                waterRatio: waterRatio,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> methodId = const Value.absent(),
                Value<int> stepOrder = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<double> waterAmount = const Value.absent(),
                Value<double> waterReference = const Value.absent(),
                Value<double?> waterRatio = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PouringStepsTableCompanion.insert(
                id: id,
                methodId: methodId,
                stepOrder: stepOrder,
                duration: duration,
                waterAmount: waterAmount,
                waterReference: waterReference,
                waterRatio: waterRatio,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PouringStepsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PouringStepsTableTable,
      PouringStepRow,
      $$PouringStepsTableTableFilterComposer,
      $$PouringStepsTableTableOrderingComposer,
      $$PouringStepsTableTableAnnotationComposer,
      $$PouringStepsTableTableCreateCompanionBuilder,
      $$PouringStepsTableTableUpdateCompanionBuilder,
      (
        PouringStepRow,
        BaseReferences<
          _$LocalDatabase,
          $PouringStepsTableTable,
          PouringStepRow
        >,
      ),
      PouringStepRow,
      PrefetchHooks Function()
    >;
typedef $$MillMasterTableTableCreateCompanionBuilder =
    MillMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String?> grindRange,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$MillMasterTableTableUpdateCompanionBuilder =
    MillMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> grindRange,
      Value<String?> description,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$MillMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $MillMasterTableTable> {
  $$MillMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grindRange => $composableBuilder(
    column: $table.grindRange,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MillMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $MillMasterTableTable> {
  $$MillMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grindRange => $composableBuilder(
    column: $table.grindRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MillMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $MillMasterTableTable> {
  $$MillMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get grindRange => $composableBuilder(
    column: $table.grindRange,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$MillMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $MillMasterTableTable,
          MillMasterRow,
          $$MillMasterTableTableFilterComposer,
          $$MillMasterTableTableOrderingComposer,
          $$MillMasterTableTableAnnotationComposer,
          $$MillMasterTableTableCreateCompanionBuilder,
          $$MillMasterTableTableUpdateCompanionBuilder,
          (
            MillMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $MillMasterTableTable,
              MillMasterRow
            >,
          ),
          MillMasterRow,
          PrefetchHooks Function()
        > {
  $$MillMasterTableTableTableManager(
    _$LocalDatabase db,
    $MillMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MillMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MillMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MillMasterTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> grindRange = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MillMasterTableCompanion(
                id: id,
                name: name,
                grindRange: grindRange,
                description: description,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String?> grindRange = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MillMasterTableCompanion.insert(
                id: id,
                name: name,
                grindRange: grindRange,
                description: description,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MillMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $MillMasterTableTable,
      MillMasterRow,
      $$MillMasterTableTableFilterComposer,
      $$MillMasterTableTableOrderingComposer,
      $$MillMasterTableTableAnnotationComposer,
      $$MillMasterTableTableCreateCompanionBuilder,
      $$MillMasterTableTableUpdateCompanionBuilder,
      (
        MillMasterRow,
        BaseReferences<_$LocalDatabase, $MillMasterTableTable, MillMasterRow>,
      ),
      MillMasterRow,
      PrefetchHooks Function()
    >;
typedef $$DripperMasterTableTableCreateCompanionBuilder =
    DripperMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String?> material,
      Value<String?> shape,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$DripperMasterTableTableUpdateCompanionBuilder =
    DripperMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> material,
      Value<String?> shape,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$DripperMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $DripperMasterTableTable> {
  $$DripperMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DripperMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $DripperMasterTableTable> {
  $$DripperMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DripperMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $DripperMasterTableTable> {
  $$DripperMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get material =>
      $composableBuilder(column: $table.material, builder: (column) => column);

  GeneratedColumn<String> get shape =>
      $composableBuilder(column: $table.shape, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$DripperMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $DripperMasterTableTable,
          DripperMasterRow,
          $$DripperMasterTableTableFilterComposer,
          $$DripperMasterTableTableOrderingComposer,
          $$DripperMasterTableTableAnnotationComposer,
          $$DripperMasterTableTableCreateCompanionBuilder,
          $$DripperMasterTableTableUpdateCompanionBuilder,
          (
            DripperMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $DripperMasterTableTable,
              DripperMasterRow
            >,
          ),
          DripperMasterRow,
          PrefetchHooks Function()
        > {
  $$DripperMasterTableTableTableManager(
    _$LocalDatabase db,
    $DripperMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DripperMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DripperMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DripperMasterTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> material = const Value.absent(),
                Value<String?> shape = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DripperMasterTableCompanion(
                id: id,
                name: name,
                material: material,
                shape: shape,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String?> material = const Value.absent(),
                Value<String?> shape = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DripperMasterTableCompanion.insert(
                id: id,
                name: name,
                material: material,
                shape: shape,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DripperMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $DripperMasterTableTable,
      DripperMasterRow,
      $$DripperMasterTableTableFilterComposer,
      $$DripperMasterTableTableOrderingComposer,
      $$DripperMasterTableTableAnnotationComposer,
      $$DripperMasterTableTableCreateCompanionBuilder,
      $$DripperMasterTableTableUpdateCompanionBuilder,
      (
        DripperMasterRow,
        BaseReferences<
          _$LocalDatabase,
          $DripperMasterTableTable,
          DripperMasterRow
        >,
      ),
      DripperMasterRow,
      PrefetchHooks Function()
    >;
typedef $$FilterMasterTableTableCreateCompanionBuilder =
    FilterMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String?> material,
      Value<String?> size,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$FilterMasterTableTableUpdateCompanionBuilder =
    FilterMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> material,
      Value<String?> size,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$FilterMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $FilterMasterTableTable> {
  $$FilterMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilterMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $FilterMasterTableTable> {
  $$FilterMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get material => $composableBuilder(
    column: $table.material,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilterMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $FilterMasterTableTable> {
  $$FilterMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get material =>
      $composableBuilder(column: $table.material, builder: (column) => column);

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$FilterMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $FilterMasterTableTable,
          FilterMasterRow,
          $$FilterMasterTableTableFilterComposer,
          $$FilterMasterTableTableOrderingComposer,
          $$FilterMasterTableTableAnnotationComposer,
          $$FilterMasterTableTableCreateCompanionBuilder,
          $$FilterMasterTableTableUpdateCompanionBuilder,
          (
            FilterMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $FilterMasterTableTable,
              FilterMasterRow
            >,
          ),
          FilterMasterRow,
          PrefetchHooks Function()
        > {
  $$FilterMasterTableTableTableManager(
    _$LocalDatabase db,
    $FilterMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilterMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilterMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilterMasterTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> material = const Value.absent(),
                Value<String?> size = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilterMasterTableCompanion(
                id: id,
                name: name,
                material: material,
                size: size,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String?> material = const Value.absent(),
                Value<String?> size = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FilterMasterTableCompanion.insert(
                id: id,
                name: name,
                material: material,
                size: size,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilterMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $FilterMasterTableTable,
      FilterMasterRow,
      $$FilterMasterTableTableFilterComposer,
      $$FilterMasterTableTableOrderingComposer,
      $$FilterMasterTableTableAnnotationComposer,
      $$FilterMasterTableTableCreateCompanionBuilder,
      $$FilterMasterTableTableUpdateCompanionBuilder,
      (
        FilterMasterRow,
        BaseReferences<
          _$LocalDatabase,
          $FilterMasterTableTable,
          FilterMasterRow
        >,
      ),
      FilterMasterRow,
      PrefetchHooks Function()
    >;
typedef $$OriginMasterTableTableCreateCompanionBuilder =
    OriginMasterTableCompanion Function({
      required String id,
      Value<String> countryCode,
      Value<String> nameJa,
      Value<String> nameEn,
      Value<String> region,
      Value<int> rowid,
    });
typedef $$OriginMasterTableTableUpdateCompanionBuilder =
    OriginMasterTableCompanion Function({
      Value<String> id,
      Value<String> countryCode,
      Value<String> nameJa,
      Value<String> nameEn,
      Value<String> region,
      Value<int> rowid,
    });

class $$OriginMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $OriginMasterTableTable> {
  $$OriginMasterTableTableFilterComposer({
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

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OriginMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $OriginMasterTableTable> {
  $$OriginMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameJa => $composableBuilder(
    column: $table.nameJa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get region => $composableBuilder(
    column: $table.region,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OriginMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $OriginMasterTableTable> {
  $$OriginMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameJa =>
      $composableBuilder(column: $table.nameJa, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);
}

class $$OriginMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $OriginMasterTableTable,
          OriginMasterRow,
          $$OriginMasterTableTableFilterComposer,
          $$OriginMasterTableTableOrderingComposer,
          $$OriginMasterTableTableAnnotationComposer,
          $$OriginMasterTableTableCreateCompanionBuilder,
          $$OriginMasterTableTableUpdateCompanionBuilder,
          (
            OriginMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $OriginMasterTableTable,
              OriginMasterRow
            >,
          ),
          OriginMasterRow,
          PrefetchHooks Function()
        > {
  $$OriginMasterTableTableTableManager(
    _$LocalDatabase db,
    $OriginMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OriginMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OriginMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OriginMasterTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> countryCode = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OriginMasterTableCompanion(
                id: id,
                countryCode: countryCode,
                nameJa: nameJa,
                nameEn: nameEn,
                region: region,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> countryCode = const Value.absent(),
                Value<String> nameJa = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> region = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OriginMasterTableCompanion.insert(
                id: id,
                countryCode: countryCode,
                nameJa: nameJa,
                nameEn: nameEn,
                region: region,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OriginMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $OriginMasterTableTable,
      OriginMasterRow,
      $$OriginMasterTableTableFilterComposer,
      $$OriginMasterTableTableOrderingComposer,
      $$OriginMasterTableTableAnnotationComposer,
      $$OriginMasterTableTableCreateCompanionBuilder,
      $$OriginMasterTableTableUpdateCompanionBuilder,
      (
        OriginMasterRow,
        BaseReferences<
          _$LocalDatabase,
          $OriginMasterTableTable,
          OriginMasterRow
        >,
      ),
      OriginMasterRow,
      PrefetchHooks Function()
    >;
typedef $$StoreMasterTableTableCreateCompanionBuilder =
    StoreMasterTableCompanion Function({
      required String id,
      Value<String> name,
      Value<String> formalName,
      Value<String> url,
      Value<String> prefecture,
      Value<String> address,
      Value<bool> hasOnlineShop,
      Value<bool> hasPhysicalStore,
      Value<bool> hasRoastery,
      Value<String> beanTendency,
      Value<String> memo,
      Value<String?> imageUrl,
      Value<String> snsUrl,
      Value<String> businessHours,
      Value<String> closedDays,
      Value<String> phone,
      Value<String> openedYear,
      Value<String> sourceUrl,
      Value<DateTime?> infoFetchedAt,
      Value<int> rowid,
    });
typedef $$StoreMasterTableTableUpdateCompanionBuilder =
    StoreMasterTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> formalName,
      Value<String> url,
      Value<String> prefecture,
      Value<String> address,
      Value<bool> hasOnlineShop,
      Value<bool> hasPhysicalStore,
      Value<bool> hasRoastery,
      Value<String> beanTendency,
      Value<String> memo,
      Value<String?> imageUrl,
      Value<String> snsUrl,
      Value<String> businessHours,
      Value<String> closedDays,
      Value<String> phone,
      Value<String> openedYear,
      Value<String> sourceUrl,
      Value<DateTime?> infoFetchedAt,
      Value<int> rowid,
    });

class $$StoreMasterTableTableFilterComposer
    extends Composer<_$LocalDatabase, $StoreMasterTableTable> {
  $$StoreMasterTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formalName => $composableBuilder(
    column: $table.formalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefecture => $composableBuilder(
    column: $table.prefecture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasOnlineShop => $composableBuilder(
    column: $table.hasOnlineShop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPhysicalStore => $composableBuilder(
    column: $table.hasPhysicalStore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasRoastery => $composableBuilder(
    column: $table.hasRoastery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanTendency => $composableBuilder(
    column: $table.beanTendency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snsUrl => $composableBuilder(
    column: $table.snsUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessHours => $composableBuilder(
    column: $table.businessHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closedDays => $composableBuilder(
    column: $table.closedDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openedYear => $composableBuilder(
    column: $table.openedYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get infoFetchedAt => $composableBuilder(
    column: $table.infoFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoreMasterTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $StoreMasterTableTable> {
  $$StoreMasterTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formalName => $composableBuilder(
    column: $table.formalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefecture => $composableBuilder(
    column: $table.prefecture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasOnlineShop => $composableBuilder(
    column: $table.hasOnlineShop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPhysicalStore => $composableBuilder(
    column: $table.hasPhysicalStore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasRoastery => $composableBuilder(
    column: $table.hasRoastery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanTendency => $composableBuilder(
    column: $table.beanTendency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snsUrl => $composableBuilder(
    column: $table.snsUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessHours => $composableBuilder(
    column: $table.businessHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closedDays => $composableBuilder(
    column: $table.closedDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openedYear => $composableBuilder(
    column: $table.openedYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get infoFetchedAt => $composableBuilder(
    column: $table.infoFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoreMasterTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $StoreMasterTableTable> {
  $$StoreMasterTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get formalName => $composableBuilder(
    column: $table.formalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get prefecture => $composableBuilder(
    column: $table.prefecture,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get hasOnlineShop => $composableBuilder(
    column: $table.hasOnlineShop,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasPhysicalStore => $composableBuilder(
    column: $table.hasPhysicalStore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasRoastery => $composableBuilder(
    column: $table.hasRoastery,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beanTendency => $composableBuilder(
    column: $table.beanTendency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get snsUrl =>
      $composableBuilder(column: $table.snsUrl, builder: (column) => column);

  GeneratedColumn<String> get businessHours => $composableBuilder(
    column: $table.businessHours,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closedDays => $composableBuilder(
    column: $table.closedDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get openedYear => $composableBuilder(
    column: $table.openedYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get infoFetchedAt => $composableBuilder(
    column: $table.infoFetchedAt,
    builder: (column) => column,
  );
}

class $$StoreMasterTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $StoreMasterTableTable,
          StoreMasterRow,
          $$StoreMasterTableTableFilterComposer,
          $$StoreMasterTableTableOrderingComposer,
          $$StoreMasterTableTableAnnotationComposer,
          $$StoreMasterTableTableCreateCompanionBuilder,
          $$StoreMasterTableTableUpdateCompanionBuilder,
          (
            StoreMasterRow,
            BaseReferences<
              _$LocalDatabase,
              $StoreMasterTableTable,
              StoreMasterRow
            >,
          ),
          StoreMasterRow,
          PrefetchHooks Function()
        > {
  $$StoreMasterTableTableTableManager(
    _$LocalDatabase db,
    $StoreMasterTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoreMasterTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoreMasterTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoreMasterTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> formalName = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> prefecture = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> hasOnlineShop = const Value.absent(),
                Value<bool> hasPhysicalStore = const Value.absent(),
                Value<bool> hasRoastery = const Value.absent(),
                Value<String> beanTendency = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> snsUrl = const Value.absent(),
                Value<String> businessHours = const Value.absent(),
                Value<String> closedDays = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> openedYear = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<DateTime?> infoFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreMasterTableCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> name = const Value.absent(),
                Value<String> formalName = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> prefecture = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<bool> hasOnlineShop = const Value.absent(),
                Value<bool> hasPhysicalStore = const Value.absent(),
                Value<bool> hasRoastery = const Value.absent(),
                Value<String> beanTendency = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> snsUrl = const Value.absent(),
                Value<String> businessHours = const Value.absent(),
                Value<String> closedDays = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> openedYear = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<DateTime?> infoFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoreMasterTableCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoreMasterTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $StoreMasterTableTable,
      StoreMasterRow,
      $$StoreMasterTableTableFilterComposer,
      $$StoreMasterTableTableOrderingComposer,
      $$StoreMasterTableTableAnnotationComposer,
      $$StoreMasterTableTableCreateCompanionBuilder,
      $$StoreMasterTableTableUpdateCompanionBuilder,
      (
        StoreMasterRow,
        BaseReferences<_$LocalDatabase, $StoreMasterTableTable, StoreMasterRow>,
      ),
      StoreMasterRow,
      PrefetchHooks Function()
    >;
typedef $$BeanPurchasesTableTableCreateCompanionBuilder =
    BeanPurchasesTableCompanion Function({
      required String id,
      Value<String> beanId,
      Value<DateTime?> purchasedAt,
      Value<DateTime?> roastDate,
      Value<double?> quantityGrams,
      Value<String> storeId,
      Value<String> storeName,
      Value<String> memo,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$BeanPurchasesTableTableUpdateCompanionBuilder =
    BeanPurchasesTableCompanion Function({
      Value<String> id,
      Value<String> beanId,
      Value<DateTime?> purchasedAt,
      Value<DateTime?> roastDate,
      Value<double?> quantityGrams,
      Value<String> storeId,
      Value<String> storeName,
      Value<String> memo,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$BeanPurchasesTableTableFilterComposer
    extends Composer<_$LocalDatabase, $BeanPurchasesTableTable> {
  $$BeanPurchasesTableTableFilterComposer({
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

  ColumnFilters<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityGrams => $composableBuilder(
    column: $table.quantityGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeanPurchasesTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $BeanPurchasesTableTable> {
  $$BeanPurchasesTableTableOrderingComposer({
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

  ColumnOrderings<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get roastDate => $composableBuilder(
    column: $table.roastDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityGrams => $composableBuilder(
    column: $table.quantityGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeanPurchasesTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $BeanPurchasesTableTable> {
  $$BeanPurchasesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get beanId =>
      $composableBuilder(column: $table.beanId, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get roastDate =>
      $composableBuilder(column: $table.roastDate, builder: (column) => column);

  GeneratedColumn<double> get quantityGrams => $composableBuilder(
    column: $table.quantityGrams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BeanPurchasesTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $BeanPurchasesTableTable,
          BeanPurchaseRow,
          $$BeanPurchasesTableTableFilterComposer,
          $$BeanPurchasesTableTableOrderingComposer,
          $$BeanPurchasesTableTableAnnotationComposer,
          $$BeanPurchasesTableTableCreateCompanionBuilder,
          $$BeanPurchasesTableTableUpdateCompanionBuilder,
          (
            BeanPurchaseRow,
            BaseReferences<
              _$LocalDatabase,
              $BeanPurchasesTableTable,
              BeanPurchaseRow
            >,
          ),
          BeanPurchaseRow,
          PrefetchHooks Function()
        > {
  $$BeanPurchasesTableTableTableManager(
    _$LocalDatabase db,
    $BeanPurchasesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeanPurchasesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeanPurchasesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeanPurchasesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> beanId = const Value.absent(),
                Value<DateTime?> purchasedAt = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> quantityGrams = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeanPurchasesTableCompanion(
                id: id,
                beanId: beanId,
                purchasedAt: purchasedAt,
                roastDate: roastDate,
                quantityGrams: quantityGrams,
                storeId: storeId,
                storeName: storeName,
                memo: memo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> beanId = const Value.absent(),
                Value<DateTime?> purchasedAt = const Value.absent(),
                Value<DateTime?> roastDate = const Value.absent(),
                Value<double?> quantityGrams = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> storeName = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BeanPurchasesTableCompanion.insert(
                id: id,
                beanId: beanId,
                purchasedAt: purchasedAt,
                roastDate: roastDate,
                quantityGrams: quantityGrams,
                storeId: storeId,
                storeName: storeName,
                memo: memo,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeanPurchasesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $BeanPurchasesTableTable,
      BeanPurchaseRow,
      $$BeanPurchasesTableTableFilterComposer,
      $$BeanPurchasesTableTableOrderingComposer,
      $$BeanPurchasesTableTableAnnotationComposer,
      $$BeanPurchasesTableTableCreateCompanionBuilder,
      $$BeanPurchasesTableTableUpdateCompanionBuilder,
      (
        BeanPurchaseRow,
        BaseReferences<
          _$LocalDatabase,
          $BeanPurchasesTableTable,
          BeanPurchaseRow
        >,
      ),
      BeanPurchaseRow,
      PrefetchHooks Function()
    >;
typedef $$AnalysisHistoryTableTableCreateCompanionBuilder =
    AnalysisHistoryTableCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<String> type,
      Value<int> dataCount,
      Value<String> payloadJson,
      Value<int> rowid,
    });
typedef $$AnalysisHistoryTableTableUpdateCompanionBuilder =
    AnalysisHistoryTableCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> type,
      Value<int> dataCount,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$AnalysisHistoryTableTableFilterComposer
    extends Composer<_$LocalDatabase, $AnalysisHistoryTableTable> {
  $$AnalysisHistoryTableTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataCount => $composableBuilder(
    column: $table.dataCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalysisHistoryTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $AnalysisHistoryTableTable> {
  $$AnalysisHistoryTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataCount => $composableBuilder(
    column: $table.dataCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalysisHistoryTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AnalysisHistoryTableTable> {
  $$AnalysisHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get dataCount =>
      $composableBuilder(column: $table.dataCount, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$AnalysisHistoryTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $AnalysisHistoryTableTable,
          AnalysisHistoryRow,
          $$AnalysisHistoryTableTableFilterComposer,
          $$AnalysisHistoryTableTableOrderingComposer,
          $$AnalysisHistoryTableTableAnnotationComposer,
          $$AnalysisHistoryTableTableCreateCompanionBuilder,
          $$AnalysisHistoryTableTableUpdateCompanionBuilder,
          (
            AnalysisHistoryRow,
            BaseReferences<
              _$LocalDatabase,
              $AnalysisHistoryTableTable,
              AnalysisHistoryRow
            >,
          ),
          AnalysisHistoryRow,
          PrefetchHooks Function()
        > {
  $$AnalysisHistoryTableTableTableManager(
    _$LocalDatabase db,
    $AnalysisHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnalysisHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> dataCount = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysisHistoryTableCompanion(
                id: id,
                createdAt: createdAt,
                type: type,
                dataCount: dataCount,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<String> type = const Value.absent(),
                Value<int> dataCount = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalysisHistoryTableCompanion.insert(
                id: id,
                createdAt: createdAt,
                type: type,
                dataCount: dataCount,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalysisHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $AnalysisHistoryTableTable,
      AnalysisHistoryRow,
      $$AnalysisHistoryTableTableFilterComposer,
      $$AnalysisHistoryTableTableOrderingComposer,
      $$AnalysisHistoryTableTableAnnotationComposer,
      $$AnalysisHistoryTableTableCreateCompanionBuilder,
      $$AnalysisHistoryTableTableUpdateCompanionBuilder,
      (
        AnalysisHistoryRow,
        BaseReferences<
          _$LocalDatabase,
          $AnalysisHistoryTableTable,
          AnalysisHistoryRow
        >,
      ),
      AnalysisHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$RecipeSuggestionsTableTableCreateCompanionBuilder =
    RecipeSuggestionsTableCompanion Function({
      required String id,
      required DateTime createdAt,
      Value<String> beanId,
      Value<String> originId,
      Value<String> roastLevel,
      Value<String> methodId,
      Value<double> temperature,
      Value<double> brewRatio,
      Value<int> totalTimeSec,
      Value<String> rationale,
      Value<String> accepted,
      Value<String> resultRecordId,
      Value<int> rowid,
    });
typedef $$RecipeSuggestionsTableTableUpdateCompanionBuilder =
    RecipeSuggestionsTableCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<String> beanId,
      Value<String> originId,
      Value<String> roastLevel,
      Value<String> methodId,
      Value<double> temperature,
      Value<double> brewRatio,
      Value<int> totalTimeSec,
      Value<String> rationale,
      Value<String> accepted,
      Value<String> resultRecordId,
      Value<int> rowid,
    });

class $$RecipeSuggestionsTableTableFilterComposer
    extends Composer<_$LocalDatabase, $RecipeSuggestionsTableTable> {
  $$RecipeSuggestionsTableTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get brewRatio => $composableBuilder(
    column: $table.brewRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTimeSec => $composableBuilder(
    column: $table.totalTimeSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rationale => $composableBuilder(
    column: $table.rationale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultRecordId => $composableBuilder(
    column: $table.resultRecordId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeSuggestionsTableTableOrderingComposer
    extends Composer<_$LocalDatabase, $RecipeSuggestionsTableTable> {
  $$RecipeSuggestionsTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beanId => $composableBuilder(
    column: $table.beanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originId => $composableBuilder(
    column: $table.originId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methodId => $composableBuilder(
    column: $table.methodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get brewRatio => $composableBuilder(
    column: $table.brewRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTimeSec => $composableBuilder(
    column: $table.totalTimeSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rationale => $composableBuilder(
    column: $table.rationale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accepted => $composableBuilder(
    column: $table.accepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultRecordId => $composableBuilder(
    column: $table.resultRecordId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeSuggestionsTableTableAnnotationComposer
    extends Composer<_$LocalDatabase, $RecipeSuggestionsTableTable> {
  $$RecipeSuggestionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get beanId =>
      $composableBuilder(column: $table.beanId, builder: (column) => column);

  GeneratedColumn<String> get originId =>
      $composableBuilder(column: $table.originId, builder: (column) => column);

  GeneratedColumn<String> get roastLevel => $composableBuilder(
    column: $table.roastLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get methodId =>
      $composableBuilder(column: $table.methodId, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get brewRatio =>
      $composableBuilder(column: $table.brewRatio, builder: (column) => column);

  GeneratedColumn<int> get totalTimeSec => $composableBuilder(
    column: $table.totalTimeSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rationale =>
      $composableBuilder(column: $table.rationale, builder: (column) => column);

  GeneratedColumn<String> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<String> get resultRecordId => $composableBuilder(
    column: $table.resultRecordId,
    builder: (column) => column,
  );
}

class $$RecipeSuggestionsTableTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $RecipeSuggestionsTableTable,
          RecipeSuggestionRow,
          $$RecipeSuggestionsTableTableFilterComposer,
          $$RecipeSuggestionsTableTableOrderingComposer,
          $$RecipeSuggestionsTableTableAnnotationComposer,
          $$RecipeSuggestionsTableTableCreateCompanionBuilder,
          $$RecipeSuggestionsTableTableUpdateCompanionBuilder,
          (
            RecipeSuggestionRow,
            BaseReferences<
              _$LocalDatabase,
              $RecipeSuggestionsTableTable,
              RecipeSuggestionRow
            >,
          ),
          RecipeSuggestionRow,
          PrefetchHooks Function()
        > {
  $$RecipeSuggestionsTableTableTableManager(
    _$LocalDatabase db,
    $RecipeSuggestionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeSuggestionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecipeSuggestionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecipeSuggestionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> beanId = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> brewRatio = const Value.absent(),
                Value<int> totalTimeSec = const Value.absent(),
                Value<String> rationale = const Value.absent(),
                Value<String> accepted = const Value.absent(),
                Value<String> resultRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeSuggestionsTableCompanion(
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                Value<String> beanId = const Value.absent(),
                Value<String> originId = const Value.absent(),
                Value<String> roastLevel = const Value.absent(),
                Value<String> methodId = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> brewRatio = const Value.absent(),
                Value<int> totalTimeSec = const Value.absent(),
                Value<String> rationale = const Value.absent(),
                Value<String> accepted = const Value.absent(),
                Value<String> resultRecordId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeSuggestionsTableCompanion.insert(
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
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeSuggestionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $RecipeSuggestionsTableTable,
      RecipeSuggestionRow,
      $$RecipeSuggestionsTableTableFilterComposer,
      $$RecipeSuggestionsTableTableOrderingComposer,
      $$RecipeSuggestionsTableTableAnnotationComposer,
      $$RecipeSuggestionsTableTableCreateCompanionBuilder,
      $$RecipeSuggestionsTableTableUpdateCompanionBuilder,
      (
        RecipeSuggestionRow,
        BaseReferences<
          _$LocalDatabase,
          $RecipeSuggestionsTableTable,
          RecipeSuggestionRow
        >,
      ),
      RecipeSuggestionRow,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$CoffeeDataTableTableTableManager get coffeeDataTable =>
      $$CoffeeDataTableTableTableManager(_db, _db.coffeeDataTable);
  $$BeanMasterTableTableTableManager get beanMasterTable =>
      $$BeanMasterTableTableTableManager(_db, _db.beanMasterTable);
  $$MethodsMasterTableTableTableManager get methodsMasterTable =>
      $$MethodsMasterTableTableTableManager(_db, _db.methodsMasterTable);
  $$PouringStepsTableTableTableManager get pouringStepsTable =>
      $$PouringStepsTableTableTableManager(_db, _db.pouringStepsTable);
  $$MillMasterTableTableTableManager get millMasterTable =>
      $$MillMasterTableTableTableManager(_db, _db.millMasterTable);
  $$DripperMasterTableTableTableManager get dripperMasterTable =>
      $$DripperMasterTableTableTableManager(_db, _db.dripperMasterTable);
  $$FilterMasterTableTableTableManager get filterMasterTable =>
      $$FilterMasterTableTableTableManager(_db, _db.filterMasterTable);
  $$OriginMasterTableTableTableManager get originMasterTable =>
      $$OriginMasterTableTableTableManager(_db, _db.originMasterTable);
  $$StoreMasterTableTableTableManager get storeMasterTable =>
      $$StoreMasterTableTableTableManager(_db, _db.storeMasterTable);
  $$BeanPurchasesTableTableTableManager get beanPurchasesTable =>
      $$BeanPurchasesTableTableTableManager(_db, _db.beanPurchasesTable);
  $$AnalysisHistoryTableTableTableManager get analysisHistoryTable =>
      $$AnalysisHistoryTableTableTableManager(_db, _db.analysisHistoryTable);
  $$RecipeSuggestionsTableTableTableManager get recipeSuggestionsTable =>
      $$RecipeSuggestionsTableTableTableManager(
        _db,
        _db.recipeSuggestionsTable,
      );
}
