import 'package:chessroad/engine/pikafish_config.dart';
import 'package:flutter/material.dart';

import '../../config/local_data.dart';
import '../../game/game.dart';

class PikafishParamsPage extends StatefulWidget {
  //
  const PikafishParamsPage({Key? key}) : super(key: key);

  @override
  PikafishParamsPageState createState() => PikafishParamsPageState();
}

class PikafishParamsPageState extends State<PikafishParamsPage> {
  //
  final config = PikafishConfig(LocalData().profile);

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

  switchPonder(bool value) {
    setState(() => config.profile[PikafishConfig.kPonder] = value);
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
    final TextStyle itemStyle = GameFonts.uicp();

    return Scaffold(
      backgroundColor: GameColors.lightBackground,
      appBar: AppBar(title: const Text('皮卡鱼')),
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
                  _buildDivider(),
                  spinnerListTitle(
                    context,
                    title: '难度等级',
                    initValue: config.level,
                    unit: '级',
                    reduce: config.levelReduce,
                    plus: config.levelPlus,
                  ),
                  _buildDivider(),
                  spinnerListTitle(
                    context,
                    title: '线程数',
                    initValue: config.threads,
                    unit: '线程',
                    reduce: config.threadsReduce,
                    plus: config.threadsPlus,
                  ),
                  _buildDivider(),
                  spinnerListTitle(
                    context,
                    title: 'Hash尺寸',
                    initValue: config.hashSize,
                    unit: 'KB',
                    reduce: config.hashSizeReduce,
                    plus: config.hashSizePlus,
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: config.ponder,
                    title: Text('后台思考', style: itemStyle),
                    onChanged: switchPonder,
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

  Container _buildDivider() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 1.0,
        color: GameColors.lightLine,
      );
}
