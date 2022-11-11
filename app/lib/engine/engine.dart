import '../cchess/phase.dart';
import 'analysis.dart';

enum EngineType { cloudLibrary, pikafish }

abstract class Response {
  // empty
}

class NoBestmove extends Response {
  // empty
}

class Error extends Response {
  final String message;
  Error(this.message);
}

class Bestmove extends Response {
  //
  late String bestmove;
  String? ponder;

  Bestmove(this.bestmove, {this.ponder});

  Bestmove.parse(String line) : super() {
    //
    var regx = RegExp(r'bestmove (\w+)');
    var match = regx.firstMatch(line);

    if (match != null) {
      //
      bestmove = match.group(1)!;

      regx = RegExp(r'ponder (\w+)');
      match = regx.firstMatch(line);

      if (match != null) {
        ponder = match.group(1);
      }
    }
  }
}

class EngineInfo extends Response {
  //
  final tokens = <String, int>{};
  final pvs = <String>[];

  EngineInfo.parse(String line) {
    //
    // info depth 10 seldepth 13 multipv 1 score cp -75 nodes 14091
    // nps 6358 hashfull 4 tbhits 0 time 2216 pv h9g7 h0g2 i9h9 i0h0
    // b9c7 h0h4 c9e7 c3c4 h7i7 h4h9 g7h9 g3g4
    final regx = RegExp(
      r'info depth (\d+) seldepth (\d+) multipv (\d+) score cp (-?\d+) '
      r'nodes (\d+) nps (\d+) hashfull (\d+) tbhits (\d+) time (\d+) pv (.*)',
    );
    final match = regx.firstMatch(line);

    if (match != null) {
      //
      tokens['depth'] = int.parse(match.group(1)!);
      tokens['seldepth'] = int.parse(match.group(2)!);
      tokens['multipv'] = int.parse(match.group(3)!);
      tokens['score'] = int.parse(match.group(4)!);
      tokens['nodes'] = int.parse(match.group(5)!);
      tokens['nps'] = int.parse(match.group(6)!);
      tokens['hashfull'] = int.parse(match.group(7)!);
      tokens['tbhits'] = int.parse(match.group(8)!);
      tokens['time'] = int.parse(match.group(9)!);

      final pv = match.group(10)!;
      pvs.addAll(pv.split(' '));
    }
  }
}

class Analysis extends Response {
  final List<AnalysisItem> items;
  Analysis(this.items);
}

class EngineResponse {
  final EngineType type;
  final Response response;
  EngineResponse(this.type, this.response);
}

typedef EngineCallback = Function(EngineResponse);

abstract class Engine {
  //
  Future<void> startup() async {}

  Future<void> applyConfig() async {}

  Future<bool> search(Phase phase, Function(EngineResponse) callback) async {
    return false;
  }

  void ponderhit() async {}

  void scheduleStop(Duration? duration) async {}

  Future<void> shutdown() async {}
}
