import 'package:json_annotation/json_annotation.dart';

part 'bean_master.g.dart';

@JsonSerializable()
class BeanMaster {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  @JsonKey(defaultValue: '')
  final String roastLevel;
  @JsonKey(defaultValue: '')
  final String origin;
  @JsonKey(defaultValue: '')
  final String store;
  @JsonKey(defaultValue: '')
  final String type;

  /// T3-34: 画像3分類のうち「パッケージ画像」。既存の単一`imageUrl`をそのまま
  /// 転用(データ移行不要。旧データは全てパッケージ画像として表示される)。
  final String? imageUrl;

  /// T3-34: 「豆画像」(豆粒そのものの写真)。
  final String? beanImageUrl;

  /// T3-34: 「情報画像」(パッケージ裏面の説明書き等。Gemini Vision抽出の
  /// 入力画像もここに保存される、T3-35で結線予定)。
  final String? infoImageUrl;

  @JsonKey(fromJson: _parseDate)
  final DateTime? purchaseDate;
  @JsonKey(fromJson: _parseDate)
  final DateTime? firstUseDate;
  @JsonKey(fromJson: _parseDate)
  final DateTime? lastUseDate;
  @JsonKey(fromJson: _parseBool, defaultValue: false)
  final bool isInStock;

  /// 購入時の初期量(g)。抽出履歴からの残量%算出(T2-2b)に使用。
  /// 未設定(既存データ含む)の場合は残量0%として扱う。
  @JsonKey(fromJson: _parseDouble)
  final double? initialQuantityGrams;

  /// T4-1b(設計書§3.2): 選択されたOriginMasterのid。`origin`(自由入力文字列)は
  /// 後方互換のため残し、保存時に同時コピーする(brew_evaluation_screen.dart等の
  /// 既存originコピー処理を壊さないため)。
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String originId;

  /// T4-1b(設計書§3.2): 焙煎日(任意入力)。豆の鮮度(経過日数)は保存せず、
  /// 表示・計算時に`brewedAt.difference(roastDate).inDays`で導出する。
  @JsonKey(fromJson: _parseDate)
  final DateTime? roastDate;

  /// T3-60: 残量の手動調整による基準時点での残量(g)。設定されている間は
  /// `initialQuantityGrams`ではなくこの値を基準に残量を算出する
  /// (`calculateBeanRemainingGrams`/`calculateBeanRemainingPercent`参照)。
  @JsonKey(fromJson: _parseDouble)
  final double? stockBaselineGrams;

  /// T3-60: `stockBaselineGrams`を設定した日時。この日時より後の抽出記録のみ
  /// 残量計算で差し引く(基準点設定より前の記録は既に反映済みとみなす)。
  @JsonKey(fromJson: _parseDate)
  final DateTime? stockBaselineAt;

  /// T3-59: 保存場所(職場/家)。選択肢は`lib/utils/bean_storage.dart`の
  /// `beanStorageLocations`を参照。
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String storageLocation;

  /// T3-50: この豆で最適条件(メソッド・湯温・粒度)を探索するか(旧称: A/Bテスト
  /// を希望するか)。`null`は「未回答」を表し、001ダッシュボードで回答を促す
  /// カードが表示される。`true`にした豆がT3-52(GP探索)・T3-53(進捗表示)の対象。
  @JsonKey(fromJson: _parseNullableBool)
  final bool? seekOptimalConditions;

  /// T3-69(設計書§9): 選択されたStoreMasterのid。`store`(自由入力文字列)は
  /// 後方互換のため残し、保存時に選択した店名を同時コピーする(originIdと同じパターン)。
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String storeId;

  BeanMaster({
    required this.id,
    required this.name,
    required this.roastLevel,
    required this.origin,
    this.store = '',
    this.type = '',
    this.imageUrl,
    this.beanImageUrl,
    this.infoImageUrl,
    this.purchaseDate,
    this.firstUseDate,
    this.lastUseDate,
    this.isInStock = false,
    this.initialQuantityGrams,
    this.originId = '',
    this.roastDate,
    this.stockBaselineGrams,
    this.stockBaselineAt,
    this.storageLocation = '',
    this.seekOptimalConditions,
    this.storeId = '',
  });

  factory BeanMaster.fromJson(Map<String, dynamic> json) =>
      _$BeanMasterFromJson(json);

  Map<String, dynamic> toJson() => _$BeanMasterToJson(this);

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try {
        String formatted = value.replaceAll('/', '-');
        if (formatted.contains(' ')) formatted = formatted.replaceAll(' ', 'T');
        if (formatted.split(':').length == 2) formatted += ':00';
        return DateTime.parse(formatted);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == 'yes' || v == '1';
    }
    return false;
  }

  /// T3-50: 3値(未回答=null/探索する=true/探索しない=false)を扱うためのbool?版。
  /// 空文字・未知の文字列は「未回答」として扱う。
  static bool? _parseNullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == 'yes' || v == '1') return true;
      if (v == 'false' || v == 'no' || v == '0') return false;
      return null;
    }
    return null;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value.trim());
    }
    return null;
  }

  BeanMaster copyWith({
    String? id,
    String? name,
    String? roastLevel,
    String? origin,
    String? store,
    String? type,
    String? imageUrl,
    String? beanImageUrl,
    String? infoImageUrl,
    DateTime? purchaseDate,
    DateTime? firstUseDate,
    DateTime? lastUseDate,
    bool? isInStock,
    double? initialQuantityGrams,
    String? originId,
    DateTime? roastDate,
    double? stockBaselineGrams,
    DateTime? stockBaselineAt,
    String? storageLocation,
    bool? seekOptimalConditions,
    String? storeId,
  }) {
    return BeanMaster(
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
      seekOptimalConditions: seekOptimalConditions ?? this.seekOptimalConditions,
      storeId: storeId ?? this.storeId,
    );
  }
}
