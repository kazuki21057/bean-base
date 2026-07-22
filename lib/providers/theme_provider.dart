import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kMainColorPrefsKey = 'main_color_value';

/// メインカラーの選択肢(090設定画面のプリセット)。
/// 1色目は既存の`kEspresso`(create_form_widgets.dart)と同値にしてあり、
/// 未変更時は従来の見た目と完全に一致する。
const List<Color> mainColorPresets = [
  Color(0xFF3E2723), // kEspresso(デフォルト)
  Color(0xFF2F3E33), // 黒板グリーン
  Color(0xFF37474F), // ブルーグレー
  Color(0xFF4E342E), // ダークブラウン
  Color(0xFF6A1B9A), // パープル
];

/// Cycle 20 T2-7 / Cycle 27 T3-9: 090(設定)の「メインカラー」で選択した
/// シードカラー。`MaterialApp`の`ThemeData.colorScheme`(NavigationRail等の
/// 標準ウィジェット)に加え、T3-9で各画面のAppBar([MockScreenScaffold]/
/// [CreateFormScaffold])・ダッシュボードの黒板風背景にも反映されるように
/// なった([boardBackgroundFor]参照)。ただし各画面内部のコーヒートーン
/// アクセント(ボタンの一部・チップ・グラフの配色等、`kMocha`/`kLatte`/
/// `kAccent`等)は固定値のハードコードのままで、この設定を変えても見た目は
/// 変化しない(090の説明文でその旨を明示する)。
final mainColorProvider = StateProvider<Color>((ref) => mainColorPresets.first);

/// [mainColor] の色相・彩度を保ちながら、明度をチョーク文字が読める暗さに
/// 固定した黒板背景色を導出する(黒板風テーマは白系の文字を前提とするため、
/// 明るい系統のメインカラーを選んでも一定の暗さを保つ必要がある)。
Color boardBackgroundFor(Color mainColor) {
  final hsl = HSLColor.fromColor(mainColor);
  return hsl
      .withLightness(0.22)
      .withSaturation(hsl.saturation.clamp(0.15, 0.6))
      .toColor();
}

Future<Color?> loadSavedMainColor() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getInt(kMainColorPrefsKey);
  return value != null ? Color(value) : null;
}

Future<void> saveMainColor(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kMainColorPrefsKey, color.toARGB32());
}
