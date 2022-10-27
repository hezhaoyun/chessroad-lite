import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'engine/battle_agent.dart';
import 'routes/main_menu/main_menu.dart';
import 'services/audios.dart';
import 'game/board_state.dart';
import 'game/page_state.dart';

void main() async {
  //
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ChessRoadApp());

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  if (Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack, overlays: []);
  }
}

class ChessRoadApp extends StatefulWidget {
  //
  static final navKey = GlobalKey<NavigatorState>();
  static get conext => navKey.currentContext;

  const ChessRoadApp({Key? key}) : super(key: key);

  @override
  _ChessRoadAppState createState() => _ChessRoadAppState();
}

class _ChessRoadAppState extends State<ChessRoadApp>
    with WidgetsBindingObserver {
  //
  @override
  void initState() {
    //
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
  }

  @override
  Widget build(BuildContext context) {
    //
    return MultiProvider(
      child: MaterialApp(
        navigatorKey: ChessRoadApp.navKey,
        theme: ThemeData(primarySwatch: Colors.brown),
        home: const Scaffold(body: MainMenu()),
        builder: EasyLoading.init(),
        debugShowCheckedModeBanner: false,
      ),
      providers: [
        ChangeNotifierProvider<BoardState>(create: (_) => BoardState()),
        ChangeNotifierProvider<PageState>(create: (_) => PageState()),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        Wakelock.enable();
        Audios.loopBgm();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        Audios.stopBgm();
        Wakelock.disable();
        break;
      case AppLifecycleState.detached:
        Audios.release();
        Wakelock.disable();
        BattleAgent.shared.shutdownEngine();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
