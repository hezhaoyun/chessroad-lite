import 'package:chessroad/config/local_data.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';

import '../game/game.dart';
import '../ui/snack_bar.dart';
import 'ad.dart';

enum AdAction {
  start,
  regret,
  requestHint,
  requestAnalysis,
}

class AdActionLimits {
  // Battle scene
  static const battleTimes = 5;
  static const battleRegretTimes = 5;
  static const battleHintTimes = 10;
  static const battleAnalysisTimes = 5;
}

class AdTrigger {
  //
  static final AdTrigger battle = AdTrigger(GameScene.battle);
  static final List<AdTrigger> triggers = [
    battle,
  ];

  final GameScene scene;

  // int _startTimesLess = 0;
  // int _regretTimesLess = 0;
  // int _hintTimesLess = 0;
  // int _analysisTimesLess = 0;

  AdTrigger(this.scene) {
    resetTimesLess();
  }

  bool isAdTime(AdAction action) {
    //
    if (!LocalData().acceptedPrivacyPolicy.value) return false;
    return false;

    // switch (action) {
    //   //
    //   case AdAction.start:
    //     _startTimesLess--;
    //     return _startTimesLess < 0;

    //   case AdAction.regret:
    //     _regretTimesLess--;
    //     return _regretTimesLess < 0;

    //   case AdAction.requestHint:
    //     _hintTimesLess--;
    //     return _hintTimesLess < 0;

    //   case AdAction.requestAnalysis:
    //     _analysisTimesLess--;
    //     return _analysisTimesLess < 0;
    // }
  }

  requestShowRewardAd(AdAction action, BuildContext context) {
    //
    final item = limitedItem(context, action);

    final message = '看条广告，可额外获得$item（每天最多 3 条广告）！';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('请支持作者！', style: GameFonts.uicp()),
        content: Text(message, style: GameFonts.uicp(fontSize: 16)),
        actions: <Widget>[
          TextButton(
            child: const Text('不了'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('看视频'),
            onPressed: () {
              Navigator.of(context).pop();
              Ad.instance.showRewardVideo(context, sendReward);
            },
          ),
        ],
      ),
    );
  }

  checkAdChance(AdAction action, BuildContext context) {
    //
    // 每天三次激励视频
    if (LocalData().showAdDate.value == today &&
        LocalData().showAdTimes.value >= 3) return false;

    if (isAdTime(action)) {
      requestShowRewardAd(action, context);
      return true;
    }

    return false;
  }

  static sendReward(BuildContext context) {
    //
    for (var trigger in triggers) {
      trigger.resetTimesLess();
    }

    if (LocalData().showAdDate.value != today) {
      LocalData().showAdDate.value = today;
      LocalData().showAdTimes.value = 0;
    }

    LocalData().showAdTimes.value += 1;
    LocalData().save();

    showSnackBar(context, '已获取广告奖励！');
  }

  static String get today => formatDate(DateTime.now(), [yyyy, mm, dd]);

  resetTimesLess() {
    //
    switch (scene) {
      //
      case GameScene.battle:
        // _startTimesLess = AdActionLimits.battleTimes;
        // _regretTimesLess = AdActionLimits.battleRegretTimes;
        // _hintTimesLess = AdActionLimits.battleHintTimes;
        // _analysisTimesLess = AdActionLimits.battleAnalysisTimes;
        break;

      default:
        break;
    }
  }

  String limitedItem(BuildContext context, AdAction action) {
    //
    switch (action) {
      case AdAction.start:
        switch (scene) {
          case GameScene.battle:
            return ' ${AdActionLimits.battleTimes} 次对局机会';
          default:
            return '';
        }

      case AdAction.regret:
        switch (scene) {
          case GameScene.battle:
            return ' ${AdActionLimits.battleRegretTimes} 次悔棋机会';
          default:
            return '';
        }

      case AdAction.requestHint:
        switch (scene) {
          case GameScene.battle:
            return ' ${AdActionLimits.battleHintTimes} 次提示机会';

          default:
            return '';
        }

      case AdAction.requestAnalysis:
        switch (scene) {
          case GameScene.battle:
            return ' ${AdActionLimits.battleAnalysisTimes} 次分析机会';

          default:
            return '';
        }
    }
  }
}
