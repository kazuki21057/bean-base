// T5-A104: GET/POSTのタイムアウト・リトライ挙動の単体テスト。
// 背景: T5-A103の調査で、GET失敗を`catch(e) { return []; }`で握り潰していたことが
// integration_testスモークの間欠的失敗(件数不変・GAS接続断)の根本原因と判明したため、
// タイムアウト・再試行・例外送出(SheetsFetchException)の挙動をここで固定する。
import 'dart:convert';

import 'package:bean_base/services/sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SheetsService GETの再試行(T5-A104)', () {
    test('2回連続失敗→3回目成功でデータが返り、呼び出し回数は3', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount < 3) {
          throw http.ClientException('接続に失敗しました');
        }
        return http.Response(
          json.encode([
            {'豆ID': 'BEAN-001', '豆名': 'Geisha'}
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      final beans = await service.getBeans();

      expect(callCount, 3);
      expect(beans.length, 1);
      expect(beans.first.id, 'BEAN-001');
    });

    test('3回とも失敗するとSheetsFetchExceptionがthrowされ、attemptsは3', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        throw http.ClientException('接続に失敗しました');
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      await expectLater(
        () => service.getBeans(),
        throwsA(
          isA<SheetsFetchException>().having((e) => e.attempts, 'attempts', 3),
        ),
      );
      expect(callCount, 3);
    });

    test('429は再試行される', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount < 3) {
          return http.Response('Too Many Requests', 429);
        }
        return http.Response(
          json.encode([
            {'豆ID': 'BEAN-002', '豆名': 'Bourbon'}
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      final beans = await service.getBeans();

      expect(callCount, 3);
      expect(beans.length, 1);
    });

    test('404は再試行せず即座にthrowされる(呼び出し回数1)', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('Not Found', 404);
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      await expectLater(
        () => service.getBeans(),
        throwsA(
          isA<SheetsFetchException>().having((e) => e.attempts, 'attempts', 1),
        ),
      );
      expect(callCount, 1);
    });
  });

  group('SheetsService POSTの書き込み(T5-A104)', () {
    test('書き込みAPIは失敗時に再試行しない(呼び出し回数1)', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('Internal Server Error', 500);
      });

      final service = SheetsService(
        client: client,
        retryBackoff: const [Duration.zero, Duration.zero],
      );

      await expectLater(
        () => service.deleteBean('BEAN-001'),
        throwsA(isA<Exception>()),
      );
      expect(callCount, 1);
    });
  });
}
