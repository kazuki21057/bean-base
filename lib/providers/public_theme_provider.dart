// T5-B21: 公開版(Android)のテーマモード(ライト/ダーク/端末に合わせる)。
//
// 正本は docs/android_monetization/デザイン方針.md §6・D2・D6。
// 既定は`ThemeMode.light`固定(D6。`ThemeMode.system`への変更はT5-B27で行う)。
// `shared_preferences`への読み書きは`lib/providers/theme_provider.dart`の
// `loadSavedMainColor`/`saveMainColor`と同じパターン。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kPublicThemeModePrefsKey = 'public_theme_mode';

/// P900(設定)の3択セグメント(ライト/ダーク/端末に合わせる)で切り替える
/// テーマモード。既定値は`ThemeMode.light`(D6)。
final publicThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

String _themeModeToPrefsValue(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

ThemeMode? _themeModeFromPrefsValue(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    default:
      return null;
  }
}

/// 起動時に保存済みのテーマモードを読み込む。未保存なら`null`を返す
/// (呼び出し側で`publicThemeModeProvider`の既定値`ThemeMode.light`を使う)。
Future<ThemeMode?> loadSavedPublicThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(kPublicThemeModePrefsKey);
  return _themeModeFromPrefsValue(value);
}

/// P900のテーマ切替で選んだモードを保存する。
Future<void> savePublicThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kPublicThemeModePrefsKey, _themeModeToPrefsValue(mode));
}
