// 受け入れテスト: T5-A104
// 完了条件(委譲プロンプトより): GET/POSTにタイムアウト・リトライを追加し、
// GET失敗を`catch(e) { return []; }`で握り潰さずSheetsFetchExceptionをthrowする。
// 以下4項目を実データに近い形(コーヒー記録・豆マスタのJapanese-key JSON)で検証する:
//  1. 2回連続失敗→3回目成功でデータが返る(呼び出し回数3)
//  2. 3回とも失敗でSheetsFetchExceptionがthrowされattempts==3
//  3. 429は再試行される・404は再試行せず即throw(呼び出し回数1)
//  4. 書き込みAPI(_postData相当)は失敗時に再試行しない(呼び出し回数1)
//
// 受入: test/acceptance/t5_a104_acceptance_test.dart
import 'dart:async';
import 'dart:convert';

import 'package:bean_base/models/bean_master.dart';
import 'package:bean_base/services/sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('受け入れ(T5-A104)', () {
    test('1. コーヒー記録取得: 2回タイムアウト→3回目成功でデータが返る(呼び出し回数3)', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount < 3) {
          throw TimeoutException('GAS応答なし');
        }
        return http.Response(
          json.encode([
            {
              '記録ID': 'REC-100',
              '記録日': '2026-08-20T09:00:00.000',
              '豆名': 'Ethiopia',
              '豆の量(g)': 18.0,
              '総合評価(1-10)': 8,
            }
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      final records = await service.getCoffeeRecords();

      expect(callCount, 3, reason: '2回失敗後3回目で成功するまでリトライすること');
      expect(records.length, 1);
      expect(records.first.id, 'REC-100');
    });

    test('2. 豆マスタ取得: 3回ともソケットエラーで失敗するとSheetsFetchExceptionがthrowされattempts==3', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('', 503);
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      SheetsFetchException? caught;
      try {
        await service.getBeans();
      } on SheetsFetchException catch (e) {
        caught = e;
      }

      expect(caught, isNotNull, reason: '全試行失敗時は[]ではなくSheetsFetchExceptionがthrowされること');
      expect(caught!.attempts, 3);
      expect(callCount, 3);
      // [] を返してデータ0件に見せかけていた旧挙動(件数不変バグ)ではないことの確認。
      expect(caught.toString(), contains('bean_master'));
    });

    test('3. 豆マスタ取得: 429は再試行され、404は再試行せず呼び出し回数1で即throw', () async {
      var call429Count = 0;
      final client429 = MockClient((request) async {
        call429Count++;
        if (call429Count < 2) {
          return http.Response('Too Many Requests', 429);
        }
        return http.Response(
          json.encode([
            {'豆ID': 'BEAN-100', '豆名': 'Yirgacheffe'}
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service429 = SheetsService(
        client: client429,
        retryBackoff: const [Duration.zero, Duration.zero],
      );
      final beans = await service429.getBeans();
      expect(call429Count, 2, reason: '429は再試行対象であること');
      expect(beans.single.id, 'BEAN-100');

      var call404Count = 0;
      final client404 = MockClient((request) async {
        call404Count++;
        return http.Response('Not Found', 404);
      });
      final service404 = SheetsService(
        client: client404,
        retryBackoff: const [Duration.zero, Duration.zero],
      );
      await expectLater(
        () => service404.getBeans(),
        throwsA(isA<SheetsFetchException>().having((e) => e.attempts, 'attempts', 1)),
      );
      expect(call404Count, 1, reason: '404は再試行せず即座に失敗させること');
    });

    test('4. 豆マスタ追加(書き込みAPI)は失敗時に再試行しない(呼び出し回数1)', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('Internal Server Error', 500);
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      final bean = BeanMaster(
        id: 'BEAN-NEW',
        name: 'テスト豆',
        roastLevel: '中煎り',
        origin: 'ブラジル',
      );

      await expectLater(
        () => service.addBean(bean),
        throwsA(isA<Exception>()),
        reason: '書き込み失敗時に例外がthrowされること(呼び出し元がエラーに気づけること)',
      );
      expect(callCount, 1, reason: '書き込み系(_postData)は冪等でないため再試行しないこと');
    });
  });
}
