import 'dart:math';
import 'package:flutter/material.dart';

/// 黒板風テーマ(Cycle 20 T2-1a)。
///
/// 001(ダッシュボード)のような「黒板」を表現する画面で使う配色・背景テクスチャ。
/// 既存のコーヒートーン配色(create_form_widgets.dart の kMocha 等)とは別系統で、
/// 黒板を表現する画面にのみ使う想定(共通ウィジェット側は `dark`/背景色の
/// オプション引数で任意選択にし、他画面の見た目は変えない)。
const kBoardBg = Color(0xFF2F3E33);
const kBoardBgLight = Color(0xFF3B4D40);
const kBoardFrame = Color(0xFF8D6E63);
const kChalkWhite = Color(0xFFF5F0E1);
const kChalkMuted = Color(0xFFD7CCC8);
const kChalkAccent = Color(0xFFE8B563);
const kChalkError = Color(0xFFFFAB91);

/// 黒板の背景(チョークの粉・かすれをCustomPainterで薄く重ねる)。
/// `child` の背後に固定シードのテクスチャを敷く。
class BlackboardTexture extends StatelessWidget {
  final Widget child;

  const BlackboardTexture({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: kBoardBg,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BlackboardTexturePainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlackboardTexturePainter extends CustomPainter {
  const _BlackboardTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 固定シード: 再描画のたびにテクスチャが変わらないようにする。
    final rnd = Random(42);

    final dustPaint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (var i = 0; i < 260; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.4 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, dustPaint);
    }

    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (var i = 0; i < 14; i++) {
      final startX = rnd.nextDouble() * size.width;
      final startY = rnd.nextDouble() * size.height;
      final length = rnd.nextDouble() * 60 + 20;
      final angle = rnd.nextDouble() * pi;
      final end = Offset(
        startX + length * cos(angle),
        startY + length * sin(angle),
      );
      canvas.drawLine(Offset(startX, startY), end, streakPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlackboardTexturePainter oldDelegate) => false;
}
