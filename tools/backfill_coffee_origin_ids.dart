// T4-2d: coffee_data (抽出記録) の産地ID (originId) バックフィル (一度きりのスクリプト)。
//
// 前提: gas/ のclaspデプロイが完了し、EXISTING_SHEET_EXTRA_COLUMNS['coffee_data']
// (産地ID列の冪等追加)が本番に反映済みであること (T4-2d、本スクリプト作成時に
// 対応済み)。
//
// 目的: 実データのcoffee_dataには「産地ID」列自体が存在せず、CoffeeRecord.originId
// が全て空だったため、F1回帰分析(design_matrix.dart)が全行除外されて機能しない
// 問題(T4-2c1で発覚)を解消する。各記録のbeanId(列名は「豆名」)からbean_masterの
// originIdを辿って産地IDをバックフィルする。
//
// 実行方法: dart run tools/backfill_coffee_origin_ids.dart
// 本番Google Sheetsへの書き込みを伴うため、実行前にユーザー確認済みであること。
//
// 冪等: 既に産地IDが設定済みの記録はスキップする。beanIdが無い記録、または
// beanId解決先のbean_masterがoriginId未設定(産地の手動突合が未了)の記録は
// 更新せずスキップ数として報告する。
//
// 注意: SheetsService(lib/services/sheets_service.dart)はflutter_riverpod経由で
// dart:uiに依存し素のdart runでは実行できないため、tools/seed_origin_masters.dart
// と同じパターンでGAS Web Appへ直接http呼び出しを行うスタンドアロン実装にしている。
import 'dart:convert';
import 'package:http/http.dart' as http;

/// デフォルトは`lib/services/sheets_service.dart`の`kGoogleSheetsApiUrl`と同じ値。
/// GAS再デプロイでURLが変わっている場合はコマンドライン引数で上書きできる。
const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

Future<List<Map<String, dynamic>>> _fetchSheet(
    http.Client client, String apiUrl, String sheetName) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=$sheetName'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $sheetName: ${response.statusCode}');
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to fetch $sheetName: ${decoded['error']}');
  }
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
}

Future<void> _updateOriginId(
    http.Client client, String apiUrl, String recordId, String originId) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({
      'sheet': 'coffee_data',
      'action': 'update',
      'data': {'記録ID': recordId, '産地ID': originId},
    }),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため手動で追従する
  // (tools/seed_origin_masters.dartと同じ理由)。
  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to update $recordId: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to update $recordId: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(utf8.decode(response.bodyBytes));
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to update $recordId: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final apiUrl = args.isNotEmpty ? args[0] : _defaultApiUrl;
  final client = http.Client();
  try {
    final beans = await _fetchSheet(client, apiUrl, 'bean_master');
    final beanOriginMap = <String, String>{};
    for (final b in beans) {
      final beanId = (b['豆ID'] ?? '').toString().trim();
      final originId = (b['産地ID'] ?? '').toString().trim();
      if (beanId.isNotEmpty && originId.isNotEmpty) {
        beanOriginMap[beanId] = originId;
      }
    }
    print('bean_master: ${beans.length}件中 originId設定済み ${beanOriginMap.length}件');

    final records = await _fetchSheet(client, apiUrl, 'coffee_data');

    var backfilled = 0;
    var alreadySet = 0;
    var skippedNoBeanId = 0;
    var skippedBeanHasNoOriginId = 0;

    for (final r in records) {
      final recordId = (r['記録ID'] ?? '').toString().trim();
      final currentOriginId = (r['産地ID'] ?? '').toString().trim();
      if (currentOriginId.isNotEmpty) {
        alreadySet++;
        continue;
      }

      final beanId = (r['豆名'] ?? '').toString().trim();
      if (beanId.isEmpty) {
        skippedNoBeanId++;
        continue;
      }

      final resolvedOriginId = beanOriginMap[beanId];
      if (resolvedOriginId == null) {
        skippedBeanHasNoOriginId++;
        continue;
      }

      await _updateOriginId(client, apiUrl, recordId, resolvedOriginId);
      backfilled++;
      print('Backfilled: $recordId -> $resolvedOriginId');
    }

    print('Done. total=${records.length}, backfilled=$backfilled, '
        'alreadySet=$alreadySet, skippedNoBeanId=$skippedNoBeanId, '
        'skippedBeanHasNoOriginId=$skippedBeanHasNoOriginId');
  } finally {
    client.close();
  }
}
