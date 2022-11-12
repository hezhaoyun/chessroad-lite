import 'package:chessroad/cchess/cc_base.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';
import 'board/pieces_layout.dart';
import 'build_utils.dart';
import 'ruler.dart';

class ThinkingBoardPainter extends CustomPainter {
  //
  static const pathColors = [
    Color(0x7FFF0000),
    Color(0x7F0000FF),
    Color(0x7F00AA00),
    Color(0x7FFF00FF),
    Color(0x7F00AAFF),
  ];
  static const indicatorColors = [
    Color(0xAAFF0000),
    Color(0xAA0000FF),
    Color(0xAA00AA00),
    Color(0xAAFF00FF),
    Color(0xAA00AAFF),
  ];

  final List<Move> moves;
  final PiecesLayout layoutParams;

  final Paint thePaint = Paint();

  ThinkingBoardPainter(this.moves, this.layoutParams);

  @override
  void paint(Canvas canvas, Size size) {
    //
    for (var i = 0; i < moves.length && i < 5; i++) {
      final move = moves[i];
      drawMoveLine(canvas, move.from, move.to, i);
    }
  }

  bool pathAmountToTarget(int boardIndex) {
    //
    var amount = 0;

    for (var i = 0; i < moves.length && i < 5; i++) {
      //
      final move = moves[i];
      if (move.to == boardIndex) amount++;
    }

    return amount > 1;
  }

  void drawMoveLine(Canvas canvas, int from, int to, int index) {
    //
    final left = Ruler.kBoardPadding + layoutParams.squareWidth / 2;
    final top = Ruler.kBoardPadding +
        Ruler.kBoardDigitsHeight +
        layoutParams.squareWidth / 2;

    final hasMultiPathToTarget = pathAmountToTarget(to);

    final fc = from % 9, fr = from ~/ 9, tc = to % 9, tr = to ~/ 9;

    final fx = left +
        (layoutParams.boardInversed ? 8 - fc : fc) * layoutParams.squareWidth;
    final fy = top +
        (layoutParams.boardInversed ? 9 - fr : fr) * layoutParams.squareWidth;

    double tx = left +
        (layoutParams.boardInversed ? 8 - tc : tc) * layoutParams.squareWidth;
    double ty = top +
        (layoutParams.boardInversed ? 9 - tr : tr) * layoutParams.squareWidth;

    if (hasMultiPathToTarget) {
      //
      if (tr > fr) ty -= layoutParams.pieceWidth / 3;
      if (tr < fr) ty += layoutParams.pieceWidth / 3;

      if (tc > fc) tx -= layoutParams.pieceWidth / 3;
      if (tc < fc) tx += layoutParams.pieceWidth / 3;
    }

    // draw line
    thePaint.style = PaintingStyle.stroke;
    thePaint.strokeWidth = 5;
    thePaint.strokeCap = StrokeCap.round;
    thePaint.color = pathColors[index];
    canvas.drawLine(Offset(fx, fy), Offset(tx, ty), thePaint);

    // draw circle
    thePaint.style = PaintingStyle.fill;
    thePaint.color = indicatorColors[index];
    canvas.drawCircle(
      Offset(tx, ty),
      layoutParams.pieceWidth / 2 * 0.5,
      thePaint,
    );

    // draw index number
    final textStyle = GameFonts.ui(
      color: Colors.white,
      fontSize: layoutParams.pieceWidth * 0.5,
    );
    drawText(canvas, '${index + 1}', textStyle, centerLocation: Offset(tx, ty));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
