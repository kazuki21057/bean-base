// T3-59: 既存 bean_master レコードに保存場所の初期値を一括設定する
// (一度きりのスクリプト、再実行安全)。
//
// 実行方法: dart run tools/migrate_bean_storage_location.dart
//
// 冪等: 本番bean_masterを取得し、保存場所が未設定(空/欠損)の行のみ
// '職場'で更新する。既に値が入っている行は上書きしない(ユーザーが
// あとで手動で「家」に振り分ける前提)。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため(rules/verification.md教訓)、既存の`tools/migrate_stores.dart`
// と同じくSheetsServiceを使わずpackage:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

Future<List<Map<String, dynamic>>> _fetchBeans(http.Client client, String apiUrl) async {
  final response = await client.get(Uri.parse('$apiUrl?sheet=bean_master'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch bean_master: ${response.statusCode}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('bean_master取得エラー: ${decoded['error']}');
  }
  return (decoded as List).cast<Map<String, dynamic>>();
}

/// package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
/// Locationヘッダへ手動でGETし直す(tools/migrate_original_data.dartと同じパターン)。
/// この302自体はリダイレクト先レスポンス取得の失敗であり、updateRowの副作用
/// (書き込み)はGAS側で既に成立していることに注意(rules/verification.md教訓)。
Future<void> _updateRow(http.Client client, String apiUrl, Map<String, dynamic> data) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': 'bean_master', 'action': 'update', 'data': data}),
  );

  if (response.statusCode == 302) {
    final location = response.headers['location'];
    if (location == null) {
      throw Exception('POST returned 302 but no Location header');
    }
    response = await client.get(Uri.parse(location));
  }

  if (response.statusCode != 200) {
    throw Exception('POST failed (${response.statusCode}): ${response.body}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('GAS error: ${decoded['error']}');
  }
}

Future<void> main(List<String> args) async {
  final apiUrl = args.isNotEmpty ? args[0] : _defaultApiUrl;
  final client = http.Client();
  try {
    final beans = await _fetchBeans(client, apiUrl);
    var updated = 0;
    var skipped = 0;
    for (final bean in beans) {
      final id = bean['豆ID']?.toString();
      final name = bean['豆名']?.toString() ?? '';
      if (id == null || id.isEmpty) continue;
      final current = bean['保存場所']?.toString().trim() ?? '';
      if (current.isNotEmpty) {
        skipped++;
        continue;
      }
      stdout.writeln('[bean_master] $id ($name) の保存場所を「職場」に設定');
      await _updateRow(client, apiUrl, {'豆ID': id, '保存場所': '職場'});
      updated++;
    }
    stdout.writeln('完了: $updated 件更新 / $skipped 件は既に値ありでスキップ(全${beans.length}件中)');
  } finally {
    client.close();
  }
}
