import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/prt.dart';
import '../../game/board_state.dart';
import '../../game/game.dart';
import '../ruler.dart';
import 'pieces_layout.dart';
import 'pieces_layer.dart';
import 'board_painter.dart';
import 'words_on_board.dart';

class BoardWidget extends StatelessWidget {
  //
  final double width;
  final Function(BuildContext, int)? onBoardTap;
  final bool opponentHuman;

  const BoardWidget(this.width, this.onBoardTap,
      {Key? key, this.opponentHuman = false})
      : super(key: key);

  double get height =>
      (width - Ruler.kBoardPadding * 2) / 9 * 10 +
      (Ruler.kBoardPadding + Ruler.kBoardDigitsHeight) * 2;

  @override
  Widget build(BuildContext context) {
    //
    prt('BoardWidget build...');

    final boardContainer = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: GameColors.boardBackground,
      ),
      child: Consumer<BoardState>(
        builder: (context, board, child) {
          return Stack(
            children: <Widget>[
              RepaintBoundary(
                child: CustomPaint(
                  painter: BoardPainter(width),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: Ruler.kBoardPadding,
                      horizontal: (width - Ruler.kBoardPadding * 2) / 9 / 2 +
                          Ruler.kBoardPadding -
                          Ruler.kBoardDigitsTextFontSize / 2,
                    ),
                    child: WordsOnBoard(board.boardInversed),
                  ),
                ),
              ),
              buildPiecesLayer(board, opponentHuman: opponentHuman),
            ],
          );
        },
      ),
    );

    if (onBoardTap == null) {
      return boardContainer;
    }

    return GestureDetector(
      child: boardContainer,
      onTapUp: (d) {
        //
        final gridWidth = (width - Ruler.kBoardPadding * 2) * 8 / 9;
        final squareWidth = gridWidth / 8;

        final dx = d.localPosition.dx, dy = d.localPosition.dy;
        final row = (dy - Ruler.kBoardPadding - Ruler.kBoardDigitsHeight) ~/
            squareWidth;
        final column = (dx - Ruler.kBoardPadding) ~/ squareWidth;

        if (row < 0 || row > 9) return;
        if (column < 0 || column > 8) return;

        if (onBoardTap != null) {
          onBoardTap!(context, row * 9 + column);
        }
      },
    );
  }

  Widget buildPiecesLayer(BoardState board, {bool opponentHuman = false}) {
    //
    return PiecesLayer(
      PiecesLayout(width, board.phase,
          focusIndex: board.focusIndex,
          blurIndex: board.blurIndex,
          boardInversed: board.boardInversed,
          pieceAnimationValue: board.pieceAnimationValue,
          opponentHuman: opponentHuman),
    );
  }
}
