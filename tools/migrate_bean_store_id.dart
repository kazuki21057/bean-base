// T3-69(docs/store_master_design.md§3.2・§9): bean_master.storeId の
// 一度きりの移行スクリプト。既存の`購入店舗`(自由入力文字列、および一部は
// 豆名からの推定)を購入店マスタ(T3-67で投入済みの7店)へ名寄せする。
// 同時に bean_purchases.購入店ID(T3-62で導入済み、遡及登録分は空のまま
// だった)にも、対応する豆で解決できた購入店IDを一本化して適用する
// (T3-63bの遡及登録がstoreIdを空で投入しているため)。
//
// 前提: gas/ のclaspデプロイが完了し、EXISTING_SHEET_EXTRA_COLUMNS['bean_master']
// に'購入店ID'が追加された状態で本番反映済みであること(T3-69)。未反映のまま
// 実行すると更新POSTが購入店ID列を持たないシートに書き込まれず何も保存されない。
//
// 名寄せ規則(docs/store_master_design.md§3.2、承認済み。ここで発明しない):
//   Navy                          → store_navy
//   神戸珈琲物語                   → store_kobe_coffee
//   HEISEI COFFEE The Factory     → store_heisei
//   SORA / そら                   → store_sora
//   岬の焙煎所                     → store_misaki
//   豆名が"岬焙煎所"で始まり店が空欄の1件 → store_misaki
//   明暮焙煎研(誤記) / 明暮焙煎所   → store_akekure
//   豆名が"Youth"で始まり店が空欄の3件    → store_youth
//   ドリップバッグ/コロンビア/グアテマラ  → 店名ではないため対象外(空のまま)
//
// 実行方法:
//   プレビューのみ(何も書き込まない): dart run tools/migrate_bean_store_id.dart --dry-run
//   実行:                              dart run tools/migrate_bean_store_id.dart
//   APIのURLを上書きする場合:           dart run tools/migrate_bean_store_id.dart --dry-run <URL>
//
// 冪等: bean_masterは既に購入店IDが設定済みの行をスキップする。bean_purchasesは
// 既に購入店IDが設定済みの行をスキップし、対応するbeanIdの解決に失敗した行も
// スキップする(2回目の実行はどちらも0件更新になる)。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため、既存のtools/migrate_bean_purchases.dart等と同じく
// package:httpで直接GAS Web Appを叩くスタンドアロン実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

/// 非店舗値(産地の誤入力・商品形態)。名寄せ対象外とし空欄のまま残す。
const _nonStoreValues = {'ドリップバッグ', 'コロンビア', 'グアテマラ'};

/// 店名の完全一致による名寄せ。
const _nameToStoreId = {
  'Navy': 'store_navy',
  '神戸珈琲物語': 'store_kobe_coffee',
  'HEISEI COFFEE The Factory': 'store_heisei',
  'SORA': 'store_sora',
  'そら': 'store_sora',
  '岬の焙煎所': 'store_misaki',
  '明暮焙煎研': 'store_akekure',
  '明暮焙煎所': 'store_akekure',
};

/// 購入店舗が空欄の行を豆名の前方一致で救う名寄せ。
String? _resolveByBeanNameFallback(String beanName) {
  if (beanName.startsWith('岬焙煎所')) return 'store_misaki';
  if (beanName.startsWith('Youth')) return 'store_youth';
  return null;
}

String? _resolveStoreId(String rawStore, String beanName) {
  final store = rawStore.trim();
  if (store.isNotEmpty) {
    if (_nonStoreValues.contains(store)) return null;
    final byName = _nameToStoreId[store];
    if (byName != null) return byName;
    return null; // 未知の値は推測せず空のまま
  }
  return _resolveByBeanNameFallback(beanName.trim());
}

Future<List<Map<String, dynamic>>> _fetchSheet(http.Client client, String apiUrl, String sheet) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=$sheet'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $sheet: ${response.statusCode}');
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('$sheet: ${decoded['error']}');
  }
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
}

Future<void> _updateRow(
  http.Client client,
  String apiUrl,
  String sheet,
  Map<String, dynamic> data,
) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': sheet, 'action': 'update', 'data': data}),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため手動で追従する
  // (tools/backfill_coffee_origin_ids.dartと同じ理由)。
  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to update $sheet: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to update $sheet: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to update $sheet: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final apiUrl = positional.isNotEmpty ? positional[0] : _defaultApiUrl;

  final client = http.Client();
  try {
    final beans = await _fetchSheet(client, apiUrl, 'bean_master');

    // bean_master: 豆ID -> 解決したstoreId (未解決/対象外はマップに含めない)
    final resolvedByBeanId = <String, String>{};
    final beanTargets = <Map<String, String>>[];
    var beanSkippedAlreadySet = 0;
    var beanSkippedUnresolved = 0;

    for (final row in beans) {
      final beanId = (row['豆ID'] ?? '').toString().trim();
      if (beanId.isEmpty) continue;
      final currentStoreId = (row['購入店ID'] ?? '').toString().trim();
      if (currentStoreId.isNotEmpty) {
        resolvedByBeanId[beanId] = currentStoreId;
        beanSkippedAlreadySet++;
        continue;
      }
      final rawStore = (row['購入店舗'] ?? '').toString();
      final beanName = (row['豆名'] ?? '').toString();
      final resolved = _resolveStoreId(rawStore, beanName);
      if (resolved == null) {
        beanSkippedUnresolved++;
        continue;
      }
      resolvedByBeanId[beanId] = resolved;
      beanTargets.add({'beanId': beanId, 'beanName': beanName, 'rawStore': rawStore, 'storeId': resolved});
    }

    stdout.writeln('--- bean_master 更新対象(${beanTargets.length}件) ---');
    for (final t in beanTargets) {
      stdout.writeln('豆ID=${t['beanId']} 豆名=${t['beanName']} 購入店舗="${t['rawStore']}" -> ${t['storeId']}');
    }
    stdout.writeln(
      'bean_master: 総数=${beans.length}, 更新対象=${beanTargets.length}, '
      '設定済みスキップ=$beanSkippedAlreadySet, 未解決スキップ=$beanSkippedUnresolved',
    );

    // bean_purchases: 購入店IDが空の行を、対応する豆の解決済みstoreIdで埋める。
    final purchases = await _fetchSheet(client, apiUrl, 'bean_purchases');
    final purchaseTargets = <Map<String, String>>[];
    var purchaseSkippedAlreadySet = 0;
    var purchaseSkippedUnresolved = 0;

    for (final row in purchases) {
      final purchaseId = (row['購入ID'] ?? '').toString().trim();
      if (purchaseId.isEmpty) continue;
      final currentStoreId = (row['購入店ID'] ?? '').toString().trim();
      if (currentStoreId.isNotEmpty) {
        purchaseSkippedAlreadySet++;
        continue;
      }
      final beanId = (row['豆ID'] ?? '').toString().trim();
      final resolved = resolvedByBeanId[beanId];
      if (resolved == null) {
        purchaseSkippedUnresolved++;
        continue;
      }
      purchaseTargets.add({'purchaseId': purchaseId, 'beanId': beanId, 'storeId': resolved});
    }

    stdout.writeln('--- bean_purchases 更新対象(${purchaseTargets.length}件) ---');
    for (final t in purchaseTargets) {
      stdout.writeln('購入ID=${t['purchaseId']} 豆ID=${t['beanId']} -> ${t['storeId']}');
    }
    stdout.writeln(
      'bean_purchases: 総数=${purchases.length}, 更新対象=${purchaseTargets.length}, '
      '設定済みスキップ=$purchaseSkippedAlreadySet, 未解決スキップ=$purchaseSkippedUnresolved',
    );

    if (dryRun) {
      stdout.writeln('--dry-run のため書き込みは行いません。');
      return;
    }

    var beanUpdated = 0;
    for (final t in beanTargets) {
      await _updateRow(client, apiUrl, 'bean_master', {'豆ID': t['beanId'], '購入店ID': t['storeId']});
      stdout.writeln('Updated bean_master: ${t['beanId']} -> ${t['storeId']}');
      beanUpdated++;
    }

    var purchaseUpdated = 0;
    for (final t in purchaseTargets) {
      await _updateRow(client, apiUrl, 'bean_purchases', {'購入ID': t['purchaseId'], '購入店ID': t['storeId']});
      stdout.writeln('Updated bean_purchases: ${t['purchaseId']} -> ${t['storeId']}');
      purchaseUpdated++;
    }

    stdout.writeln('Done. bean_master updated=$beanUpdated, bean_purchases updated=$purchaseUpdated');
  } finally {
    client.close();
  }
}
