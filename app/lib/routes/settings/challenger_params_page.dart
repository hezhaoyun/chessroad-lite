import 'package:flutter/material.dart';

import '../../config/local_data.dart';
import '../../engine/config/challenger_engine_config.dart';
import '../../game/game.dart';

class ChallengerParamsPage extends StatefulWidget {
  //
  const ChallengerParamsPage({Key? key}) : super(key: key);

  @override
  ChallengerParamsPageState createState() => ChallengerParamsPageState();
}

class ChallengerParamsPageState extends State<ChallengerParamsPage> {
  //
  final config = ChallengerEngineConfig(LocalData().profile);

  Widget spinnerListTitle(
    BuildContext context, {
    required String title,
    required int initValue,
    required String unit,
    required Function reduce,
    required Function plus,
  }) {
    //
    final TextStyle itemStyle = GameFonts.uicp();

    return ListTile(
      title: Text(title, style: itemStyle),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove, color: GameColors.secondary),
          onPressed: () => setState(() {
            reduce();
          }),
        ),
        Text('$initValue $unit'),
        IconButton(
          icon: const Icon(Icons.add, color: GameColors.secondary),
          onPressed: () => setState(() {
            plus();
          }),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    config.save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //
    final TextStyle headerStyle = GameFonts.ui(
      color: GameColors.secondary,
      fontSize: 20,
    );

    return Scaffold(
      backgroundColor: GameColors.lightBackground,
      appBar: AppBar(title: const Text('挑战者')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            Text('引擎参数', style: headerStyle),
            const SizedBox(height: 10.0),
            Card(
              color: GameColors.boardBackground,
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
              child: Column(
                children: <Widget>[
                  spinnerListTitle(
                    context,
                    title: '思考时间',
                    initValue: config.timeLimit,
                    unit: '秒',
                    reduce: config.timeLimitReduce,
                    plus: config.timeLimitPlus,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60.0),
          ],
        ),
      ),
    );
  }
}
