// T3-63b(docs/bean_purchase_design.md§5.2): 既存bean_masterの購入日を
// 遡及登録し、購入履歴(bean_purchases)に初回購入行を1件ずつ作る
// (一度きりのスクリプト、tools/migrate_stores.dartと同型)。
//
// 実行方法:
//   プレビューのみ(何も書き込まない): dart run tools/migrate_bean_purchases.dart --dry-run
//   実行:                              dart run tools/migrate_bean_purchases.dart
//   APIのURLを上書きする場合:           dart run tools/migrate_bean_purchases.dart --dry-run <URL>
//
// 冪等: 実行のたびにbean_purchasesの既存`購入ID`一覧を取得し、
// `bp_init_<豆ID>`が未投入のものだけ追加する。2回目の実行はadded=0になる。
//
// 対象: bean_masterの全行のうち`購入日`が非空のもの。
// 購入店IDは空のままにする(名寄せはT3-69の`tools/migrate_bean_store_id.dart`に一本化)。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため、既存の`tools/migrate_stores.dart`と同じくSheetsServiceを
// 使わずpackage:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

class _Target {
  final String beanId;
  final String beanName;
  final String purchasedAt;
  final String roastDate;
  final String quantityGrams;
  final String storeName;

  _Target({
    required this.beanId,
    required this.beanName,
    required this.purchasedAt,
    required this.roastDate,
    required this.quantityGrams,
    required this.storeName,
  });

  String get purchaseId => 'bp_init_$beanId';
}

Future<List<Map<String, dynamic>>> _fetchSheet(http.Client client, String apiUrl, String sheet) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=$sheet'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $sheet: ${response.statusCode}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('$sheet: ${decoded['error']}');
  }
  return (decoded as List).cast<Map<String, dynamic>>();
}

Future<void> _addPurchase(http.Client client, String apiUrl, _Target target) async {
  final data = {
    '購入ID': target.purchaseId,
    '豆ID': target.beanId,
    '購入日': target.purchasedAt,
    '焙煎日': target.roastDate,
    '購入量(g)': target.quantityGrams,
    '購入店ID': '',
    '購入店名': target.storeName,
    'メモ': '既存データからの遡及登録',
    '登録日時': DateTime.now().toIso8601String(),
  };

  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': 'bean_purchases', 'action': 'add', 'data': data}),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
  // Locationヘッダへ手動でGETし直す(tools/migrate_stores.dartと同じパターン)。
  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to add ${target.purchaseId}: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to add ${target.purchaseId}: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to add ${target.purchaseId}: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final apiUrl = positional.isNotEmpty ? positional[0] : _defaultApiUrl;

  final client = http.Client();
  try {
    final beanRows = await _fetchSheet(client, apiUrl, 'bean_master');
    final existingPurchases = await _fetchSheet(client, apiUrl, 'bean_purchases');
    final existingIds = existingPurchases.map((r) => r['購入ID']?.toString()).whereType<String>().toSet();

    final targets = <_Target>[];
    for (final row in beanRows) {
      final purchasedAt = row['購入日']?.toString().trim() ?? '';
      if (purchasedAt.isEmpty) continue;
      final beanId = row['豆ID']?.toString() ?? '';
      if (beanId.isEmpty) continue;
      targets.add(_Target(
        beanId: beanId,
        beanName: row['豆名']?.toString() ?? '',
        purchasedAt: purchasedAt,
        roastDate: row['焙煎日']?.toString().trim() ?? '',
        quantityGrams: row['初期購入量(g)']?.toString().trim() ?? '',
        storeName: row['購入店舗']?.toString().trim() ?? '',
      ));
    }

    final toAdd = targets.where((t) => !existingIds.contains(t.purchaseId)).toList();
    final skipped = targets.length - toAdd.length;

    stdout.writeln('--- 対象一覧(${toAdd.length}件、既存$skipped件はスキップ) ---');
    for (final t in toAdd) {
      stdout.writeln(
        '${t.purchaseId}: 豆名=${t.beanName} 購入日=${t.purchasedAt} 購入量=${t.quantityGrams}g 購入店=${t.storeName}',
      );
    }

    if (dryRun) {
      stdout.writeln('--dry-run のため書き込みは行いません。');
      return;
    }

    var added = 0;
    for (final t in toAdd) {
      await _addPurchase(client, apiUrl, t);
      stdout.writeln('Added: ${t.purchaseId} (${t.beanName})');
      added++;
    }

    stdout.writeln('Done. added=$added, skipped=$skipped, total=${targets.length}');
  } finally {
    client.close();
  }
}
