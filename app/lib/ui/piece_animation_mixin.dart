import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../game/board_state.dart';

mixin PieceAnimationMixIn<T extends StatefulWidget> on State<T> {
  //
  late AnimationController _moveController;
  late Animation _moveAnimation;

  createPieceAnimation(Duration duration, TickerProvider vsync) {
    //
    _moveController = AnimationController(duration: duration, vsync: vsync);
    _moveAnimation = Tween(begin: 0.0, end: 1.0).animate(_moveController);

    _moveAnimation.addListener(() {
      final boardState = Provider.of<BoardState>(context, listen: false);
      boardState.pieceAnimationUpdate(_moveAnimation.value);
    });
  }

  startPieceAnimation() {
    if (_moveAnimation.value > 0) _moveController.reset();
    _moveController.forward();
  }
}
