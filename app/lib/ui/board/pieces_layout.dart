import 'package:flutter/material.dart';
import '../../cchess/cc_base.dart';
import '../../cchess/position.dart';
import '../ruler.dart';
import 'blur_holder.dart';
import 'piece_stubs.dart';
import 'piece_widget.dart';

class PiecesLayout {
  //
  final double width;
  final Position position;
  final int focusIndex, blurIndex;
  final bool boardInversed;

  final double pieceAnimationValue;
  final bool opponentHuman;

  PiecesLayout(
    this.width,
    this.position, {
    required this.pieceAnimationValue,
    required this.boardInversed,
    this.focusIndex = Move.invalidIndex,
    this.blurIndex = Move.invalidIndex,
    this.opponentHuman = false,
  });

  double get gridWidth => (width - Ruler.kBoardPadding * 2) / 9 * 8;
  double get squareWidth => (width - Ruler.kBoardPadding * 2) / 9;
  double get pieceWidth => squareWidth * 0.96;

  Widget buildPiecesLayout(BuildContext context) {
    //
    const offsetX = Ruler.kBoardPadding;
    const offsetY = Ruler.kBoardPadding + Ruler.kBoardDigitsHeight;

    final pieces = <PieceLayoutStub>[];

    for (var rank = 0; rank < 10; rank++) {
      //
      for (var file = 0; file < 9; file++) {
        //
        final index = rank * 9 + file;
        final piece = position.pieceAt(index);
        if (piece == Piece.noPiece) continue;

        final x = boardInversed ? 8 - file : file;
        final y = boardInversed ? 9 - rank : rank;

        var posX = offsetX + squareWidth * x;
        var posY = offsetY + squareWidth * y;

        // update the piece's location with last moved
        if (pieceAnimationValue < 1 &&
            index == focusIndex &&
            blurIndex != Move.invalidIndex) {
          //
          final fx = blurIndex % 9, fy = blurIndex ~/ 9;
          final tx = file, ty = rank;
          final ax = fx + (tx - fx) * pieceAnimationValue,
              ay = fy + (ty - fy) * pieceAnimationValue;

          final x = boardInversed ? 8 - ax : ax;
          final y = boardInversed ? 9 - ay : ay;

          posX = offsetX + squareWidth * x;
          posY = offsetY + squareWidth * y;
        }

        pieces.add(
          PieceLayoutStub(
            piece: piece,
            diameter: pieceWidth,
            selected: index == focusIndex,
            x: posX,
            y: posY,
            rotate: opponentHuman &&
                PieceColor.of(piece) ==
                    (boardInversed ? PieceColor.red : PieceColor.black),
          ),
        );
      }
    }

    final blurRow = blurIndex ~/ 9, blurCol = blurIndex % 9;
    final blurX = boardInversed ? 8 - blurCol : blurCol;
    final blurY = boardInversed ? 9 - blurRow : blurRow;

    return Stack(
      children: <Widget>[
        if (blurIndex != Move.invalidIndex)
          Positioned(
            left: offsetX + blurX * squareWidth,
            top: offsetY + blurY * squareWidth,
            child: BlurHolder(
              diameter: pieceWidth * 0.8,
              squreSide: squareWidth,
            ),
          ),
        for (var piece in pieces)
          Positioned(
            left: piece.x,
            top: piece.y,
            child: PieceWidget(
              piece: piece.piece,
              diameter: piece.diameter,
              squreSide: squareWidth,
              selected: piece.selected,
              rotate: piece.rotate,
            ),
          ),
      ],
    );
  }
}
