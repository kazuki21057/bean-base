import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bean_base/config/app_edition.dart';
import 'package:bean_base/services/ai_key_service.dart';

/// T5-B4(E-4): AIキー取得経路の集約先である[AiKeyService]の単体テスト。
/// 正本は docs/android_monetization/コードベース構成方針.md §10.3の4番の表。
void main() {
  group('AiKeyService (ownKey)', () {
    test('saveKeyで保存した値をreadKeyで取得できる', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AiKeyService(AiKeyMode.ownKey);

      await service.saveKey('abc');
      final result = await service.readKey();

      expect(result, 'abc');
    });

    test('未設定/空白のみの値はnullを返す', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AiKeyService(AiKeyMode.ownKey);

      final unset = await service.readKey();
      expect(unset, isNull);

      await service.saveKey('   ');
      final blank = await service.readKey();
      expect(blank, isNull);
    });
  });

  group('AiKeyService (proxy)', () {
    test('readKey/saveKeyはどちらもAiKeyUnavailableExceptionをthrowする', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AiKeyService(AiKeyMode.proxy);
      const expectedMessage = 'この版のAI機能はサーバ経由で提供されます。現在準備中のためご利用いただけません。';

      await expectLater(
        () => service.readKey(),
        throwsA(
          isA<AiKeyUnavailableException>().having((e) => e.message, 'message', expectedMessage),
        ),
      );
      await expectLater(
        () => service.saveKey('x'),
        throwsA(
          isA<AiKeyUnavailableException>().having((e) => e.message, 'message', expectedMessage),
        ),
      );
    });
  });

  group('aiKeyServiceProvider', () {
    test('kPersonalEditionではrequiresUserKeyがtrue', () {
      final container = ProviderContainer(
        overrides: [appEditionProvider.overrideWithValue(kPersonalEdition)],
      );
      addTearDown(container.dispose);

      expect(container.read(aiKeyServiceProvider).requiresUserKey, isTrue);
    });

    test('kPublicEditionではrequiresUserKeyがfalse', () {
      final container = ProviderContainer(
        overrides: [appEditionProvider.overrideWithValue(kPublicEdition)],
      );
      addTearDown(container.dispose);

      expect(container.read(aiKeyServiceProvider).requiresUserKey, isFalse);
    });
  });
}
