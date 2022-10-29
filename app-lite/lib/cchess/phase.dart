import 'dart:convert';
import 'dart:io';
import 'package:date_format/date_format.dart';
import 'package:path_provider/path_provider.dart';
import '../../common/prt.dart';
import '../../game/game.dart';
import 'cc_rules.dart';
import 'cc_base.dart';
import 'step_name.dart';
import 'cc_fen.dart';
import 'move_recorder.dart';

class Phase {
  //
  BattleResult result = BattleResult.pending;

  late String _side;
  late List<String> _pieces; // 10 行，9 列
  late MoveRecorder _recorder;

  String _initBoard = '';
  String? _lastCapturedPhase;

  static Phase defaultPhase() {
    return Fen.phaseFromFen(Fen.defaultPhase)!;
  }

  Phase(List<String> pieces, String side, MoveRecorder recorder) {
    //
    _pieces = pieces;
    _side = side;
    _recorder = recorder;

    updateInitPhase();
  }

  Phase.clone(Phase other) {
    deepCopy(other);
  }

  String get initBoard => _initBoard;

  void updateInitPhase() {
    _lastCapturedPhase = Fen.phaseToFen(this);
    _initBoard = Fen.phaseToCrManualBoard(this);
  }

  void deepCopy(Phase other) {
    //
    _pieces = [];
    for (var piece in other._pieces) {
      _pieces.add(piece);
    }

    _side = other._side;

    _recorder = MoveRecorder(
      halfMove: other._recorder.halfMove,
      fullMove: other._recorder.fullMove,
    );

    _initBoard = other._initBoard;
  }

  bool move(Move move, {validate = true}) {
    //
    // 移动是否符合象棋规则
    if (validate && !validateMove(move.from, move.to)) {
      return false;
    }

    // 生成棋步，记录步数
    final captured = _pieces[move.to];

    move.captured = captured;
    move.counterMarks = _recorder.toString();

    StepName.translate(this, move);
    _recorder.stepIn(move, _side);

    // 修改棋盘
    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.empty;

    // 交换走棋方
    _side = Side.oppo(_side);

    // 记录最近一个吃子局面的 FEN，UCCI 引擎需要
    if (captured != Piece.empty) {
      _lastCapturedPhase = Fen.phaseToFen(this);
    }

    return true;
  }

  // 在判断行棋合法性等环节，要在克隆的棋盘上进行行棋假设，然后检查效果
  // 这种情况下不验证、不记录、不翻译
  void moveTest(Move move, {turnSide = false}) {
    //
    // 修改棋盘
    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.empty;

    // 交换走棋方
    if (turnSide) _side = Side.oppo(_side);
  }

  bool regret() {
    //
    final lastMove = _recorder.removeLast();
    if (lastMove == null) return false;

    _pieces[lastMove.from] = _pieces[lastMove.to];
    _pieces[lastMove.to] = lastMove.captured;

    _side = Side.oppo(_side);

    final counterMarks = MoveRecorder.fromCounterMarks(lastMove.counterMarks);
    _recorder.halfMove = counterMarks.halfMove;
    _recorder.fullMove = counterMarks.fullMove;

    if (lastMove.captured != Piece.empty) {
      //
      // 查找上一个吃子局面（或开局），NativeEngine 需要
      final tempPhase = Phase.clone(this);

      final moves = _recorder.reverseMovesToPrevCapture();
      for (var move in moves) {
        //
        tempPhase._pieces[move.from] = tempPhase._pieces[move.to];
        tempPhase._pieces[move.to] = move.captured;

        tempPhase._side = Side.oppo(tempPhase._side);
      }

      _lastCapturedPhase = Fen.phaseToFen(tempPhase);
    }

    result = BattleResult.pending;

    return true;
  }

  bool validateMove(int from, int to) {
    //
    // 移动的棋子的选手，应该是当前方
    if (Side.of(_pieces[from]) != _side) return false;

    return (ChessRules.validate(this, Move(from, to)));
  }

  Move last9steps(int index) =>
      _recorder.stepAt((_recorder.historyLength - 9) + index);

  bool isLongCheck() {
    //
    if (!appearRepeatPhase()) return false;

    final tempPhase = Phase.clone(this);
    for (var i = 0; i < 9; i++) {
      tempPhase.regret();
    }

    tempPhase.move(last9steps(0));
    if (!ChessRules.beChecked(tempPhase)) return false;

    tempPhase.move(last9steps(1));
    tempPhase.move(last9steps(2));
    if (!ChessRules.beChecked(tempPhase)) return false;

    tempPhase.move(last9steps(3));
    tempPhase.move(last9steps(4));
    if (!ChessRules.beChecked(tempPhase)) return false;

    tempPhase.move(last9steps(5));
    tempPhase.move(last9steps(6));
    if (!ChessRules.beChecked(tempPhase)) return false;

    tempPhase.move(last9steps(7));
    tempPhase.move(last9steps(8));
    if (!ChessRules.beChecked(tempPhase)) return false;

    return true;
  }

  bool appearRepeatPhase() {
    //
    if (_recorder.historyLength < 9) return false;

    bool same(Move m1, Move m2, [Move? m3]) {
      if (m3 == null) return m1.from == m2.from && m1.to == m2.to;
      return m1.from == m2.from &&
          m1.to == m2.to &&
          m1.from == m3.from &&
          m1.to == m3.to;
    }

    return same(last9steps(0), last9steps(4), last9steps(8)) &&
        same(last9steps(1), last9steps(5)) &&
        same(last9steps(2), last9steps(6)) &&
        same(last9steps(3), last9steps(7));
  }

  Future<bool> saveManual(GameScene scene) async {
    //
    final title = formatDate(
      DateTime.now(),
      [yyyy, '-', mm, '-', d, '_', HH, ':', nn, ':', ss],
    );

    const black = '棋路-象棋课堂';
    const clazz = '人机练习';

    final moveList = _recorder.buildMoveListForManual();
    String battleResult;

    switch (result) {
      case BattleResult.pending:
        battleResult = '未知';
        break;
      case BattleResult.win:
        battleResult = '红胜';
        break;
      case BattleResult.lose:
        battleResult = '黑胜';
        break;
      case BattleResult.draw:
        battleResult = '和棋';
        break;
    }

    final map = {
      'id': '0',
      'title': title,
      'event': '',
      'clazz': clazz,
      'red': '',
      'black': black,
      'result': battleResult,
      'init_board': _initBoard,
      'move_list': '[DhtmlXQ_movelist]$moveList[/DhtmlXQ_movelist]',
      'comment_list': '',
    };

    final appDocDir = await getApplicationDocumentsDirectory();

    try {
      final contents = jsonEncode(map);

      final file = File('${appDocDir.path}/saved/$title.crm');
      await file.create(recursive: true);

      await file.writeAsString(contents);
      //
    } catch (e) {
      prt('saveManual: $e');
      return false;
    }

    return true;
  }

  String buildPositionCommand({forEleeye = false}) {
    //
    final String? phase, moves;

    if (forEleeye) {
      phase = lastCapturedPhase;
      moves = movesAfterLastCaptured;
    } else {
      phase = Fen.phaseToFen(this);
      moves = allMoves;
    }

    if (moves == '') return 'position fen $phase';
    return 'position fen $phase moves $moves';
  }

  String? buildInfoText() {
    //
    if (lastMove == null) return '';
    final lmv = lastMove!;

    if (lmv.depth != null && lmv.score != null) {
      //
      // 有详细的 info 反馈，例如 皮卡鱼 引擎的反馈

      final score = lmv.score! * (Side.red == _side ? -1 : 1);
      final goodSide = score > 0
          ? '红优'
          : score < 0
              ? '黑优'
              : '均势';

      final pvMoves = lmv.pv ?? '';
      final mvs = pvMoves.split(' ');

      final tempPhase = Phase.clone(this);
      final lastSideIsRed = _side == Side.black;

      String blackStepName = '', otherStepNames = '';

      if (lastSideIsRed && mvs.length > 1) {
        final move = Move.fromEngineStep(mvs[1]);
        blackStepName = StepName.translate(tempPhase, move);
        tempPhase.move(move);
      }

      for (var i = lastSideIsRed ? 2 : 1; i < mvs.length; i += 2) {
        //
        var move = Move.fromEngineStep(mvs[i]);
        final redStep = StepName.translate(tempPhase, move);
        tempPhase.move(move);

        otherStepNames += '$redStep  ';

        if (i + 1 < mvs.length) {
          move = Move.fromEngineStep(mvs[i + 1]);
          final blackStep = StepName.translate(tempPhase, move);
          tempPhase.move(move);
          otherStepNames += '$blackStep\n';
        }
      }

      return '局面评估：$score '
          '($goodSide)\n'
          '搜索深度：${lmv.depth ?? 0}\n'
          '搜索节点：${lmv.nodes ?? 0}\n'
          '累计时间：${lmv.time ?? 0}\n'
          '后续着法：$blackStepName\n'
          '$otherStepNames\n';
    }

    return null;
  }

  String get infoText {
    return buildInfoText() ?? _recorder.buildManualText();
  }

  String buildMoveListForManual() => _recorder.buildMoveListForManual();

  // broken setting operation

  String pieceAt(int index) => _pieces[index];

  void setPiece(int index, String piece) => _pieces[index] = piece;

  String get side => _side;
  void trunSide() => _side = Side.oppo(_side);

  // broken access to recorder outside

  MoveRecorder get recorder => _recorder;

  Move? get lastMove => _recorder.last;
  int get halfMove => _recorder.halfMove; // 无吃子步数
  int get fullMove => _recorder.fullMove; // 总回合步数
  String get stepCount => _recorder.toString();

  String? get lastCapturedPhase => _lastCapturedPhase;
  String get allMoves => _recorder.allMoves();
  String get movesAfterLastCaptured => _recorder.movesAfterLastCaptured();
}
