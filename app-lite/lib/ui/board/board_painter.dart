import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game/game.dart';
import '../ruler.dart';

class BoardPainter extends CustomPainter {
  //
  final double width;
  final thePaint = Paint();

  BoardPainter(this.width);

  double get gridWidth => (width - Ruler.kBoardPadding * 2) / 9 * 8;
  double get squareWidth => (width - Ruler.kBoardPadding * 2) / 9;

  @override
  void paint(Canvas canvas, Size size) {
    //
    doPaint(
      canvas,
      thePaint,
      gridWidth,
      squareWidth,
      offsetX: Ruler.kBoardPadding + squareWidth / 2,
      offsetY: Ruler.kBoardPadding + Ruler.kBoardDigitsHeight + squareWidth / 2,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  static doPaint(
    Canvas canvas,
    Paint paint,
    double gridWidth,
    double squareWidth, {
    required double offsetX,
    required double offsetY,
  }) {
    //
    paint.color = GameColors.boardLine;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    final left = offsetX, top = offsetY;

    // 外框
    canvas.drawRect(
      Rect.fromLTWH(left, top, gridWidth, squareWidth * 9),
      paint,
    );

    paint.strokeWidth = 1;

    // 8 根中间的横线
    for (var i = 1; i < 9; i++) {
      canvas.drawLine(
        Offset(left, top + squareWidth * i),
        Offset(left + gridWidth, top + squareWidth * i),
        paint,
      );
    }

    // 短竖线
    for (var i = 0; i < 8; i++) {
      //
      canvas.drawLine(
        Offset(left + squareWidth * i, top),
        Offset(left + squareWidth * i, top + squareWidth * 4),
        paint,
      );
      canvas.drawLine(
        Offset(left + squareWidth * i, top + squareWidth * 5),
        Offset(left + squareWidth * i, top + squareWidth * 9),
        paint,
      );
    }

    // 九宫中的斜线
    canvas.drawLine(
      Offset(left + squareWidth * 3, top),
      Offset(left + squareWidth * 5, top + squareWidth * 2),
      paint,
    );
    canvas.drawLine(
      Offset(left + squareWidth * 5, top),
      Offset(left + squareWidth * 3, top + squareWidth * 2),
      paint,
    );
    canvas.drawLine(
      Offset(left + squareWidth * 3, top + squareWidth * 7),
      Offset(left + squareWidth * 5, top + squareWidth * 9),
      paint,
    );
    canvas.drawLine(
      Offset(left + squareWidth * 5, top + squareWidth * 7),
      Offset(left + squareWidth * 3, top + squareWidth * 9),
      paint,
    );

    // 炮/兵架位置指示
    final positions = [
      // 炮架位置指示
      Offset(left + squareWidth, top + squareWidth * 2),
      Offset(left + squareWidth * 7, top + squareWidth * 2),
      Offset(left + squareWidth, top + squareWidth * 7),
      Offset(left + squareWidth * 7, top + squareWidth * 7),
      // 部分兵架位置指示
      Offset(left + squareWidth * 2, top + squareWidth * 3),
      Offset(left + squareWidth * 4, top + squareWidth * 3),
      Offset(left + squareWidth * 6, top + squareWidth * 3),
      Offset(left + squareWidth * 2, top + squareWidth * 6),
      Offset(left + squareWidth * 4, top + squareWidth * 6),
      Offset(left + squareWidth * 6, top + squareWidth * 6),
    ];

    for (var pos in positions) {
      canvas.drawCircle(pos, 5, paint);
    }

    // 兵架靠边位置指示
    final leftPositions = [
      Offset(left, top + squareWidth * 3),
      Offset(left, top + squareWidth * 6),
    ];
    for (var pos in leftPositions) {
      var rect = Rect.fromCenter(center: pos, width: 10, height: 10);
      canvas.drawArc(rect, -math.pi / 2, math.pi, true, paint);
    }

    final rightPositions = [
      Offset(left + squareWidth * 8, top + squareWidth * 3),
      Offset(left + squareWidth * 8, top + squareWidth * 6),
    ];
    for (var pos in rightPositions) {
      var rect = Rect.fromCenter(center: pos, width: 10, height: 10);
      canvas.drawArc(rect, math.pi / 2, math.pi, true, paint);
    }
  }
}
