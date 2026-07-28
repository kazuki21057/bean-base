// T3-67(docs/store_master_design.md§4/§6): store_master シートへの初期7店投入
// (一度きりのスクリプト、tools/seed_origin_masters.dartと同型)。
//
// 前提: gas/ の clasp デプロイが完了し、store_master シートが
// (ensureSheet_ により) ヘッダー行付きで自動生成済みであること。
//
// 実行方法: dart run tools/migrate_stores.dart
//
// 冪等: 実行のたびに既存の購入店ID一覧を取得し、未投入のものだけ追加する
// (IDは固定スラッグのため再実行しても重複登録されない)。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため(rules/verification.md教訓)、既存の`tools/seed_origin_masters.dart`
// と同じくSheetsServiceを使わずpackage:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'package:bean_base/models/store_master.dart';
import 'package:http/http.dart' as http;

/// デフォルトは`lib/services/sheets_service.dart`の`kGoogleSheetsApiUrl`と
/// 同じ値。GAS再デプロイでURLが変わっている場合はコマンドライン引数
/// (`dart run tools/migrate_stores.dart <URL>`)で上書きできる。
const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

/// GASのレスポンスは常にHTTP 200/302で返り、失敗は`{"error": "..."}`という
/// JSON本文でのみ判別できる(ステータスコードだけでは成否が分からない)。
Future<Set<String>> _fetchExistingIds(http.Client client, String apiUrl) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=store_master'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch store_master: ${response.statusCode}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception(
      'store_masterシートが見つかりません(${decoded['error']})。'
      'gas/README.mdの手順でclasp push(ensureSheet_によるシート自動生成)を'
      '完了してから再実行してください。',
    );
  }
  if (decoded is! List) return {};
  return decoded
      .whereType<Map>()
      .map((row) => row['購入店ID']?.toString())
      .whereType<String>()
      .toSet();
}

Map<String, dynamic> _toRow(StoreMaster store) {
  return {
    '購入店ID': store.id,
    '店名': store.name,
    '正式名称': store.formalName,
    'URL': store.url,
    '都道府県': store.prefecture,
    '住所': store.address,
    'オンライン販売': store.hasOnlineShop,
    '実店舗': store.hasPhysicalStore,
    '焙煎所併設': store.hasRoastery,
    '取扱豆の傾向': store.beanTendency,
    'メモ': store.memo,
    '店舗画像URL': store.imageUrl,
    'SNS': store.snsUrl,
    '営業時間': store.businessHours,
    '定休日': store.closedDays,
    '電話番号': store.phone,
    '開業年': store.openedYear,
    '情報取得元': store.sourceUrl,
    '情報取得日': store.infoFetchedAt?.toIso8601String(),
  };
}

Future<void> _postStore(http.Client client, String apiUrl, StoreMaster store) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': 'store_master', 'action': 'add', 'data': _toRow(store)}),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
  // Locationヘッダ(script.googleusercontent.com/macros/echo)へ手動でGETし直す
  // (curl -Lと同じ挙動)。
  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to add ${store.id}: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to add ${store.id}: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to add ${store.id}: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final apiUrl = args.isNotEmpty ? args[0] : _defaultApiUrl;
  final client = http.Client();
  try {
    final existingIds = await _fetchExistingIds(client, apiUrl);

    var added = 0;
    var skipped = 0;
    for (final store in kInitialStoreMasters) {
      if (existingIds.contains(store.id)) {
        skipped++;
        continue;
      }
      await _postStore(client, apiUrl, store);
      added++;
      print('Added: ${store.id} (${store.name})');
    }

    print('Done. added=$added, skipped=$skipped, total=${kInitialStoreMasters.length}');
  } finally {
    client.close();
  }
}
