import 'dart:io';

import 'package:chessroad/routes/main_menu/privacy_policy.dart';
import 'package:chessroad/routes/settings/challenger_params_page.dart';
import 'package:chessroad/ui/review_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/local_data.dart';
import '../../engine/battle_agent.dart';
import '../../engine/engine.dart';
import '../../game/game.dart';
import '../../services/audios.dart';
import '../../ui/snack_bar.dart';
import 'eleeye_params_page.dart';
import 'pikafish_params_page.dart';
import 'show_about.dart';

class SettingsPage extends StatefulWidget {
  //
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  //
  int _titleClicked = 0;

  updateLoginState(bool _) {
    if (mounted) setState(() {});
  }

  changeEngineConfig() async {
    //
    final engineName = LocalData().engineName.value;

    final Widget page;
    if (engineName == NativeEngine.kNameChallenger) {
      page = const ChallengerParamsPage();
    } else if (engineName == NativeEngine.kNamePikafish) {
      page = const PikafishParamsPage();
    } else {
      page = const EleeyeParamsPage();
    }

    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => page),
    );

    await BattleAgent.shared.applyNativeEngineConfig();
  }

  changeNativeEngine() {
    //
    callback(int? engineIndex) async {
      //
      Navigator.of(context).pop();

      if (engineIndex == null) return;

      final engineName = NativeEngine.kEngineNames[engineIndex];
      setState(() => LocalData().engineName.value = engineName);

      await BattleAgent.shared.nativeEngineChanged();

      LocalData().save();
    }

    var index = NativeEngine.kEngineNames.indexOf(
      LocalData().engineName.value,
    );

    index = index < 0 ? 0 : index;

    Widget createListTile(String name, int level) => RadioListTile(
          activeColor: GameColors.primary,
          title: Text(name),
          groupValue: index,
          value: level,
          onChanged: callback,
        );

    final names = <Widget>[];

    names.add(const SizedBox(height: 10));

    for (var i = 0; i < NativeEngine.kEngineNames.length; i++) {
      final name = NativeEngine.kEngineNames[i];
      names.add(createListTile(name, i));
      names.add(const Divider());
    }

    names.add(const SizedBox(height: 56));

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: names),
      ),
    );
  }

  switchCloudEngine(bool value) async {
    //
    setState(() => LocalData().cloudEngineEnabled.value = value);
    LocalData().save();
  }

  switchMusic(bool value) async {
    //
    setState(() => LocalData().bgmEnabled.value = value);

    if (LocalData().bgmEnabled.value) {
      Audios.loopBgm();
    } else {
      Audios.stopBgm();
    }

    LocalData().save();
  }

  switchTone(bool value) async {
    //
    setState(() => LocalData().toneEnabled.value = value);

    LocalData().save();
  }

  switchHighContrast(bool value) async {
    //
    setState(() => LocalData().highContrast.value = value);

    LocalData().save();
  }

  changeFont() {
    //
    callback(String? fontFamily) async {
      //
      Navigator.of(context).pop();

      setState(() {
        LocalData().artFont.value = fontFamily!;
      });

      LocalData().save();
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            RadioListTile(
              activeColor: GameColors.primary,
              title: const Text('??????'),
              groupValue: LocalData().artFont.value as String,
              value: 'XiaoLi',
              onChanged: callback,
            ),
            const Divider(),
            RadioListTile(
              activeColor: GameColors.primary,
              title: const Text('?????????'),
              groupValue: LocalData().artFont.value as String,
              value: 'ZhongSan',
              onChanged: callback,
            ),
            const Divider(),
            RadioListTile(
              activeColor: GameColors.primary,
              title: const Text('??????'),
              groupValue: LocalData().artFont.value as String,
              value: 'QiTi',
              onChanged: callback,
            ),
            const Divider(),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
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
      appBar: AppBar(title: const Text('??????')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            Text('????????????', style: headerStyle),
            const SizedBox(height: 10.0),
            Card(
              color: GameColors.boardBackground,
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().cloudEngineEnabled.value,
                    title: Text('????????????', style: itemStyle),
                    onChanged: switchCloudEngine,
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('????????????', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(LocalData().engineName.value),
                        const Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: changeNativeEngine,
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('????????????', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text('??????'),
                        Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: changeEngineConfig,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('??????', style: headerStyle),
            Card(
              color: GameColors.boardBackground,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().bgmEnabled.value,
                    title: Text('????????????', style: itemStyle),
                    onChanged: switchMusic,
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().toneEnabled.value,
                    title: Text('????????????', style: itemStyle),
                    onChanged: switchTone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Text('??????', style: headerStyle),
            const SizedBox(height: 10.0),
            Card(
              color: GameColors.boardBackground,
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text('??????', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          LocalData().artFont.value == 'QiTi'
                              ? '??????'
                              : LocalData().artFont.value == 'ZhongSan'
                                  ? '?????????'
                                  : '??????',
                        ),
                        const Icon(Icons.keyboard_arrow_right,
                            color: GameColors.secondary),
                      ],
                    ),
                    onTap: changeFont,
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().highContrast.value,
                    title: Text('??????????????????', style: itemStyle),
                    onChanged: switchHighContrast,
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: clickAboutTitle,
              child: Text('??????', style: headerStyle),
            ),
            Card(
              color: GameColors.boardBackground,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: <Widget>[
                  if (Platform.isIOS)
                    ListTile(
                      title: Text('????????????', style: itemStyle),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: GameColors.secondary,
                      ),
                      onTap: () => ReviewPanel.popRequest(force: true),
                    ),
                  if (Platform.isIOS) _buildDivider(),
                  ListTile(
                    title: Text('????????????', style: itemStyle),
                    trailing: const Icon(
                      Icons.keyboard_arrow_right,
                      color: GameColors.secondary,
                    ),
                    onTap: () => openPrivacyPolicy(context),
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('??????', style: itemStyle),
                    trailing: const Icon(
                      Icons.keyboard_arrow_right,
                      color: GameColors.secondary,
                    ),
                    onTap: () => showAbout(context),
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

  @override
  void dispose() {
    super.dispose();
  }

  void clickAboutTitle() {
    //
    _titleClicked++;

    if (_titleClicked >= 5) {
      //
      LocalData().debugMode.value = !LocalData().debugMode.value;

      _titleClicked = 0;

      showSnackBar(
        context,
        'DebugMode: ${LocalData().debugMode.value}',
      );
    }
  }
}
