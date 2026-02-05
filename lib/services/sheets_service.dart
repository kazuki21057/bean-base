import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_record.dart';
import '../models/bean_master.dart';
import '../models/equipment_masters.dart';
import '../models/method_master.dart';
import '../models/pouring_step.dart';

// URL Placeholder - User needs to provide this
const String kGoogleSheetsApiUrl = 'https://script.google.com/macros/s/AKfycbx3ZIgSRh8v7ORcrL960GzZm0qD6I4X1jqsWYXHrZ8kpRXnpEs59N7pfszP-I6_AnoV/exec';

class SheetsService {
  final http.Client _client;
  final String _baseUrl = kGoogleSheetsApiUrl;

  SheetsService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<T>> _fetchData<T>(
      String sheetName, T Function(Map<String, dynamic>) fromJson) async {
    if (_baseUrl.isEmpty) {
      print('Warning: API URL is not set.');
      return [];
    }

    try {
      final response = await _client.get(Uri.parse('$_baseUrl?sheet=$sheetName'));

      if (response.statusCode == 200) {
        print('DEBUG: Raw API Response for $sheetName (Status 200)');
        // Print first 500 chars of body to avoid spamming console but allow inspection
        final rawBody = response.body;
        print('DEBUG: Raw Body Sample: ${rawBody.length > 500 ? rawBody.substring(0, 500) : rawBody}...');
        
        final dynamic decoded = json.decode(response.body);
        
        // Guard: Check if response is actually a List
        if (decoded is! List) {
          print('Error: Expected List for $sheetName but got ${decoded.runtimeType}. Response: $decoded');
          return [];
        }

        final List<dynamic> data = decoded;
        print('DEBUG: Decoded list length for $sheetName: ${data.length}');
        if (data.isNotEmpty) {
           print('DEBUG: First raw item in $sheetName: ${data.first}');
        }

        final List<T> validItems = [];
        for (var i = 0; i < data.length; i++) {
           final e = data[i];
           try {
             if (e == null) continue;
             if (e is! Map) {
                print('Warning: Item at index $i in $sheetName is not a Map: $e');
                continue;
             }
             
             // Sanitize map values (convert empty strings to null, strings to numbers if needed)
             final map = Map<String, dynamic>.from(e);
             
             // Remove nulls so defaults can work, or let sanitization handle it
             // Better: Keep nulls if we want to sanitize them? 
             // Current strategy: Remove null-value keys so json_serializable uses @JsonKey(defaultValue: ...)
             map.removeWhere((key, value) => value == null);

             // Apply robust conversion via fromJson (which calls _remapKeys internally in our usage patterns below)
             // Wait, the callback `fromJson` calls `_remapKeys`.
             // So we pass the raw map to `fromJson` callback, but the callback relies on `_remapKeys` to do the heavy lifting.
             
             validItems.add(fromJson(map));
           } catch (err, stack) {
             print('Error parsing record #$i in $sheetName: $err');
             print('Record content: $e');
             // print('Stack trace: $stack'); // Uncomment for deep debug
             // Continue to next item, don't crash entire list
           }
        }
        print('DEBUG: Successfully parsed ${validItems.length} items from $sheetName');
        if (validItems.isNotEmpty) {
           // Try to print ID or Name if available, otherwise just toString
           try {
             // Use dynamic to access fields loosely if possible, or just toString
             print('DEBUG: First parsed item: ${validItems.first}');
           } catch (e) {
             print('DEBUG: First parsed item (toString failed?): $e');
           }
        }
        return validItems;

      } else {
        throw Exception('Failed to load $sheetName: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching $sheetName: $e');
      return [];
    }
  }

  /// Remaps keys and sanitizes values (e.g. empty strings to null for defaults)
  Map<String, dynamic> _remapKeys(Map<String, dynamic> json, Map<String, String> keyMap) {
    final newMap = <String, dynamic>{};
    
    // First, map known keys
    json.forEach((key, value) {
      // 1. Determine new key
      final newKey = keyMap[key] ?? key;
      
      // 2. Sanitize value
      final sanitizedValue = _sanitizeValue(value);
      
      // 3. Add to new map ONLY if not null (to allow defaults to trigger)
      // BUT: If the field is nullable, we might want to keep explicit null?
      // json_serializable behavior: 
      // - if key is missing -> defaultValue used.
      // - if key is present but value is null -> defaultValue used (if includeIfNull: true default).
      // So adding it as null is usually safe if we want default.
      // However, to be safest for "defaultValue" triggering, it's often best to omit the key for empty values.
      
      if (sanitizedValue != null) {
        newMap[newKey] = sanitizedValue;
      }
    });

    return newMap;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (value.trim().isEmpty) return null; // Convert empty string to null
      
      // Try to parse numbers from strings if they look like numbers?
      // Risk: "0123" might be a zip code (string) but gets parsed as 123 (int).
      // Given this is BeanBase, most "number-like" strings are likely numbers (weights, temps, scores).
      // Let's be conservative: Only parse if we KNOW it's a number? 
      // We don't know the schema here.
      // So, let's just return the string. json_serializable might fail if it expects int.
      // Improving: Try double.tryParse?
      // If we convert "5" to 5.0, and field is int, it crashes?
      // If we convert "5" to 5, and field is String, it crashes?
      // Safest: Leave types alone UNLESS it's definitely an empty string cleanup.
      // The previous issue was "sending string '5' to int field" OR "sending number 5 to string field".
      // Our previous fix was "don't cast to string". That fixed "number to number".
      // Now we fix "empty string to number".
      
      return value;
    }
    return value;
  }

  Future<List<CoffeeRecord>> getCoffeeRecords() async {
    final keyMap = {
      '記録ID': 'id',
      '記録日': 'brewedAt',
      'ミル': 'grinderId',
      'ドリッパー': 'dripperId',
      'フィルター': 'filterId',
      '豆名': 'beanId',
      '焙煎度': 'roastLevel',
      '産地': 'origin',
      '豆の量(g)': 'beanWeight',
      '挽き目': 'grindSize',
      '抽出方法': 'methodId', // Changed from 'メソッド'
      '味': 'taste',
      '濃度': 'concentration',
      '湯温(℃)': 'temperature', // Changed from '温度'
      '蒸らし湯量(ml)': 'bloomingWater', // Changed from '蒸らし湯量'
      '湯量(ml)': 'totalWater', // Changed from '総湯量'
      '蒸らし時間(秒)': 'bloomingTime', // Changed from '蒸らし時間'
      '抽出時間(秒)': 'totalTime',
      '香り(1-10)': 'scoreFragrance',
      '酸味(1-10)': 'scoreAcidity',
      '苦味(1-10)': 'scoreBitterness',
      '甘味(1-10)': 'scoreSweetness',
      '複雑さ(1-10)': 'scoreComplexity',
      'フレーバー(1-10)': 'scoreFlavor',
      '総合評価(1-10)': 'scoreOverall',
      'コメント': 'comment',
      'ミル写真URL': 'grinderImageUrl',
      'ドリッパー写真URL': 'dripperImageUrl',
      'フィルタ写真URL': 'filterImageUrl',
      '豆写真URL': 'beanImageUrl',
    };

    return _fetchData('coffee_data', (map) {
      final remapped = _remapKeys(map, keyMap);
      
      // Special handling for brewedAt (DateTime)
      if (!remapped.containsKey('brewedAt') || remapped['brewedAt'] == null || remapped['brewedAt'] == '') {
         remapped['brewedAt'] = DateTime.now().toIso8601String();
      }
      
      return CoffeeRecord.fromJson(remapped);
    });
  }

  Future<List<BeanMaster>> getBeans() async {
    final keyMap = {
      '豆ID': 'id',
      '豆名': 'name',
      '焙煎度': 'roastLevel',
      '産地': 'origin',
      '購入店舗': 'store',
      '豆の種類': 'type',
      '豆画像URL': 'imageUrl',
      '購入日': 'purchaseDate',
      '開封日': 'firstUseDate',
      '使い切り日': 'lastUseDate',
      '在庫': 'isInStock',
    };
    return _fetchData('bean_master', (map) => BeanMaster.fromJson(_remapKeys(map, keyMap)));
  }

  Future<List<MethodMaster>> getMethods() async {
    final keyMap = {
      'メソッドID': 'id',
      'メソッド名': 'name',
      '発案者': 'author',
      '基準豆量(g)': 'baseBeanWeight',
      '基準湯量(ml)': 'baseWaterAmount',
      '湯温（℃）': 'temperature',
      '粒度': 'grindSize', 
      '説明': 'description',
      '推奨機器': 'recommendedEquipment',
      'ソース': 'sourceUrl',
    };
    return _fetchData('methods_master', (map) => MethodMaster.fromJson(_remapKeys(map, keyMap)));
  }
  
    Future<List<PouringStep>> getPouringSteps() async {
    final keyMap = {
      'ID': 'id',
      'メソッドID（親）': 'methodId',
      '並び順': 'stepOrder',
      '加算時間（秒）': 'duration',
      '加算湯量（ml）': 'waterAmount',
      '湯量基準(豆量15g)': 'waterReference',
      '湯量係数': 'waterRatio',
      '注意事項': 'description',
    };
    return _fetchData('pouring_steps', (map) => PouringStep.fromJson(_remapKeys(map, keyMap)));
  }

  Future<List<GrinderMaster>> getGrinders() async {
    final keyMap = {
      'ミルID': 'id',
      'ミル名': 'name',
      '挽き目範囲': 'grindRange',
      '説明': 'description',
      'ミル画像URL': 'imageUrl',
    };
    // Corrected sheet name from grinder_master to mill_master
    return _fetchData('mill_master', (map) => GrinderMaster.fromJson(_remapKeys(map, keyMap)));
  }

  Future<List<DripperMaster>> getDrippers() async {
    final keyMap = {
      'ドリッパーID': 'id',
      'ドリッパー名': 'name',
      '素材': 'material',
      '形状': 'shape',
      'ドリッパー画像URL': 'imageUrl',
    };
    return _fetchData('dripper_master', (map) => DripperMaster.fromJson(_remapKeys(map, keyMap)));
  }

  Future<List<FilterMaster>> getFilters() async {
     final keyMap = {
      'フィルターID': 'id',
      'フィルター名': 'name',
      '素材': 'material',
      'サイズ': 'size',
      'フィルター画像URL': 'imageUrl',
    };
    return _fetchData('filter_master', (map) => FilterMaster.fromJson(_remapKeys(map, keyMap)));
  }

  Future<void> addBean(BeanMaster bean) async {
    final data = _reverseMapBean(bean);
    await _postData('bean_master', 'add', data);
  }

  Future<void> updateBean(BeanMaster bean) async {
    final data = _reverseMapBean(bean);
    await _postData('bean_master', 'update', data);
  }

  Future<void> addGrinder(GrinderMaster grinder) async {
    final data = _reverseMapGrinder(grinder);
    await _postData('mill_master', 'add', data);
  }
  
  Future<void> updateGrinder(GrinderMaster grinder) async {
    final data = _reverseMapGrinder(grinder);
    await _postData('mill_master', 'update', data);
  }

  Future<void> addCoffeeRecord(CoffeeRecord record) async {
    final data = _reverseMapCoffeeRecord(record);
    await _postData('coffee_data', 'add', data);
  }

  Future<void> updateCoffeeRecord(CoffeeRecord record) async {
    final data = _reverseMapCoffeeRecord(record);
    await _postData('coffee_data', 'update', data);
  }

  Map<String, dynamic> _reverseMapCoffeeRecord(CoffeeRecord record) {
     final reverseMap = {
      'id': '記録ID',
      'brewedAt': '記録日',
      'grinderId': 'ミル',
      'dripperId': 'ドリッパー',
      'filterId': 'フィルター',
      'beanId': '豆名',
      'roastLevel': '焙煎度',
      'origin': '産地',
      'beanWeight': '豆の量(g)',
      'grindSize': '挽き目',
      'methodId': '抽出方法',
      'taste': '味',
      'concentration': '濃度',
      'temperature': '湯温(℃)',
      'bloomingWater': '蒸らし湯量(ml)',
      'totalWater': '湯量(ml)',
      'bloomingTime': '蒸らし時間(秒)',
      'totalTime': '抽出時間(秒)',
      'scoreFragrance': '香り(1-10)',
      'scoreAcidity': '酸味(1-10)',
      'scoreBitterness': '苦味(1-10)',
      'scoreSweetness': '甘味(1-10)',
      'scoreComplexity': '複雑さ(1-10)',
      'scoreFlavor': 'フレーバー(1-10)',
      'scoreOverall': '総合評価(1-10)',
      'comment': 'コメント',
      'grinderImageUrl': 'ミル写真URL',
      'dripperImageUrl': 'ドリッパー写真URL',
      'filterImageUrl': 'フィルタ写真URL',
      'beanImageUrl': '豆写真URL',
    };
    // Need to handle DateTime for brewedAt specifically if _mapToJson doesn't
    var json = record.toJson();
    // Ensure brewedAt is string format if it isn't already (toJson usually handles it)
    return _mapToJson(json, reverseMap);
  }

  Future<void> addDripper(DripperMaster dripper) async {
    final data = _reverseMapDripper(dripper);
    await _postData('dripper_master', 'add', data);
  }

  Future<void> updateDripper(DripperMaster dripper) async {
    final data = _reverseMapDripper(dripper);
    await _postData('dripper_master', 'update', data);
  }

  Future<void> addFilter(FilterMaster filter) async {
    final data = _reverseMapFilter(filter);
    await _postData('filter_master', 'add', data);
  }

  Future<void> updateFilter(FilterMaster filter) async {
    final data = _reverseMapFilter(filter);
    await _postData('filter_master', 'update', data);
  }

  Future<void> addMethod(MethodMaster method) async {
    final data = _reverseMapMethod(method);
    await _postData('methods_master', 'add', data);
  }

  Future<void> updateMethod(MethodMaster method) async {
    final data = _reverseMapMethod(method);
    await _postData('methods_master', 'update', data);
  }

  // --- Pouring Steps ---

  Future<void> addPouringStep(PouringStep step) async {
    final data = _reverseMapPouringStep(step);
    await _postData('pouring_steps', 'add', data);
  }

  Future<void> updatePouringStep(PouringStep step) async {
    final data = _reverseMapPouringStep(step);
    await _postData('pouring_steps', 'update', data);
  }

  Future<void> deletePouringStepsForMethod(String methodId) async {
     // This would preferably be a batch operation or a specific 'delete_all' action on the backend
     // Since backend is generic, we might need a custom action or just use 'action: delete' if supported.
     // For now, let's assume valid action 'delete_by_method_id' is NOT standard in our generic script?
     // Actually the generic script usually takes 'id' to delete.
     // To delete ALL for a method, we might need to filter and delete one by one or support a filter delete.
     // Let's assume for now we will just ADD/UPDATE. Deleting old ones might be tricky without bulk API.
     // Workaround: We will just ADD new ones. If we edit, we UPDATE existing ones.
     // If we remove one in UI, we should call 'delete' if available.
     // Let's add a generic 'delete' method if we have the ID.
  }

  Future<void> deletePouringStep(String stepId) async {
     await _postData('pouring_steps', 'delete', {'ID': stepId});
  }

  // Helpers for reverse mapping
  Map<String, dynamic> _reverseMapBean(BeanMaster bean) {
     final reverseMap = {
      'id': '豆ID', 'name': '豆名', 'roastLevel': '焙煎度', 'origin': '産地',
      'store': '購入店舗', 'type': '豆の種類', 'imageUrl': '豆画像URL',
      'purchaseDate': '購入日', 'firstUseDate': '開封日', 'lastUseDate': '使い切り日', 'isInStock': '在庫',
    };
    return _mapToJson(bean.toJson(), reverseMap);
  }

  Map<String, dynamic> _reverseMapGrinder(GrinderMaster item) {
    final reverseMap = { 'id': 'ミルID', 'name': 'ミル名', 'grindRange': '挽き目範囲', 'description': '説明', 'imageUrl': 'ミル画像URL' };
    return _mapToJson(item.toJson(), reverseMap);
  }

  Map<String, dynamic> _reverseMapDripper(DripperMaster item) {
    final reverseMap = { 'id': 'ドリッパーID', 'name': 'ドリッパー名', 'material': '素材', 'shape': '形状', 'imageUrl': 'ドリッパー画像URL' };
    return _mapToJson(item.toJson(), reverseMap);
  }

  Map<String, dynamic> _reverseMapFilter(FilterMaster item) {
    final reverseMap = { 'id': 'フィルターID', 'name': 'フィルター名', 'material': '素材', 'size': 'サイズ', 'imageUrl': 'フィルター画像URL' };
    return _mapToJson(item.toJson(), reverseMap);
  }

  Map<String, dynamic> _reverseMapMethod(MethodMaster item) {
    final reverseMap = { 
       'id': 'メソッドID', 'name': 'メソッド名', 'author': '発案者', 
       'baseBeanWeight': '基準豆量(g)', 'baseWaterAmount': '基準湯量(ml)', 
       'temperature': '湯温（℃）', 'grindSize': '粒度', 
       'description': '説明', 'recommendedEquipment': '推奨機器', 'sourceUrl': 'ソース'
    };
    return _mapToJson(item.toJson(), reverseMap);
  }

  Map<String, dynamic> _reverseMapPouringStep(PouringStep item) {
    final reverseMap = {
      'id': 'ID',
      'methodId': 'メソッドID（親）',
      'stepOrder': '並び順',
      'duration': '加算時間（秒）',
      'waterAmount': '加算湯量（ml）',
      'waterReference': '湯量基準(豆量15g)',
      'waterRatio': '湯量係数',
      'description': '注意事項',
    };
    return _mapToJson(item.toJson(), reverseMap);
  }

  Map<String, dynamic> _mapToJson(Map<String, dynamic> json, Map<String, String> reverseMap) {
    final data = <String, dynamic>{};
    json.forEach((key, value) {
      if (reverseMap.containsKey(key)) {
        data[reverseMap[key]!] = value;
      }
    });
    return data;
  }

  Future<void> _postData(String sheetName, String action, Map<String, dynamic> data) async {
     if (_baseUrl.isEmpty) return;
     
     print('DEBUG: Sending $action request to $sheetName');
     print('DEBUG: Payload: $data');

     try {
       final response = await _client.post(
         Uri.parse(_baseUrl),
         // Use text/plain to avoid CORS preflight OPTIONS request which GAS doesn't handle well
         headers: {'Content-Type': 'text/plain'},
         body: json.encode({
           'sheet': sheetName,
           'action': action,
           'data': data,
         }),
       );

       if (response.statusCode == 200 || response.statusCode == 302) {
         print('DEBUG: Successfully posted to $sheetName ($action)');
         print('DEBUG: Response Body: ${response.body}');
       } else {
         print('ERROR: Failed to post to $sheetName: ${response.statusCode} ${response.body}');
         throw Exception('Failed to post to $sheetName: ${response.statusCode}');
       }
     } catch (e) {
       print('Error posting to $sheetName: $e');
       throw e; 
     }
  }
}

final sheetsServiceProvider = Provider<SheetsService>((ref) {
  return SheetsService();
});
