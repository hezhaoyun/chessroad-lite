import 'package:chessroad/engine/hybrid_engine.dart';
import 'package:chessroad/engine/pikafish_config.dart';
import 'package:chessroad/engine/pikafish_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../ad/trigger.dart';
import '../../cchess/cc_base.dart';
import '../../cchess/cc_fen.dart';
import '../../cchess/move_name.dart';
import '../../config/local_data.dart';
import '../../config/profile.dart';
import '../../engine/analysis.dart';
import '../../engine/cloud_engine.dart';
import '../../engine/engine.dart';
import '../../game/board_state.dart';
import '../../game/game.dart';
import '../../game/page_state.dart';
import '../../services/audios.dart';
import '../../ui/build_utils.dart';
import '../../ui/checkbox_list_tile_ex.dart';
import '../../ui/operation_bar.dart';
import '../../ui/piece_animation_mixin.dart';
import '../../ui/review_panel.dart';
import '../../ui/ruler.dart';
import '../../ui/snack_bar.dart';
import '../settings/settings_page.dart';

class BattlePage extends StatefulWidget {
  //
  static const yourTurn = '请走棋';

  const BattlePage({Key? key}) : super(key: key);

  @override
  BattlePageState createState() => BattlePageState();
}

class BattlePageState extends State<BattlePage>
    with PieceAnimationMixIn, TickerProviderStateMixin {
  //
  bool _opponentHuman = false;

  late BoardState _boardState;
  late PageState _pageState;

  @override
  void initState() {
    super.initState();
    initGame();
  }

  initGame() async {
    //
    _boardState = Provider.of<BoardState>(context, listen: false);
    _pageState = Provider.of<PageState>(context, listen: false);

    createPieceAnimation(const Duration(milliseconds: 200), this);

    await loadBattle();

    if (_boardState.isOpponentTurn && !_opponentHuman) {
      engineGo();
    } else {
      _pageState.changeStatus(BattlePage.yourTurn);
    }
  }

  // 打开上一次退出时的棋谱
  Future<void> loadBattle() async {
    //
    final profile = await Profile.local().load();

    final initBoard = profile['battlepage-init-board'] ?? Fen.defaultPosition;
    final moveList = profile['battlepage-move-list'] ?? '';
    final boardInversed = profile['battlepage-board-inversed'] ?? false;
    _opponentHuman = profile['battlepage-oppo-human'] ?? false;

    final position = Fen.positionFromFen(initBoard)!;

    for (var i = 0; i < moveList.length; i += 4) {
      //
      final move = Move.fromCoordinate(
        int.parse(moveList.substring(i + 0, i + 1)),
        int.parse(moveList.substring(i + 1, i + 2)),
        int.parse(moveList.substring(i + 2, i + 3)),
        int.parse(moveList.substring(i + 3, i + 4)),
      );

      position.move(move);
    }

    _boardState.inverseBoard(boardInversed, notify: false);
    _boardState.setPosition(position);
  }

  Future<bool> saveBattle() async {
    //
    final moveList = _boardState.buildMoveListForManual();

    final profile = await Profile.local().load();

    profile['battlepage-init-board'] = Fen.defaultPosition;
    profile['battlepage-move-list'] = moveList;
    profile['battlepage-board-inversed'] = _boardState.boardInversed;
    profile['battlepage-oppo-human'] = _opponentHuman;

    return await profile.save();
  }

  confirmNewGame() {
    //
    bool opponentFirst = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('开始新对局？', style: GameFonts.uicp()),
        content: SingleChildScrollView(
          child: Column(
            children: [
              CheckboxListTileEx(
                title: const Text('对方先行'),
                onChanged: (value) => opponentFirst = value,
                value: opponentFirst,
              ),
              CheckboxListTileEx(
                title: const Text('玩家控制双方棋子'),
                onChanged: (value) => _opponentHuman = value,
                value: _opponentHuman,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.of(context).pop();
              newGame(opponentFirst);
            },
          ),
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  newGame(bool opponentFirst) async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.start, context)) return;

    _boardState.inverseBoard(opponentFirst);

    _boardState.load(Fen.defaultPosition, notify: true);

    HybridEngine().newGame();

    setState(() {
      _boardState.engineInfo = null;
      _boardState.bestmove = null;
    });

    if (opponentFirst && !_opponentHuman) {
      engineGo();
    } else {
      _pageState.changeStatus(BattlePage.yourTurn);
    }

    ReviewPanel.popRequest();
  }

  regret() async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.regret, context)) return;

    await _stopPonder();

    _boardState.regret(GameScene.battle, moves: 2);
  }

  analysisPosition() async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.requestAnalysis, context)) {
      return;
    }

    showSnackBar(context, '正在分析局面...', shortDuration: true);

    try {
      final result = await CloudEngine().analysis(_boardState.position);

      if (result.response is Analysis) {
        //
        List<AnalysisItem> items = (result.response as Analysis).items;

        for (var item in items) {
          item.name = MoveName.translate(
            _boardState.position,
            Move.fromEngineMove(item.move),
          );
        }
        if (mounted) {
          showAnalysisItems(
            context,
            items: items,
            callback: (index) => Navigator.of(context).pop(),
          );
        }
      } else if (result.response is Error) {
        if (mounted) showSnackBar(context, '已请求服务器计算，请稍后查看！');
      } else {
        if (mounted) {
          showSnackBar(context, '错误：${result.type}');
        }
      }
    } catch (e) {
      showSnackBar(context, '错误：$e');
    }
  }

  showAnalysisItems(
    BuildContext context, {
    required List<AnalysisItem> items,
    required Function(AnalysisItem item) callback,
  }) {
    //
    final List<Widget> children = [];

    for (var item in items) {
      children.add(
        ListTile(
          title: Text(item.name!, style: GameFonts.ui(fontSize: 18)),
          subtitle: Text('获胜机率：${item.winrate}%'),
          trailing: Text('局面评分：${item.score}'),
          onTap: () => callback(item),
        ),
      );
      children.add(const Divider());
    }

    children.insert(0, const SizedBox(height: 10));
    children.add(const SizedBox(height: 56));

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  swapPosition() async {
    //
    if (PikafishEngine().state == EngineState.pondering) {
      await _stopPonder();
      await Future.delayed(const Duration(seconds: 1));
    }

    _boardState.inverseBoard(!_boardState.boardInversed);

    if (_boardState.isOpponentTurn && !_opponentHuman) {
      engineGo();
    } else {
      _pageState.changeStatus(BattlePage.yourTurn);
    }
  }

  inverseBoard() async {
    //
    await HybridEngine().newGame();
    await Future.delayed(const Duration(seconds: 1));

    _boardState.engineInfo = null;
    _boardState.bestmove = null;

    _boardState.inverseBoard(!_boardState.boardInversed, swapSite: true);
  }

  saveManual() async {
    //
    final success = await _boardState.saveManual(GameScene.battle);

    if (!mounted) return;
    showSnackBar(context, success ? '保存成功！' : '保存失败！');
  }

  onBoardTap(BuildContext context, int index) async {
    //
    if (_boardState.boardInversed) index = 89 - index;

    final position = _boardState.position;

    // 仅 Position 中的 sideToMove 指示一方能动棋
    if (_boardState.isOpponentTurn && !_opponentHuman) return;

    final tapedPiece = position.pieceAt(index);

    // 之前已经有棋子被选中了
    if (_boardState.focusIndex != Move.invalidIndex &&
        PieceColor.of(position.pieceAt(_boardState.focusIndex)) ==
            position.sideToMove) {
      //
      // 当前点击的棋子和之前已经选择的是同一个位置
      if (_boardState.focusIndex == index) return;

      // 之前已经选择的棋子和现在点击的棋子是同一边的，说明是选择另外一个棋子
      final focusPiece = position.pieceAt(_boardState.focusIndex);

      if (PieceColor.sameColor(focusPiece, tapedPiece)) {
        _boardState.select(index);
        return;
      }

      // 现在点击的棋子和上一次选择棋子不同边，要么是吃子，要么是移动棋子到空白处
      if (_boardState.move(Move(_boardState.focusIndex, index))) {
        //
        startPieceAnimation();

        final result = HybridEngine().scanGameResult(
          _boardState.position,
          _boardState.playerSide,
        );

        switch (result) {
          //
          case GameResult.pending:
            //
            final move = _boardState.position.lastMove!.asEngineMove();

            if (_boardState.bestmove?.ponder != null &&
                PikafishConfig(LocalData().profile).ponder &&
                move == _boardState.bestmove?.ponder) {
              //
              await HybridEngine().ponderhit();
              //
            } else {
              //
              await _stopPonder();

              if (!_opponentHuman) {
                await Future.delayed(const Duration(seconds: 1));
                await engineGo();
              }
            }
            break;
          case GameResult.win:
            gotWin();
            break;
          case GameResult.lose:
            gotLose();
            break;
          case GameResult.draw:
            gotDraw();
            break;
        }
      }
    } else if (tapedPiece != Piece.noPiece &&
        PieceColor.of(tapedPiece) == position.sideToMove) {
      // 之前未选中棋子，现在点击就是选择棋子
      _boardState.select(index);
    }
  }

  engineCallback(EngineResponse er) async {
    //
    final resp = er.response;

    if (resp is EngineInfo) {
      //
      _boardState.engineInfo = resp;

      if (PikafishEngine().state != EngineState.pondering) {
        final score = _boardState.engineInfo!.score(_boardState, false);
        if (score != null) {
          _pageState.changeStatus(score);
        }
      }
    } else {
      //
      if (resp is Bestmove) {
        //
        final move = Move.fromEngineMove(resp.bestmove);

        _boardState.bestmove = (er.response as Bestmove);

        _boardState.move(move);
        startPieceAnimation();

        final result = HybridEngine().scanGameResult(
          _boardState.position,
          _boardState.playerSide,
        );

        switch (result) {
          //
          case GameResult.pending:
            if (er.type == EngineType.cloudLibrary) {
              _pageState.changeStatus(BattlePage.yourTurn);
            } else {
              afterEngineMove();
            }
            break;
          case GameResult.win:
            gotWin();
            break;
          case GameResult.lose:
            gotLose();
            break;
          case GameResult.draw:
            gotDraw();
            break;
        }
      } else if (resp is NoBestmove) {
        if (PikafishEngine().state == EngineState.searching) {
          gotWin();
        } else {
          gotLose();
        }
      } else if (resp is Error) {
        if (mounted) showSnackBar(context, resp.message);
        _pageState.changeStatus(resp.message);
      }
    }
  }

  afterEngineMove() async {
    //
    if (PikafishEngine().state == EngineState.searching) {
      //
      if (_boardState.bestmove?.ponder != null &&
          PikafishConfig(LocalData().profile).ponder) {
        //
        await Future.delayed(
          const Duration(seconds: 1),
          () => engineGoPonder(),
        );
      }

      if (_boardState.engineInfo != null) {
        //
        final score = _boardState.engineInfo?.score(
          _boardState,
          true,
        );
        if (score != null) {
          _pageState.changeStatus('$score，${BattlePage.yourTurn}');
        } else {
          _pageState.changeStatus(BattlePage.yourTurn);
        }
      } else {
        _pageState.changeStatus(BattlePage.yourTurn);
      }

      // debug
      if (LocalData().debugMode.value &&
          !PikafishConfig(LocalData().profile).ponder &&
          mounted) {
        //
        Future.delayed(const Duration(seconds: 1), () => engineGoHint());
      }
    } else {
      if (_boardState.isOpponentTurn && !_opponentHuman) {
        Future.delayed(const Duration(seconds: 1), () => engineGo());
      }
    }
  }

  Future<void> engineGo() async {
    //
    final state = PikafishEngine().state;
    if (state == EngineState.searching || state == EngineState.hinting) return;

    _pageState.changeStatus('对方思考中...');

    await HybridEngine().go(_boardState.position, engineCallback);
  }

  engineGoPonder() async {
    await HybridEngine().goPonder(
      _boardState.position,
      engineCallback,
      _boardState.bestmove!.ponder!,
    );
  }

  engineGoHint() async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.requestHint, context)) return;

    final state = PikafishEngine().state;
    if (state == EngineState.searching || state == EngineState.hinting) return;

    await _stopPonder();
    await Future.delayed(const Duration(seconds: 1));

    _pageState.changeStatus('引擎思考提示着法...');
    await HybridEngine().goHint(_boardState.position, engineCallback);
  }

  gotWin() async {
    //
    await Future.delayed(const Duration(seconds: 1));

    Audios.playTone('win.mp3');
    _boardState.position.result = GameResult.win;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('赢了', style: GameFonts.uicp()),
        content: const Text('恭喜您取得胜利！'),
        actions: <Widget>[
          TextButton(
            child: const Text('再来一局'),
            onPressed: () {
              Navigator.of(context).pop();
              confirmNewGame();
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  gotLose() async {
    //
    await Future.delayed(const Duration(seconds: 1));

    Audios.playTone('lose.mp3');
    _boardState.position.result = GameResult.lose;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('输了', style: GameFonts.uicp()),
        content: const Text('败亦可喜！'),
        actions: <Widget>[
          TextButton(
            child: const Text('再来一局'),
            onPressed: () {
              Navigator.of(context).pop();
              confirmNewGame();
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  gotDraw() async {
    //
    await Future.delayed(const Duration(seconds: 1));

    Audios.playTone('draw.mp3');
    _boardState.position.result = GameResult.draw;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('和棋', style: GameFonts.uicp()),
        content: const Text('和为贵！'),
        actions: <Widget>[
          TextButton(
            child: const Text('再来一局'),
            onPressed: () {
              Navigator.of(context).pop();
              confirmNewGame();
            },
          ),
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    final header = createPageHeader(
      context,
      GameScene.battle,
      rightAction: () async {
        //
        await HybridEngine().stop();

        _boardState.engineInfo = null;
        _boardState.bestmove = null;

        if (!mounted) return;

        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );

        if (_boardState.isOpponentTurn && !_opponentHuman) {
          engineGo();
        } else {
          _pageState.changeStatus(BattlePage.yourTurn);
        }
      },
    );

    final board = createChessBoard(
      context,
      GameScene.battle,
      onBoardTap: onBoardTap,
      opponentHuman: _opponentHuman,
    );
    final operatorBar = OperationBar(items: [
      ActionItem(name: '新局', callback: confirmNewGame),
      ActionItem(name: '悔棋', callback: regret),
      ActionItem(name: '提示', callback: engineGoHint),
      ActionItem(name: '云库', callback: analysisPosition),
      ActionItem(name: '交换局面', callback: swapPosition),
      ActionItem(name: '翻转棋盘', callback: inverseBoard),
      ActionItem(name: '保存棋谱', callback: saveManual),
    ]);

    final footer = Consumer<BoardState>(
      builder: (context, __, child) => buildFooter(),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(children: <Widget>[header, board, operatorBar, footer]),
      ),
    );
  }

  Widget buildFooter() {
    //
    String? content;

    if (_boardState.engineInfo != null) {
      //
      content = _boardState.engineInfo!.info(_boardState);

      if (PikafishEngine().state == EngineState.pondering) {
        content = '[ 后台思考 ]\n$content';
      }
    }

    content ??= _boardState.position.moveList;

    return buildInfoPanel(content);
  }

  Widget buildInfoPanel(String text) {
    //
    final manualStyle = GameFonts.ui(
      fontSize: 15,
      color: GameColors.darkTextSecondary,
      height: 1.5,
    );

    return Expanded(
      child: Container(
        // width: double.infinity,
        margin: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: manualStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _stopPonder() async {
    await HybridEngine().stopPonder();
    _boardState.engineInfo = null;
    _boardState.bestmove = null;
  }

  @override
  void dispose() {
    saveBattle().then((_) => _boardState.reset());
    HybridEngine().stop();
    super.dispose();
  }
}
