import 'package:flutter/material.dart';
import 'dart:math';
import '../../config/local_data.dart';
import '../../game/game.dart';
import '../../cchess/cc_base.dart';

class PieceWidget extends StatelessWidget {
  //
  final String piece;
  final bool selected;
  final double diameter, squreSide;
  final bool rotate;

  const PieceWidget(
      {Key? key,
      required this.piece,
      required this.selected,
      required this.diameter,
      required this.squreSide,
      this.rotate = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //
    final theme = LocalData().highContrast.value
        ? BoardTheme.highContrastTheme
        : BoardTheme.defaultTheme;

    final borderColor = Piece.isRed(piece)
        ? theme.redPieceBorderColor
        : theme.blackPieceBorderColor;
    final bgColor =
        Piece.isRed(piece) ? theme.redPieceColor : theme.blackPieceColor;
    final textColor = Piece.isRed(piece)
        ? theme.redPieceTextColor
        : theme.blackPieceTextColor;

    final textStyle = GameFonts.artForce(
      color: textColor,
      fontSize: diameter * 0.8,
    );

    if (selected) {
      return Transform.rotate(
        angle: rotate ? pi : 0,
        child: Container(
          width: squreSide,
          height: squreSide,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(squreSide / 2),
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: squreSide - diameter + 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(1, 1),
                blurRadius: 2,
              )
            ],
          ),
          child: Center(
            child: Text(
              Piece.zhName[piece]!,
              style: textStyle,
              textScaleFactor: 1,
            ),
          ),
        ),
      );
    }

    return Transform.rotate(
      angle: rotate ? pi : 0,
      child: Container(
        margin: EdgeInsets.all((squreSide - diameter) / 2),
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(diameter / 2),
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            Piece.zhName[piece]!,
            style: textStyle,
            textScaleFactor: 1,
          ),
        ),
      ),
    );
  }
}
