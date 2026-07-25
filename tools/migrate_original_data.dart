// T3-38: original-data/ にユーザーが投入した最新データを本番Sheetsへ移植する
// (一度きりのスクリプト、再実行安全)。
//
// 実行方法: dart run tools/migrate_original_data.dart
//
// 冪等: 本番のbean_master・coffee_dataから既存ID一覧を取得し、
// original-data/配下のCSVに存在するが本番にまだ無いIDのみを追加する
// (二重登録防止、T3-38の終了条件)。既存レコードの更新・削除は行わない。
//
// 対象外(着手前に`original-data/old/`との差分を確認し、変更が無いことを確認済み):
// mill_master・dripper_master・filter_master・methods_master・pouring_steps。
//
// 注意: `SheetsService`はflutter_riverpod(→dart:ui)に依存し素の`dart run`では
// ロードできないため(rules/verification.md教訓)、既存の`tools/seed_origin_masters.dart`
// と同じくSheetsServiceを使わずpackage:httpで直接GAS Web Appを叩く独立実装にしている。
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _apiUrl =
    'https://script.google.com/macros/s/AKfycbxqhFoge1C2jYwoyPcS3BDRypCyOjc7rV6qd3FwwMaPBQ42MyrtMv8-NdcAIlvpl0Ao/exec';

Future<List<Map<String, dynamic>>> _fetchSheet(http.Client client, String sheet) async {
  final response = await client.get(Uri.parse('$_apiUrl?sheet=$sheet'));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch $sheet: ${response.statusCode}');
  }
  final decoded = json.decode(response.body);
  if (decoded is Map && decoded.containsKey('error')) {
    throw Exception('$sheet: ${decoded['error']}');
  }
  return (decoded as List).cast<Map<String, dynamic>>();
}

Future<void> _addRow(http.Client client, String sheet, Map<String, dynamic> data) async {
  var response = await client.post(
    Uri.parse(_apiUrl),
    // text/plain でCORSプリフライトを回避する既存パターン(rules/verification.md参照)。
    headers: {'Content-Type': 'text/plain'},
    body: json.encode({'sheet': sheet, 'action': 'add', 'data': data}),
  );

  // package:http はPOSTの302リダイレクトを自動追従しないため、GASが返す
  // Locationヘッダへ手動でGETし直す(tools/seed_origin_masters.dartと同じパターン)。
  // この302自体はリダイレクト先レスポンス取得の失敗であり、addRowの副作用(行追加)は
  // GAS側で既に成立していることに注意(rules/verification.md教訓)。
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

/// 単純な `,` split で読む(対象CSVにクォート・埋め込みカンマが無いことを
/// 着手時にPythonで全行検証済み)。
List<List<String>> _parseCsv(String path) {
  final lines = File(path).readAsLinesSync();
  return lines
      .skip(1)
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.split(','))
      .toList();
}

Future<void> main() async {
  final client = http.Client();
  try {
    // --- bean_master: 豆ID,豆名,焙煎度,産地,豆の説明,豆画像URL ---
    final existingBeans = await _fetchSheet(client, 'bean_master');
    final existingBeanIds = existingBeans.map((b) => b['豆ID'].toString()).toSet();

    final beanRows = _parseCsv('original-data/coffee_masters_template - 豆マスター.csv');
    var beansAdded = 0;
    for (final cols in beanRows) {
      final id = cols[0];
      if (id.isEmpty || existingBeanIds.contains(id)) continue;
      final data = <String, dynamic>{
        '豆ID': id,
        '豆名': cols[1],
        '焙煎度': cols[2],
        '産地': cols[3],
        // cols[4]=豆の説明: BeanMasterに対応フィールドが無いため保存しない(既知の仕様)。
        // cols[5]=豆画像URL: CSVはローカルファイルパス(豆マスター_Images/...)を指しており
        // 画像実体が手元に無いため移植しない(空のまま。後日ユーザーが011/012で再アップロード)。
      };
      stdout.writeln('[bean_master] adding $id (${cols[1]})');
      await _addRow(client, 'bean_master', data);
      beansAdded++;
    }
    stdout.writeln(
        'bean_master: $beansAdded added / ${beanRows.length} total in CSV (残りは既存)');

    // --- coffee_data: 記録ID,記録日,ミル,ドリッパー,フィルター,豆名,焙煎度,産地,豆の量(g),
    // 挽き目,抽出方法,味,濃度,湯温(℃),蒸らし湯量(ml),湯量(ml),蒸らし時間(秒),抽出時間(秒),
    // 香り(1-10),酸味(1-10),苦味(1-10),甘味(1-10),複雑さ(1-10),フレーバー(1-10),総合評価(1-10),
    // コメント,ミル写真URL,ドリッパ写真URL,フィルタ写真URL,豆写真URL ---
    final existingRecords = await _fetchSheet(client, 'coffee_data');
    final existingRecordIds = existingRecords.map((r) => r['記録ID'].toString()).toSet();

    final recordRows = _parseCsv('original-data/coffee_data - coffee_data.csv');
    var recordsAdded = 0;
    for (final cols in recordRows) {
      final id = cols[0];
      if (id.isEmpty || existingRecordIds.contains(id)) continue;
      final data = <String, dynamic>{
        '記録ID': id,
        '記録日': cols[1],
        'ミル': cols[2],
        'ドリッパー': cols[3],
        'フィルター': cols[4],
        '豆名': cols[5],
        '焙煎度': cols[6],
        '産地': cols[7],
        '豆の量(g)': cols[8],
        '挽き目': cols[9],
        '抽出方法': cols[10],
        '味': cols[11],
        '濃度': cols[12],
        '湯温(℃)': cols[13],
        '蒸らし湯量(ml)': cols[14],
        '湯量(ml)': cols[15],
        '蒸らし時間(秒)': cols[16],
        '抽出時間(秒)': cols[17],
        '香り(1-10)': cols[18],
        '酸味(1-10)': cols[19],
        '苦味(1-10)': cols[20],
        '甘味(1-10)': cols[21],
        '複雑さ(1-10)': cols[22],
        'フレーバー(1-10)': cols[23],
        '総合評価(1-10)': cols[24],
        'コメント': cols[25],
      };
      stdout.writeln('[coffee_data] adding $id (${cols[1]})');
      await _addRow(client, 'coffee_data', data);
      recordsAdded++;
    }
    stdout.writeln(
        'coffee_data: $recordsAdded added / ${recordRows.length} total in CSV (残りは既存)');
  } finally {
    client.close();
  }
}
