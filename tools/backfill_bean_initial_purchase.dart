// T3-72a: 本番bean_masterの「初期購入量(g)」が未入力で全豆0%表示になっている
// 問題を、既に本番bean_purchasesにbp_init_<豆ID>として記録済みの初回購入量から
// 逆算して一括投入するワンショットスクリプト
// (tools/migrate_bean_purchases.dart・tools/backfill_coffee_origin_ids.dartと同じ形式)。
//
// 実行方法:
//   プレビューのみ(何も書き込まない): dart run tools/backfill_bean_initial_purchase.dart --dry-run
//   実行:                              dart run tools/backfill_bean_initial_purchase.dart
//   APIのURLを上書きする場合:           dart run tools/backfill_bean_initial_purchase.dart --dry-run <URL>
//
// 冪等: bean_purchasesの`bp_init_<豆ID>`行から`購入量(g)`を取得し、bean_masterの
// `初期購入量(g)`と異なる行のみ更新する。既に一致している行・`bp_init_`行が無い豆は
// スキップし件数を出力する(2回目の実行はupdated=0になる)。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため、既存のmigrate系スクリプトと同じくSheetsServiceを使わず
// package:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

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

/// package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
/// Locationヘッダへ手動でGETし直す(既存migrate系スクリプトと同じパターン)。
Future<void> _updateBean(http.Client client, String apiUrl, String beanId, String quantityGrams) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({
      'sheet': 'bean_master',
      'action': 'update',
      'data': {'豆ID': beanId, '初期購入量(g)': quantityGrams},
    }),
  );

  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to update $beanId: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to update $beanId: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to update $beanId: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final apiUrl = positional.isNotEmpty ? positional[0] : _defaultApiUrl;

  final client = http.Client();
  try {
    final purchases = await _fetchSheet(client, apiUrl, 'bean_purchases');
    final initQuantityByBeanId = <String, String>{};
    for (final row in purchases) {
      final purchaseId = row['購入ID']?.toString().trim() ?? '';
      if (!purchaseId.startsWith('bp_init_')) continue;
      final beanId = row['豆ID']?.toString().trim() ?? '';
      final quantity = row['購入量(g)']?.toString().trim() ?? '';
      if (beanId.isEmpty || quantity.isEmpty) continue;
      initQuantityByBeanId[beanId] = quantity;
    }
    stdout.writeln('bean_purchases: ${purchases.length}件中 bp_init_行 ${initQuantityByBeanId.length}件');

    final beans = await _fetchSheet(client, apiUrl, 'bean_master');

    final toUpdate = <(String beanId, String beanName, String from, String to)>[];
    var skippedNoInit = 0;
    var alreadySet = 0;
    for (final bean in beans) {
      final beanId = bean['豆ID']?.toString().trim() ?? '';
      if (beanId.isEmpty) continue;
      final beanName = bean['豆名']?.toString() ?? '';
      final target = initQuantityByBeanId[beanId];
      if (target == null) {
        skippedNoInit++;
        continue;
      }
      final current = bean['初期購入量(g)']?.toString().trim() ?? '';
      if (current == target) {
        alreadySet++;
        continue;
      }
      toUpdate.add((beanId, beanName, current, target));
    }

    stdout.writeln('--- 更新対象一覧(${toUpdate.length}件) ---');
    for (final t in toUpdate) {
      stdout.writeln('${t.$1}: 豆名=${t.$2} 初期購入量(g) ${t.$3.isEmpty ? "(空)" : t.$3} -> ${t.$4}');
    }

    if (dryRun) {
      stdout.writeln(
          '--dry-run のため書き込みは行いません。(bp_init_無し=$skippedNoInit件, 既に一致=$alreadySet件, 全${beans.length}件中)');
      return;
    }

    var updated = 0;
    for (final t in toUpdate) {
      await _updateBean(client, apiUrl, t.$1, t.$4);
      stdout.writeln('Updated: ${t.$1} (${t.$2}) -> ${t.$4}g');
      updated++;
    }

    stdout.writeln(
        'Done. updated=$updated, skippedNoInit=$skippedNoInit, alreadySet=$alreadySet, total=${beans.length}');
  } finally {
    client.close();
  }
}
