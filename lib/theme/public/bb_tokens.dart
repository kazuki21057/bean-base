// T5-B21: 公開版(Android)の余白・角丸・エレベーション・モーショントークン。
//
// 正本は docs/android_monetization/デザイン方針.md §5。
import 'package:flutter/material.dart';

/// §5.1 `BbSpace`(4dpグリッド)。
abstract final class BbSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// §5.1 レイアウト定数。
abstract final class BbLayout {
  static const double screenPaddingH = 16;
  static const double cardPadding = 16;
  static const double sectionGap = 24;
  static const double rowMinHeight = 56;
  static const double tapTargetMin = 48;

  /// タブレット・横向きで本文が伸び切らないようにする上限幅。
  static const double contentMaxWidth = 640;
  static const double adSlotHeight = 64;
}

/// §5.2 `BbRadius`。
abstract final class BbRadius {
  /// バッジ・小さいタグ。
  static const double xs = 6;

  /// 画像サムネイル。
  static const double sm = 10;

  /// カード・主ボタン・入力欄(入力欄のみ12ではなく14に統一)。
  static const double md = 14;

  /// ダイアログ。
  static const double lg = 20;

  /// ボトムシート上端。
  static const double xl = 28;

  /// チップ・セグメント・FAB。
  static const double pill = 999;
}

/// §5.3 `BbElevation`。
///
/// 値のみを定義する(影の描画自体は各コンポーネント実装=T5-B22で行う)。
/// ダークモードでは影を使わず、段差はサーフェスのトーンで表す規則(§5.3)。
abstract final class BbElevation {
  static const double none = 0;
  static const double raised = 1;
  static const double floating = 3;
  static const double overlay = 6;
  static const double sheet = 8;
}

/// §5.4 `BbMotion`。
abstract final class BbMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  /// リングの弧のアニメ。
  static const Duration ring = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}
