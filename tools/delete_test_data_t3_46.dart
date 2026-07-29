// T3-46: 本番Sheetsに残っているテストデータ4件を削除する(一度きりのスクリプト)。
//
// 実行方法: dart run tools/delete_test_data_t3_46.dart
//
// 対象:
//   bean_master  豆ID=1784590301174 (検証用テスト豆(T4-1e確認・削除予定))
//   bean_master  豆ID=1784590715190 (検証用テスト豆2(T4-1b修正確認・削除予定))
//   coffee_data  記録ID=TEST-REC-NO-REDIRECT
//   coffee_data  記録ID=REC-1770290905531
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため(rules/verification.md教訓)、既存の`tools/migrate_bean_storage_location.dart`
// と同じくSheetsServiceを使わずpackage:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _defaultApiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

/// package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
/// Locationヘッダへ手動でGETし直す(tools/migrate_bean_storage_location.dartと同じパターン)。
/// この302自体はリダイレクト先レスポンス取得の失敗であり、deleteRowの副作用
/// (削除)はGAS側で既に成立していることに注意(rules/verification.md教訓)。
Future<Map<String, dynamic>> _deleteRow(
  http.Client client,
  String apiUrl,
  String sheet,
  Map<String, dynamic> data,
) async {
  var response = await client.post(
    Uri.parse(apiUrl),
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': sheet, 'action': 'delete', 'data': data}),
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
  return json.decode(response.body) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  final apiUrl = args.isNotEmpty ? args[0] : _defaultApiUrl;
  final client = http.Client();
  try {
    final targets = [
      ('bean_master', {'豆ID': '1784590301174'}, '検証用テスト豆(T4-1e確認・削除予定)'),
      ('bean_master', {'豆ID': '1784590715190'}, '検証用テスト豆2(T4-1b修正確認・削除予定)'),
      ('coffee_data', {'記録ID': 'TEST-REC-NO-REDIRECT'}, 'Test Bean No Redirect'),
      ('coffee_data', {'記録ID': 'REC-1770290905531'}, 'REC-1770290905531'),
    ];

    for (final (sheet, data, label) in targets) {
      final result = await _deleteRow(client, apiUrl, sheet, data);
      if (result.containsKey('error')) {
        stdout.writeln('❌ $sheet / $label: ${result['error']}');
      } else {
        stdout.writeln('✅ $sheet / $label: ${json.encode(result)}');
      }
    }
  } finally {
    client.close();
  }
}
