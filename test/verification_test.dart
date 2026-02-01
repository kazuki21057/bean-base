import 'dart:convert';
import 'package:bean_base/models/coffee_record.dart';
import 'package:bean_base/services/sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SheetsService Verification Tests', () {
    test('getCoffeeRecords handles Japanese keys and null values correctly', () async {
      final mockData = [
        {
          '記録ID': 'REC-001',
          '記録日': '2023-01-01T10:00:00.000',
          '豆名': 'Ethiopia Yirgacheffe',
          '豆の量(g)': 20.0,
          '味': null, // Null value checks
          '総合評価': 5
        }
      ];

      final client = MockClient((request) async {
        if (request.url.toString().contains('sheet=coffee_data')) {
          return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('[]', 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();

      expect(records.length, 1);
      final record = records.first;
      expect(record.id, 'REC-001');
      expect(record.beanId, 'Ethiopia Yirgacheffe');
      expect(record.beanWeight, 20.0); // Should handle num
      expect(record.taste, ''); // Should be sanitized from null to empty string
      expect(record.scoreOverall, 5);
    });

    test('getCoffeeRecords handles empty strings in numeric fields', () async {
      final mockData = [
        {
          '記録ID': 'REC-003',
          '記録日': '2023-01-01T10:00:00.000',
          '豆名': 'Brazil',
          '豆の量(g)': '', // Empty string for double failure check
          '総合評価': ''  // Empty string for int failure check
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();

      expect(records.length, 1);
      final record = records.first;
      expect(record.beanWeight, 0.0); // Default value
      expect(record.scoreOverall, 0); // Default value
    });

    test('getCoffeeRecords handles malformed date and string numbers', () async {
      final mockData = [
        {
          '記録ID': 'REC-004',
          '記録日': 'INVALID-DATE', // Should default to now
          '豆名': 'Test Bean',
          '豆の量(g)': '20.5', // String double
          '総合評価': '8' // String int
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();

      expect(records.length, 1);
      final record = records.first;
      expect(record.beanWeight, 20.5);
      expect(record.scoreOverall, 8);
      // Date should be recent (defaulted)
      expect(record.brewedAt.difference(DateTime.now()).inMinutes.abs() < 1, true);
    });

    test('getCoffeeRecords handles slash dates and Japanese keys', () async {
      final mockData = [
        {
          '記録ID': 'REC-SLASH',
          '記録日': '2025/04/14 7:39',
          '豆名': 'Test Bean',
          '豆の量(g)': 15.0,
          '抽出方法': 'method001', // New key mapping check
          '湯温(°C)': 92, // New key mapping
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();

      expect(records.length, 1);
      final record = records.first;
      expect(record.id, 'REC-SLASH');
      expect(record.beanWeight, 15.0);
      expect(record.methodId, 'method001');
      expect(record.temperature, 92.0);
      
      // Verify date parsing
      expect(record.brewedAt.year, 2025);
      expect(record.brewedAt.month, 4);
      expect(record.brewedAt.day, 14);
      expect(record.brewedAt.hour, 7);
      expect(record.brewedAt.minute, 39);
    });

    test('getCoffeeRecords defaults brewedAt if missing', () async {
      final mockData = [
        {
          '記録ID': 'REC-002',
          // '記録日' is missing
          '豆名': 'Colombia',
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();

      expect(records.length, 1);
      expect(records.first.id, 'REC-002');
      expect(records.first.brewedAt, isNotNull);
      // Verify it is recent (within last minute)
      final brewedAt = records.first.brewedAt;
      expect(brewedAt.difference(DateTime.now()).inMinutes.abs() < 1, true);
    });

    test('getBeans handles Japanese keys', () async {
      final mockData = [
        {
          '豆ID': 'BEAN-001',
          '豆名': 'Geisha',
          '焙煎度': 'Light',
          '産地': 'Panama',
          '豆画像URL': 'http://example.com/bean.jpg'
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final beans = await service.getBeans();

      expect(beans.length, 1);
      final bean = beans.first;
      expect(bean.id, 'BEAN-001');
      expect(bean.name, 'Geisha');
      expect(bean.roastLevel, 'Light');
      expect(bean.origin, 'Panama');
      expect(bean.imageUrl, 'http://example.com/bean.jpg');
    });
    
    test('getMethods handles Japanese keys', () async {
      final mockData = [
        {
          'メソッドID': 'M-001',
          'メソッド名': 'V60 Standard',
          '基準豆量(g)': 15,
          '基準湯量(ml)': 250
        }
      ];

      final client = MockClient((request) async {
         return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final service = SheetsService(client: client);
      final methods = await service.getMethods();

      expect(methods.length, 1);
      expect(methods.first.id, 'M-001');
      expect(methods.first.name, 'V60 Standard');
      expect(methods.first.baseBeanWeight, 15);
      expect(methods.first.baseWaterAmount, 250);
    });

    test('Should handle non-List response gracefully', () async {
       final client = MockClient((request) async {
         return http.Response('{"error": "Some error"}', 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      
      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();
      expect(records, isEmpty);
    });

    test('Should handle malformed JSON records gracefully', () async {
       final client = MockClient((request) async {
         // Second item is not a map
         return http.Response('[{"記録ID": "1"}, "INVALID", {"記録ID": "3"}]', 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });
      
      final service = SheetsService(client: client);
      final records = await service.getCoffeeRecords();
      // Should skip the invalid one but parse valid ones if logic allows
      expect(records.length, 2); 
      expect(records[0].id, '1');
      expect(records[1].id, '3');
    });
  });
}
