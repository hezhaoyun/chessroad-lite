import 'package:flutter/material.dart';

import '../../game/game.dart';
import '../ruler.dart';

class WordsOnBoard extends StatelessWidget {
  //
  final bool boardInversed;
  const WordsOnBoard(this.boardInversed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //
    final topSideColumns = boardInversed ? '一二三四五六七八九' : '１２３４５６７８９';
    final bottomSideColumns = boardInversed ? '９８７６５４３２１' : '九八七六五四三二一';

    final topSideChildren = <Widget>[], bottomSideChildren = <Widget>[];

    const digitsStyle = TextStyle(fontSize: Ruler.kBoardDigitsTextFontSize);
    const riverTipsStyle = TextStyle(fontSize: 28);

    for (var i = 0; i < 9; i++) {
      //
      topSideChildren.add(Text(topSideColumns[i], style: digitsStyle));
      bottomSideChildren.add(Text(bottomSideColumns[i], style: digitsStyle));

      if (i < 8) {
        topSideChildren.add(const Expanded(child: SizedBox()));
        bottomSideChildren.add(const Expanded(child: SizedBox()));
      }
    }

    final riverTips = Row(
      children: const <Widget>[
        Expanded(child: SizedBox()),
        Text('楚河', style: riverTipsStyle),
        Expanded(flex: 2, child: SizedBox()),
        Text('汉界', style: riverTipsStyle),
        Expanded(child: SizedBox()),
      ],
    );

    return DefaultTextStyle(
      style: GameFonts.art(color: GameColors.boardTips),
      child: Column(
        children: <Widget>[
          Row(children: topSideChildren),
          const Expanded(child: SizedBox()),
          riverTips,
          const Expanded(child: SizedBox()),
          Row(children: bottomSideChildren),
        ],
      ),
    );
  }
}
