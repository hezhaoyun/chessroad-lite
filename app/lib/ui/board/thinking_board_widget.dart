import 'package:chessroad/ui/board/thinking_board_layout.dart';
import 'package:flutter/material.dart';

import '../../game/board_state.dart';
import 'board_widget.dart';
import 'pieces_layout.dart';

class ThinkingBoardWidget extends BoardWidget {
  //
  const ThinkingBoardWidget(
      double width, Function(BuildContext, int)? onBoardTap,
      {Key? key, required bool opponentHuman})
      : super(width, onBoardTap, opponentHuman: opponentHuman, key: key);

  @override
  Widget buildPiecesLayer(BoardState board, {bool opponentHuman = false}) {
    //
    return ThinkingBoardLayout(
      board.thinkingInfo,
      PiecesLayout(
        width,
        board.phase,
        focusIndex: board.focusIndex,
        blurIndex: board.blurIndex,
        pieceAnimationValue: board.pieceAnimationValue,
        boardInversed: board.boardInversed,
      ),
    );
  }
}
