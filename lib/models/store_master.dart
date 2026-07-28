import 'package:json_annotation/json_annotation.dart';

part 'store_master.g.dart';

/// 購入店マスタ (T3-67、設計書`docs/store_master_design.md`§2)。
@JsonSerializable()
class StoreMaster {
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String id;
  @JsonKey(defaultValue: '-')
  final String name;
  @JsonKey(defaultValue: '')
  final String formalName;
  @JsonKey(defaultValue: '')
  final String url;
  @JsonKey(defaultValue: '')
  final String prefecture;
  @JsonKey(defaultValue: '')
  final String address;
  @JsonKey(fromJson: _parseBool, defaultValue: false)
  final bool hasOnlineShop;
  @JsonKey(fromJson: _parseBool, defaultValue: false)
  final bool hasPhysicalStore;
  @JsonKey(fromJson: _parseBool, defaultValue: false)
  final bool hasRoastery;
  @JsonKey(defaultValue: '')
  final String beanTendency;
  @JsonKey(defaultValue: '')
  final String memo;
  final String? imageUrl;
  @JsonKey(defaultValue: '')
  final String snsUrl;
  @JsonKey(defaultValue: '')
  final String businessHours;
  @JsonKey(defaultValue: '')
  final String closedDays;
  @JsonKey(defaultValue: '')
  final String phone;
  @JsonKey(defaultValue: '', fromJson: _parseString)
  final String openedYear;
  @JsonKey(defaultValue: '')
  final String sourceUrl;
  @JsonKey(fromJson: _parseDate)
  final DateTime? infoFetchedAt;

  StoreMaster({
    required this.id,
    required this.name,
    this.formalName = '',
    this.url = '',
    this.prefecture = '',
    this.address = '',
    this.hasOnlineShop = false,
    this.hasPhysicalStore = false,
    this.hasRoastery = false,
    this.beanTendency = '',
    this.memo = '',
    this.imageUrl,
    this.snsUrl = '',
    this.businessHours = '',
    this.closedDays = '',
    this.phone = '',
    this.openedYear = '',
    this.sourceUrl = '',
    this.infoFetchedAt,
  });

  factory StoreMaster.fromJson(Map<String, dynamic> json) =>
      _$StoreMasterFromJson(json);

  Map<String, dynamic> toJson() => _$StoreMasterToJson(this);

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
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

  StoreMaster copyWith({
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
    String? imageUrl,
    String? snsUrl,
    String? businessHours,
    String? closedDays,
    String? phone,
    String? openedYear,
    String? sourceUrl,
    DateTime? infoFetchedAt,
  }) {
    return StoreMaster(
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
    );
  }
}

/// 初期投入データ7店 (設計書§4、T3-66の名寄せ結果)。
/// IDは固定スラッグ(タイムスタンプ生成にしない=冪等な移行スクリプトのため)。
/// 空欄の項目は「確証が得られなかった」ことを意味し、推測で埋めていない
/// (設計書§4の注記どおり)。
final List<StoreMaster> kInitialStoreMasters = [
  StoreMaster(
    id: 'store_navy',
    name: 'Navy',
    formalName: 'Navy Coffee Roaster',
    url: 'https://www.navycoffeeroaster.com/',
    prefecture: '兵庫県',
    address: '〒673-0873 明石市大蔵中町4-8',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    hasRoastery: true,
    beanTendency: 'スペシャルティコーヒー(甘み・果実感を重視)',
    snsUrl: 'https://www.instagram.com/navy_coffee_roaster/',
    businessHours: '8:00-18:00',
    closedDays: '火曜',
    phone: '078-965-6998',
    memo: '※同名店が複数あるため同定要確認(三重県鈴鹿市のNavy Coffee Houseとは別)。'
        '地域的に明石の当店と判断した。',
  ),
  StoreMaster(
    id: 'store_kobe_coffee',
    name: '神戸珈琲物語',
    formalName: '株式会社神戸珈琲',
    url: 'https://kobecoffee.jp/',
    prefecture: '兵庫県',
    address: '〒653-0827 神戸市長田区上池田6-8-23(上池田本店)',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    hasRoastery: true,
    beanTendency: '珈琲鑑定士が厳選した豆の量り売り。紀州備長炭による炭火焙煎が看板商品',
    businessHours: '平日9:00-17:30 土日祝8:00-17:30(上池田本店)',
    phone: '078-621-3360',
    memo: '直営10店舗(喫茶6/豆挽き売り4)。住所・電話・営業時間は本店のもの。'
        'どの店舗で購入したかはユーザーが後で補足すること。',
  ),
  StoreMaster(
    id: 'store_heisei',
    name: 'HEISEI COFFEE The Factory',
    formalName: '株式会社平成珈琲',
    url: 'https://www.heisei-coffee.co.jp/',
    prefecture: '兵庫県',
    address: '神戸市垂水区本多聞3丁目6-12',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    hasRoastery: true,
    beanTendency: 'ブレンド + スペシャルティのシングルオリジン。'
        'ドイツProbat製UG22・P3の2台で焙煎',
    snsUrl: 'https://www.instagram.com/heiseicoffee/',
    phone: '078-224-1479',
    openedYear: '2019',
    memo: 'The Factory(垂水区本多聞)は2026年オープンの焙煎工房併設店。'
        '公式サイト記載の営業時間8:00-18:00・定休日(日祝/第三第五土曜)は本社/工房の'
        'ものでThe Factory店舗としての営業時間かは未確認のため空欄にした。'
        '開業年2019は平成珈琲としての創業年。',
  ),
  StoreMaster(
    id: 'store_sora',
    name: 'SORA',
    memo: '※未同定。「そら」表記の1件を統合済み。候補: ①古民家カフェSORA / Sora cafe'
        '(神戸市北区有馬) ②珈琲焙煎室そら(神奈川県伊勢原) ③焙煎幸房"そら"(岐阜県大垣)。'
        '地域的には①が有力だが確証がないため全項目を空欄にした。ユーザーによる同定が必要。',
  ),
  StoreMaster(
    id: 'store_misaki',
    name: '岬の焙煎所',
    formalName: '岬の焙煎所',
    url: 'https://live-coffee.ocnk.net/',
    prefecture: '兵庫県',
    address: '神戸市兵庫区和田岬',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    hasRoastery: true,
    beanTendency: '浅煎り〜深煎りの自家焙煎8種前後。看板は「和田岬ブレンド」。'
        '中南米・アフリカのスペシャルティ',
    snsUrl: 'https://www.instagram.com/misaki_no_mame/',
    businessHours: '月-金10:00-17:00、第4土曜9:00-16:00',
    closedDays: '土日祝(第4土曜を除く)',
    openedYear: '2015',
    memo: '番地は公式サイトに記載なし。関連店「misaki cafe musubi」は'
        '兵庫区今出在家町2-2-17 HD神戸ビル1階。',
  ),
  StoreMaster(
    id: 'store_akekure',
    name: '明暮焙煎所',
    formalName: '明暮焙煎所',
    url: 'https://akekure-beans.com/',
    prefecture: '兵庫県',
    address: '〒654-0033 神戸市須磨区東町1-2-9',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    hasRoastery: true,
    beanTendency: 'スペシャルティグレードの生豆のみ使用。ブレンド5種+シングルオリジン7種の計12種',
    businessHours: '10:00-19:00',
    closedDays: '火曜・水曜',
    phone: '078-739-1050',
    openedYear: '2017',
    memo: '本番データの表記「明暮焙煎研」は誤記と判断し「明暮焙煎所」に修正した'
        '(T3-69の突合時、旧表記も一致するようフォールバックすること)。',
  ),
  StoreMaster(
    id: 'store_youth',
    name: 'Youth Coffee',
    url: 'https://youthcoffee.stores.jp/',
    prefecture: '兵庫県',
    hasOnlineShop: true,
    hasPhysicalStore: true,
    memo: '本番データでは購入店舗列が空欄で、豆名「Youth コロンビア/エチオピア/ケニア」'
        '3件から推定した店。神戸・三宮の立ち飲みスタイルのコーヒー店とみられるが、'
        '公式ストアがHTTP 403で取得できず二次情報のみ(営業8:00-18:00/火曜定休との記述あり)'
        'のため詳細は空欄にした。焙煎所併設かどうかも未確認。',
  ),
];
