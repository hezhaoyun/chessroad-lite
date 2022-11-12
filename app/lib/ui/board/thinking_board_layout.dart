import 'package:chessroad/cchess/cc_base.dart';
import 'package:chessroad/engine/engine.dart';
import 'package:chessroad/ui/thinking_board_painter.dart';
import 'package:flutter/material.dart';

import 'pieces_layout.dart';

class ThinkingBoardLayout extends StatefulWidget {
  //
  final EngineInfo? engineInfo;
  final PiecesLayout layoutParams;

  const ThinkingBoardLayout(this.engineInfo, this.layoutParams, {Key? key})
      : super(key: key);

  @override
  State createState() => _PiecesLayoutState();
}

class _PiecesLayoutState extends State<ThinkingBoardLayout> {
  //
  @override
  Widget build(BuildContext context) {
    //
    final moves = <Move>[];

    if (widget.engineInfo != null) {
      //
      var pvs = widget.engineInfo!.pvs;

      if (pvs.length > 4) {
        pvs = pvs.sublist(0, 4);
      } else if (pvs.length > 2) {
        pvs = pvs.sublist(0, 2);
      }

      moves.addAll(pvs.map((move) => Move.fromEngineStep(move)));
    }

    final layout = widget.layoutParams.buildPiecesLayout(context);

    return Stack(children: [
      layout,
      CustomPaint(
        painter: ThinkingBoardPainter(moves, widget.layoutParams),
      )
    ]);
  }
}
