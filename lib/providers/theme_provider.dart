import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kMainColorPrefsKey = 'main_color_value';

/// メインカラーの選択肢(090設定画面のプリセット)。
const List<Color> mainColorPresets = [
  Color(0xFF6D4C41), // kEspresso相当(デフォルト)
  Color(0xFF2F3E33), // 黒板グリーン
  Color(0xFF37474F), // ブルーグレー
  Color(0xFF4E342E), // ダークブラウン
  Color(0xFF6A1B9A), // パープル
];

/// Cycle 20 T2-7: 090(設定)の「メインカラー」で選択したシードカラー。
/// `MaterialApp`の`ThemeData.colorScheme`(NavigationRail/ボタン等の標準
/// ウィジェット)に反映される。コーヒートーンパレット
/// (`create_form_widgets.dart`のkEspresso等、黒板風テーマ含む)は固定値の
/// ハードコードのため、この設定を変えても見た目は変化しない
/// (090の説明文でその旨を明示する)。
final mainColorProvider = StateProvider<Color>((ref) => mainColorPresets.first);

Future<Color?> loadSavedMainColor() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getInt(kMainColorPrefsKey);
  return value != null ? Color(value) : null;
}

Future<void> saveMainColor(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kMainColorPrefsKey, color.toARGB32());
}
