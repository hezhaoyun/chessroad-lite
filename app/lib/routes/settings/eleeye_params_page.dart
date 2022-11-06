import 'package:flutter/material.dart';

import '../../config/local_data.dart';
import '../../engine/config/eleeye_engine_config.dart';
import '../../game/game.dart';

class EleeyeParamsPage extends StatefulWidget {
  //
  const EleeyeParamsPage({Key? key}) : super(key: key);

  @override
  EleeyeParamsPageState createState() => EleeyeParamsPageState();
}

class EleeyeParamsPageState extends State<EleeyeParamsPage> {
  //
  static const kRadioParams = ['none', 'small', 'medium', 'large'];

  final config = EleeyeEngineConfig(LocalData().profile);

  void switchUseBook(value) {
    setState(() => config.profile[EleeyeEngineConfig.kUseBook] = value);
  }

  Widget createListTile(
    String name,
    int index,
    int selectedIndex,
    Function(int?) onChanged,
  ) {
    return RadioListTile<int>(
      activeColor: GameColors.primary,
      title: Text(name),
      groupValue: selectedIndex,
      value: index,
      onChanged: onChanged,
    );
  }

  void changeRadioConfig(String key) {
    //
    final value = config.profile[key];

    var selectedIndex = -1;
    if (value != null) selectedIndex = kRadioParams.indexOf(value);
    selectedIndex = selectedIndex < 0 ? 0 : selectedIndex;

    final items = <Widget>[];

    items.add(const SizedBox(height: 10));

    for (var i = 0; i < kRadioParams.length; i++) {
      //
      final item = kRadioParams[i];

      items.add(createListTile(
        item,
        i,
        selectedIndex,
        (int? index) async {
          //
          Navigator.of(context).pop();

          if (index == null) return;
          final value = kRadioParams[index];

          setState(() => config.profile[key] = value);
        },
      ));

      if (i + 1 < kRadioParams.length) items.add(const Divider());
    }

    items.add(const SizedBox(height: 56));

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
      ),
    );
  }

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
    final TextStyle itemStyle = GameFonts.uicp();

    return Scaffold(
      backgroundColor: GameColors.lightBackground,
      appBar: AppBar(title: const Text('象眼')),
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
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: config.useBook,
                    title: Text('使用开局库', style: itemStyle),
                    onChanged: switchUseBook,
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('知识库', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(config.knowledge),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: () {
                      changeRadioConfig(EleeyeEngineConfig.kKnowledge);
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('裁剪力度', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(config.pruning),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: () {
                      changeRadioConfig(EleeyeEngineConfig.kPruning);
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('随机性', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(config.randomness),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: () {
                      changeRadioConfig(EleeyeEngineConfig.kRandomness);
                    },
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
