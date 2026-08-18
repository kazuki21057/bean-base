// ignore_for_file: always_use_package_imports
// T5-B4(E-4): AIキー取得経路を AppEdition.aiKeyMode 経由の1箇所へ集約する。
//
// 正本は docs/android_monetization/コードベース構成方針.md §10「E-4(T5-B4)実装仕様」。
// `proxy`モード(public版のサーバ中継)の実体はT5-B41まで存在しないため、
// ここでは例外を投げるプレースホルダに留める(§10.2 D6)。
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_edition.dart';

/// SharedPreferences 上のGemini APIキーの保存先キー。
/// この文字列を他のファイルに書かないこと(T5-B4で集約した)。
const String kGeminiApiKeyPrefsKey = 'gemini_api_key';

/// AIキーがこのエディションでは取得できないことを表す例外。
class AiKeyUnavailableException implements Exception {
  final String message;
  const AiKeyUnavailableException(this.message);
  @override
  String toString() => message;
}

/// AIキーの取得・保存を [AppEdition.aiKeyMode] に応じて切り替える。
class AiKeyService {
  final AiKeyMode mode;

  const AiKeyService(this.mode);

  static const String _proxyUnavailableMessage =
      'この版のAI機能はサーバ経由で提供されます。現在準備中のためご利用いただけません。';

  /// APIキーを取得する。未設定(ownKey時に空)は`null`を返す。
  /// `proxy`モードでは[AiKeyUnavailableException]をthrowする。
  Future<String?> readKey() async {
    if (mode == AiKeyMode.proxy) {
      debugPrint('[Antigravity] AIキー取得: proxyモードは未実装(T5-B41で中継サーバを実装予定)');
      throw const AiKeyUnavailableException(_proxyUnavailableMessage);
    }
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(kGeminiApiKeyPrefsKey)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// APIキーを保存する。`proxy`モードでは[AiKeyUnavailableException]をthrowする。
  Future<void> saveKey(String key) async {
    if (mode == AiKeyMode.proxy) {
      debugPrint('[Antigravity] AIキー取得: proxyモードは未実装(T5-B41で中継サーバを実装予定)');
      throw const AiKeyUnavailableException(_proxyUnavailableMessage);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kGeminiApiKeyPrefsKey, key.trim());
    debugPrint('[Antigravity] Action: Gemini APIキーを保存');
  }

  /// ユーザー自身がキーを入力する必要があるか(=ownKeyモードか)。
  bool get requiresUserKey => mode == AiKeyMode.ownKey;
}

final aiKeyServiceProvider = Provider<AiKeyService>(
  (ref) => AiKeyService(ref.watch(appEditionProvider).aiKeyMode),
);
