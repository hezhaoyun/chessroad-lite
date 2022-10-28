import 'dart:async';

import 'package:chessroad/config/local_data.dart';
import 'package:chessroad/routes/main_menu/privacy_policy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ad/ad.dart';
import '../../engine/battle_agent.dart';
import '../../game/game.dart';
import '../../services/audios.dart';
import '../../ui/ruler.dart';
import '../../ui/snack_bar.dart';
import '../battle/battle_page.dart';
import '../settings/settings_page.dart';
import 'flowers_mixin.dart';

class MainMenu extends StatefulWidget {
  //
  const MainMenu({Key? key}) : super(key: key);

  @override
  MainMenuState createState() => MainMenuState();
}

class MainMenuState extends State<MainMenu>
    with TickerProviderStateMixin, FlowersMinix {
  //
  late AnimationController _inController, _shadowController;
  late Animation _inAnimation, _shadowAnimation;

  bool _waitingInit = true;

  @override
  void initState() {
    //
    super.initState();

    initSync();
    initAsync();
  }

  void initSync() {
    //
    _inController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _inAnimation = CurvedAnimation(
      parent: _inController,
      curve: Curves.bounceIn,
    );
    _inAnimation = Tween(begin: 1.6, end: 1.0).animate(_inController);

    _shadowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shadowAnimation = Tween(begin: 0.0, end: 12.0).animate(_shadowController);

    _inController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shadowController.forward();
    });
    _shadowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shadowController.reverse();
    });

    _inAnimation.addListener(() {
      if (mounted) setState(() {});
    });
    _shadowAnimation.addListener(() {
      if (mounted) setState(() {});
    });

    _inController.forward();
  }

  Future<void> initAsync() async {
    //
    await LocalData().load();

    if (!mounted) return;

    createFlowers(context, this, () => setState(() {}));

    bool newUser = await checkPrivacyPolicy();

    await Ad.instance.init();
    startSplashAd(newUser);

    Audios.init();

    await BattleAgent.shared.startupEngine();

    setState(() => _waitingInit = false);

    Audios.loopBgm();
  }

  Future<void> startSplashAd(bool newUser) async {
    //
    if (!newUser) {
      //
      int counterDown = 30;

      while ((!mounted || !Ad.instance.initCompleted) && counterDown > 0) {
        await Future.delayed(const Duration(milliseconds: 100));
        counterDown--;
      }

      if (counterDown > 0 && mounted) {
        await Ad.instance.showSplashVideo(context);
      }
    }
  }

  checkPrivacyPolicy() async {
    //
    if (!LocalData().aceptedPrivacyPolicy.value) {
      await openPrivacyPolicy(context);
      return true;
    }

    return false;
  }

  browseHomepage() async {
    //
    const url = 'https://mdevs.cn';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Clipboard.setData(const ClipboardData(text: url));
      showSnackBar(context, '链接已复制到剪贴板！');
    }
  }

  showReadme() {
    //
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('棋路 Lite 版', style: GameFonts.uicp()),
        content: Linkify(
          text: '这是棋路的「开源精简」版！\n\n'
              '集成了多个开源象棋引擎，包括：\n\n'
              ' - 象眼\n'
              ' - 挑战者\n'
              ' - 皮卡鱼\n\n'
              '请从以下地址下载棋路完整版：\n\n'
              ' - https://mdevs.cn',
          style: GameFonts.uicp(fontSize: 16),
          onOpen: (link) async {
            Navigator.of(context).pop();
            if (await canLaunchUrl(Uri.parse(link.url))) {
              await launchUrl(Uri.parse(link.url));
            } else {
              Clipboard.setData(ClipboardData(text: link.url));
              showSnackBar(context, '链接已复制到剪贴板！');
            }
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text('下载完整版', style: GameFonts.uicp(fontSize: 16)),
            onPressed: () {
              Navigator.of(context).pop();
              browseHomepage();
            },
          ),
          TextButton(
            child: Text('知道了', style: GameFonts.uicp(fontSize: 16)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    if (_waitingInit) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            '加载中',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final nameShadow = Shadow(
      color: const Color.fromARGB(0x99, 66, 0, 0),
      offset: Offset(0, _shadowAnimation.value / 2),
      blurRadius: _shadowAnimation.value,
    );

    final nameStyle = TextStyle(
      fontSize: 64,
      fontFamily: LocalData().artFont.value,
      color: Colors.black,
      shadows: [nameShadow],
    );

    Widget buildActionCtrls() {
      //
      final menuItemStyle = GameFonts.art(
        fontSize: 28,
        color: GameColors.primary,
      );

      return Expanded(
        flex: 4,
        child: Column(
          children: [
            TextButton(
              child: Text(
                '人机练习',
                style: menuItemStyle,
              ),
              onPressed: () => navigateTo(GameScene.battle),
            ),
            const Expanded(child: SizedBox()),
            TextButton(
              onPressed: showReadme,
              child: Text(
                '版本说明',
                style: menuItemStyle,
              ),
            ),
            const Expanded(flex: 4, child: SizedBox()),
          ],
        ),
      );
    }

    final mainEntries = Center(
      child: Column(
        children: <Widget>[
          const Expanded(flex: 2, child: SizedBox()),
          Hero(tag: 'logo', child: Image.asset('images/logo.png')),
          const Expanded(child: SizedBox()),
          Transform.scale(
            scale: _inAnimation.value,
            child: Text(
              '象棋课堂',
              style: nameStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(child: SizedBox()),
          buildActionCtrls(),
          const Expanded(flex: 2, child: SizedBox()),
          Container(height: 10),
          Text(
            '用心娱乐，为爱传承',
            style: GameFonts.art(color: Colors.black54, fontSize: 16),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: GameColors.menuBackground,
      body: Stack(
        children: <Widget>[
          const Positioned(
            right: 0,
            top: 0,
            child: Image(image: AssetImage('images/mei.png')),
          ),
          const Positioned(
            left: 0,
            bottom: 0,
            child: Image(image: AssetImage('images/zhu.png')),
          ),
          buildFlowersCanvas(),
          mainEntries,
          Positioned(
            top: Ruler.statusBarHeight(context),
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.settings, color: GameColors.primary),
              onPressed: () async {
                await Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
                _inController.forward();
              },
            ),
          ),
        ],
      ),
    );
  }

  navigateTo(GameScene scene) async {
    //
    Widget page;

    switch (scene) {
      case GameScene.battle:
        page = const BattlePage();
        break;

      case GameScene.unknown:
        throw 'Scene is not define.';
    }

    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => page),
    );

    _inController.reset();
    _shadowController.reset();
    _inController.forward();
  }

  @override
  void dispose() {
    //
    _inController.dispose();
    _shadowController.dispose();

    super.dispose();
  }
}
