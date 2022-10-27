import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sprintf/sprintf.dart';
import '../../ad/trigger.dart';
import '../../common/prt.dart';
import '../../config/profile.dart';
import '../../engine/analysis.dart';
import '../../engine/battle_agent.dart';
import '../../engine/cloud_engine.dart';
import '../../engine/engine.dart';
import '../../game/board_state.dart';
import '../../game/game.dart';
import '../../cchess/cc_base.dart';
import '../../cchess/cc_fen.dart';
import '../../cchess/step_name.dart';
import '../../services/audios.dart';
import '../../ui/build_utils.dart';
import '../../game/page_state.dart';
import '../../ui/checkbox_list_tile_ex.dart';
import '../../ui/operation_bar.dart';
import '../../ui/review_panel.dart';
import '../../ui/ruler.dart';
import '../../ui/snack_bar.dart';
import '../../ui/piece_animation_mixin.dart';

class BattlePage extends StatefulWidget {
  //
  static const yourTurn = '请走棋';

  const BattlePage({Key? key}) : super(key: key);

  @override
  _BattlePageState createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage>
    with PieceAnimationMixIn, TickerProviderStateMixin {
  //
  bool _working = false;
  bool _oppoHuman = false;

  late BoardState _boardState;
  late PageState _pageState;

  @override
  void initState() {
    //
    super.initState();
    initGame();
  }

  initGame() async {
    //
    _boardState = Provider.of<BoardState>(context, listen: false);
    _pageState = Provider.of<PageState>(context, listen: false);

    createPieceAnimation(const Duration(milliseconds: 200), this);

    await loadBattle();

    if (_boardState.isOppoTurn && !_oppoHuman) {
      askEngineGo();
    } else {
      _pageState.changeStatus(BattlePage.yourTurn);
    }
  }

  // 打开上一次退出时的棋谱
  Future<void> loadBattle() async {
    //
    final profile = await Profile.local().load();

    final initBoard = profile['battlepage-init-board'] ?? Fen.defaultPhase;
    final moveList = profile['battlepage-move-list'] ?? '';
    final boardInversed = profile['battlepage-board-inversed'] ?? false;
    _oppoHuman = profile['battlepage-oppo-human'] ?? false;

    prt('boardInversed: $boardInversed');

    final phase = Fen.phaseFromFen(initBoard)!;

    for (var i = 0; i < moveList.length; i += 4) {
      //
      final move = Move.fromCoordinate(
        int.parse(moveList.substring(i + 0, i + 1)),
        int.parse(moveList.substring(i + 1, i + 2)),
        int.parse(moveList.substring(i + 2, i + 3)),
        int.parse(moveList.substring(i + 3, i + 4)),
      );

      phase.move(move.from, move.to);
    }

    _boardState.inverseBoard(boardInversed, notify: false);
    _boardState.setPhase(phase);
  }

  Future<bool> saveBattle() async {
    //
    final moveList = _boardState.buildMoveListForManual();

    final profile = await Profile.local().load();

    profile['battlepage-init-board'] = Fen.defaultPhase;
    profile['battlepage-move-list'] = moveList;
    profile['battlepage-board-inversed'] = _boardState.boardInversed;
    profile['battlepage-oppo-human'] = _oppoHuman;

    return await profile.save();
  }

  confirmNewGame() {
    //
    bool oppoFirst = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('开始新对局？', style: GameFonts.uicp()),
        content: SingleChildScrollView(
          child: Column(
            children: [
              CheckboxListTileEx(
                title: const Text('对方先行'),
                onChanged: (value) => oppoFirst = value,
                value: oppoFirst,
              ),
              CheckboxListTileEx(
                title: const Text('玩家控制双方棋子'),
                onChanged: (value) => _oppoHuman = value,
                value: _oppoHuman,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('确定'),
            onPressed: () {
              Navigator.of(context).pop();
              newGame(oppoFirst);
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

  newGame(bool oppoFirst) async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.start, context)) return;

    _boardState.inverseBoard(oppoFirst);

    _boardState.load(Fen.defaultPhase, notify: true);

    if (oppoFirst && !_oppoHuman) askEngineGo();

    setState(() {});

    ReviewPanel.popRequest();
  }

  regret() {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.regret, context)) return;

    _boardState.regret(GameScene.battle, steps: 2);
  }

  analysisPhase() async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.requestAnalysis, context)) {
      return;
    }

    if (_working) return;

    _working = true;
    showSnackBar(
      context,
      '正在分析局面...',
      shortDuration: true,
    );

    try {
      final result = await CloudEngine.analysis(_boardState.phase);

      if (result.type == 'analysis') {
        //
        List<AnalysisItem> items = result.value;
        for (var item in items) {
          item.stepName = StepName.translate(
            _boardState.phase,
            Move.fromEngineStep(item.move),
          );
        }
        showAnalysisItems(
          context,
          items: result.value,
          callback: (index) => Navigator.of(context).pop(),
        );
      } else if (result.type == 'no-result') {
        showSnackBar(context, '已请求服务器计算，请稍后查看！');
      } else {
        showSnackBar(
          context,
          sprintf('错误：%s', [result.type]),
        );
      }
    } catch (e) {
      showSnackBar(
        context,
        sprintf('错误：%s', [e.toString()]),
      );
    } finally {
      _working = false;
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
          title: Text(item.stepName!, style: GameFonts.ui(fontSize: 18)),
          subtitle: Text(
            sprintf('获胜机率：.2f%', [item.winrate]),
          ),
          trailing: Text(
            sprintf('局面评分：%d', [item.score]),
          ),
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

  askEngineHint() async {
    //
    if (AdTrigger.battle.checkAdChance(AdAction.requestHint, context)) return;

    if (_working) return;

    _working = true;
    _pageState.changeStatus('引擎思考提示着法...');

    final EngineResponse searchResult;
    try {
      searchResult = await BattleAgent.shared.engineThink(
        _boardState.phase,
      );
    } finally {
      _working = false;
    }

    if (searchResult.type == Engine.kMove) {
      //
      final step = searchResult.value;

      _boardState.move(step.from, step.to);
      startPieceAnimation();

      final result = BattleAgent.shared.scanBattleResult(
        _boardState.phase,
        _boardState.playerSide,
      );

      switch (result) {
        case BattleResult.pending:
          if (_boardState.isOppoTurn && !_oppoHuman) {
            Future.delayed(const Duration(seconds: 1), () => askEngineGo());
          }
          break;
        case BattleResult.win:
          gotWin();
          break;
        case BattleResult.lose:
          gotLose();
          break;
        case BattleResult.draw:
          gotDraw();
          break;
      }

      //
    } else if (searchResult.type == Engine.kNoBestMove) {
      _pageState.changeStatus('引擎无可用招法！');
    } else if (searchResult.type == Engine.kNetworkError) {
      _pageState.changeStatus('网络错误，请重试！');
    } else {
      _pageState.changeStatus('Error: ${searchResult.type}');
    }
  }

  swapPhase() {
    //
    _boardState.inverseBoard(!_boardState.boardInversed);

    if (_boardState.isOppoTurn && !_oppoHuman) {
      askEngineGo();
    } else {
      _pageState.changeStatus(BattlePage.yourTurn);
    }
  }

  inverseBoard() {
    _boardState.inverseBoard(!_boardState.boardInversed, swapSite: true);
  }

  saveManual() async {
    //
    final success = await _boardState.saveManual(GameScene.battle);

    if (success) {
      showSnackBar(context, '保存成功！');
    } else {
      showSnackBar(context, '保存失败！');
    }
  }

  onBoardTap(BuildContext context, int index) {
    //
    if (_boardState.boardInversed) index = 89 - index;

    final phase = _boardState.phase;

    // 仅 Phase 中的 side 指示一方能动棋
    if (_boardState.isOppoTurn && !_oppoHuman) return;

    final tapedPiece = phase.pieceAt(index);

    // 之前已经有棋子被选中了
    if (_boardState.focusIndex != Move.invalidIndex &&
        Side.of(phase.pieceAt(_boardState.focusIndex)) == phase.side) {
      //
      // 当前点击的棋子和之前已经选择的是同一个位置
      if (_boardState.focusIndex == index) return;

      // 之前已经选择的棋子和现在点击的棋子是同一边的，说明是选择另外一个棋子
      final focusPiece = phase.pieceAt(_boardState.focusIndex);

      if (Side.sameSide(focusPiece, tapedPiece)) {
        _boardState.select(index);
        return;
      }

      // 现在点击的棋子和上一次选择棋子不同边，要么是吃子，要么是移动棋子到空白处
      if (_boardState.move(_boardState.focusIndex, index)) {
        //
        startPieceAnimation();

        final result = BattleAgent.shared.scanBattleResult(
          _boardState.phase,
          _boardState.playerSide,
        );

        switch (result) {
          case BattleResult.pending:
            if (!_oppoHuman) {
              Future.delayed(const Duration(seconds: 1), () => askEngineGo());
            }
            break;
          case BattleResult.win:
            gotWin();
            break;
          case BattleResult.lose:
            gotLose();
            break;
          case BattleResult.draw:
            gotDraw();
            break;
        }
      }
    } else if (tapedPiece != Piece.empty && Side.of(tapedPiece) == phase.side) {
      // 之前未选中棋子，现在点击就是选择棋子
      _boardState.select(index);
    }
  }

  askEngineGo() async {
    //
    if (_working) return;

    _working = true;
    _pageState.changeStatus('对方思考中...');

    final EngineResponse searchResult;
    try {
      searchResult = await BattleAgent.shared.engineThink(
        _boardState.phase,
      );
    } finally {
      _working = false;
    }

    if (searchResult.type == Engine.kMove) {
      //
      final Move step = searchResult.value;
      _boardState.move(step.from, step.to);

      if (_boardState.phase.appearRepeatPhase()) {
        final recorder = _boardState.phase.recorder;
        final lastRoundStep = recorder.stepAt(recorder.historyLength - 3);
        CloudEngine.banMoves = 'move:${step.step}|move:${lastRoundStep.step}';
      } else {
        CloudEngine.banMoves = null;
      }

      startPieceAnimation();

      final result = BattleAgent.shared.scanBattleResult(
        _boardState.phase,
        _boardState.playerSide,
      );

      switch (result) {
        //
        case BattleResult.pending:
          if (step.score != null) {
            final engine = (searchResult.engine == Engine.kCloud) ? '云库' : 'AI';
            _pageState.changeStatus(
              sprintf(
                '%s 评估 %d 分，%s',
                [engine, (step.score ?? 0) * -1, BattlePage.yourTurn],
              ),
            );
          } else {
            _pageState.changeStatus(BattlePage.yourTurn);
          }
          break;
        case BattleResult.win:
          gotWin();
          break;
        case BattleResult.lose:
          gotLose();
          break;
        case BattleResult.draw:
          gotDraw();
          break;
      }

      //
    } else if (searchResult.type == Engine.kNoBestMove) {
      //
      gotWin();
      //
    } else if (searchResult.type == Engine.kNetworkError) {
      //
      // 撤销人走的一步棋，下次人重新走棋时，还可以重新请求引擎
      _boardState.regret(GameScene.battle, steps: 1);

      showSnackBar(context, '网络错误，请重试！');
      _pageState.changeStatus('网络错误，请重试！');

      //
    } else if (searchResult.type == Engine.kTimeout) {
      //
      // 撤销人走的一步棋，下次人重新走棋时，还可以重新请求引擎
      _boardState.regret(GameScene.battle, steps: 1);

      showSnackBar(context, '引擎超时未回复，请重试一次！');
      _pageState.changeStatus('引擎超时未回复，请重试一次！');

      //
    } else {
      // 撤销人走的一步棋，下次人重新走棋时，还可以重新请求引擎
      _boardState.regret(GameScene.battle, steps: 1);

      showSnackBar(context, searchResult.type);
      _pageState.changeStatus(searchResult.type);
    }
  }

  gotWin() async {
    //
    await Future.delayed(const Duration(seconds: 1));

    Audios.playTone('win.mp3');
    _boardState.phase.result = BattleResult.win;

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
    _boardState.phase.result = BattleResult.lose;

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
    _boardState.phase.result = BattleResult.draw;

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
    final header = createPageHeader(context, GameScene.battle);
    final board = createChessBoard(
      context,
      GameScene.battle,
      onBoardTap: onBoardTap,
      oppoHuman: _oppoHuman,
    );
    final operatorBar = OperationBar(items: [
      ActionItem(name: '新局', callback: confirmNewGame),
      ActionItem(name: '悔棋', callback: regret),
      ActionItem(name: '提示', callback: askEngineHint),
      ActionItem(name: '分析', callback: analysisPhase),
      ActionItem(name: '交换局面', callback: swapPhase),
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
    if (Ruler.isLongScreen(context)) {
      return buildManualPanel(_boardState.phase.manualText);
    }

    return buildExpandableManaulPanel(context, _boardState.phase.manualText);
  }

  Widget buildManualPanel(String text) {
    //
    final manualStyle = GameFonts.ui(
      fontSize: 18,
      color: GameColors.darkTextSecondary,
      height: 1.5,
    );

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(child: Text(text, style: manualStyle)),
      ),
    );
  }

  Widget buildExpandableManaulPanel(BuildContext context, String text) {
    //
    final manualStyle = GameFonts.ui(fontSize: 18, height: 1.5);

    return Expanded(
      child: IconButton(
        icon: const Icon(Icons.expand_less, color: GameColors.darkTextPrimary),
        onPressed: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('棋谱', style: GameFonts.uicp()),
            content: SingleChildScrollView(
              child: Text(text, style: manualStyle),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    //
    saveBattle().then((_) => _boardState.inverseBoard(false, notify: false));

    super.dispose();
  }
}
