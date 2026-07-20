// T4-1a/T4-1c: origin_master シートへの初期15件投入 (一度きりのスクリプト)。
//
// 前提: gas/ の clasp デプロイが完了し、origin_master シートが
// (ensureSheet_ により) ヘッダー行付きで自動生成済みであること。
//
// 実行方法: dart run tools/seed_origin_masters.dart
//
// 冪等: 実行のたびに既存の産地ID一覧を取得し、未投入のものだけ追加する。
//
// 注意: `SheetsService`(lib/services/sheets_service.dart)は
// `flutter_riverpod`(→Flutter→dart:ui)に依存しており、素の`dart run`では
// `dart:ui`が解決できずロードできない(要Flutterエンジン)。そのため本スクリプトは
// SheetsServiceを再利用せず、同じGAS Web App(text/plain POSTでCORSプリフライトを
// 回避するパターン、`rules/verification.md`の教訓参照)に対して直接http呼び出しを
// 行う、独立したスタンドアロン実装にしている。
import 'dart:convert';
import 'package:bean_base/models/origin_master.dart';
import 'package:http/http.dart' as http;

/// デフォルトは`lib/services/sheets_service.dart`の`kGoogleSheetsApiUrl`と
/// 同じ値。GAS再デプロイでURLが変わっている場合はコマンドライン引数
/// (`dart run tools/seed_origin_masters.dart <URL>`)で上書きできる。
const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

/// GASのレスポンスは常にHTTP 200/302で返り、失敗は`{"error": "..."}`という
/// JSON本文でのみ判別できる(ステータスコードだけでは成否が分からない)。
Future<Set<String>> _fetchExistingIds(http.Client client, String apiUrl) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=origin_master'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch origin_master: ${response.statusCode}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception(
      'origin_masterシートが見つかりません(${decoded['error']})。'
      'gas/README.mdの手順でclasp push(ensureSheet_によるシート自動生成)を'
      '完了してから再実行してください。',
    );
  }
  if (decoded is! List) return {};
  return decoded
      .whereType<Map>()
      .map((row) => row['産地ID']?.toString())
      .whereType<String>()
      .toSet();
}

Future<void> _postOrigin(http.Client client, String apiUrl, OriginMaster origin) async {
  final data = {
    '産地ID': origin.id,
    '国コード': origin.countryCode,
    '産地名': origin.nameJa,
    '産地名(英)': origin.nameEn,
    '地域': origin.region,
  };
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': 'origin_master', 'action': 'add', 'data': data}),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
  // Locationヘッダ(script.googleusercontent.com/macros/echo)へ手動でGETし直す
  // (curl -Lと同じ挙動)。
  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('Failed to add ${origin.id}: 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('Failed to add ${origin.id}: ${response.statusCode} ${response.body}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('Failed to add ${origin.id}: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final apiUrl = args.isNotEmpty ? args[0] : _defaultApiUrl;
  final client = http.Client();
  try {
    final existingIds = await _fetchExistingIds(client, apiUrl);

    var added = 0;
    var skipped = 0;
    for (final origin in kInitialOriginMasters) {
      if (existingIds.contains(origin.id)) {
        skipped++;
        continue;
      }
      await _postOrigin(client, apiUrl, origin);
      added++;
      print('Added: ${origin.id} (${origin.nameJa})');
    }

    print('Done. added=$added, skipped=$skipped, total=${kInitialOriginMasters.length}');
  } finally {
    client.close();
  }
}
