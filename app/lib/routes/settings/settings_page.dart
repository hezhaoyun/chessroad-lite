import 'dart:io';

import 'package:chessroad/engine/hybrid_engine.dart';
import 'package:chessroad/routes/main_menu/privacy_policy.dart';
import 'package:chessroad/ui/review_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/local_data.dart';
import '../../game/game.dart';
import '../../services/audios.dart';
import '../../ui/snack_bar.dart';
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
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const PikafishParamsPage()),
    );

    await HybridEngine().applyNativeEngineConfig();
  }

  switchCloudEngine(bool value) async {
    //
    setState(() => LocalData().cloudEngineEnabled.value = value);
    LocalData().save();
  }

  switchThinkingArrow(bool value) async {
    //
    setState(() => LocalData().thinkingArrowEnabled.value = value);
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
              title: const Text('小隶'),
              groupValue: LocalData().artFont.value as String,
              value: 'XiaoLi',
              onChanged: callback,
            ),
            const Divider(),
            RadioListTile(
              activeColor: GameColors.primary,
              title: const Text('中山体'),
              groupValue: LocalData().artFont.value as String,
              value: 'ZhongSan',
              onChanged: callback,
            ),
            const Divider(),
            RadioListTile(
              activeColor: GameColors.primary,
              title: const Text('启体'),
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
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            Text('引擎设置', style: headerStyle),
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
                    title: Text('启用云库', style: itemStyle),
                    onChanged: switchCloudEngine,
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('皮卡鱼参数', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text('配置'),
                        Icon(
                          Icons.keyboard_arrow_right,
                          color: GameColors.secondary,
                        ),
                      ],
                    ),
                    onTap: changeEngineConfig,
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().thinkingArrowEnabled.value,
                    title: Text('引擎思考箭头', style: itemStyle),
                    onChanged: switchThinkingArrow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('声音', style: headerStyle),
            Card(
              color: GameColors.boardBackground,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().bgmEnabled.value,
                    title: Text('背景音乐', style: itemStyle),
                    onChanged: switchMusic,
                  ),
                  _buildDivider(),
                  SwitchListTile(
                    activeColor: GameColors.primary,
                    value: LocalData().toneEnabled.value,
                    title: Text('提示音效', style: itemStyle),
                    onChanged: switchTone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Text('棋盘', style: headerStyle),
            const SizedBox(height: 10.0),
            Card(
              color: GameColors.boardBackground,
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: Text('字体', style: itemStyle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          LocalData().artFont.value == 'QiTi'
                              ? '启体'
                              : LocalData().artFont.value == 'ZhongSan'
                                  ? '中山体'
                                  : '小隶',
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
                    title: Text('使用强对比色', style: itemStyle),
                    onChanged: switchHighContrast,
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: clickAboutTitle,
              child: Text('关于', style: headerStyle),
            ),
            Card(
              color: GameColors.boardBackground,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: <Widget>[
                  if (Platform.isIOS)
                    ListTile(
                      title: Text('五星好评', style: itemStyle),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: GameColors.secondary,
                      ),
                      onTap: () => ReviewPanel.popRequest(force: true),
                    ),
                  if (Platform.isIOS) _buildDivider(),
                  ListTile(
                    title: Text('隐私政策', style: itemStyle),
                    trailing: const Icon(
                      Icons.keyboard_arrow_right,
                      color: GameColors.secondary,
                    ),
                    onTap: () => openPrivacyPolicy(context),
                  ),
                  _buildDivider(),
                  ListTile(
                    title: Text('关于', style: itemStyle),
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
