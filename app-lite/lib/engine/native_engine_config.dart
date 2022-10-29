import 'package:chessroad/config/local_data.dart';

class NativeEngineConfig {
  //
  static String get engineName => LocalData().engineName.value;
  static NativeEngineConfig get current =>
      levels[LocalData().engineConfig.value];

  static const puzzleConfig = NativeEngineConfig(
    'Puzzle',
    -1,
    7,
    3000,
    knowledge: 'small',
    pruning: 'small',
    randomness: 'none',
    useBook: true,
  );

  static const analysisConfig = NativeEngineConfig(
    'Analysis',
    -1,
    8,
    1000,
    knowledge: 'large',
    pruning: 'large',
    randomness: 'none',
    useBook: true,
  );

  static final levels = [
    const NativeEngineConfig(
      '一级',
      0,
      1,
      1000,
      knowledge: 'none',
      pruning: 'none',
      randomness: 'large',
      useBook: false,
    ),
    const NativeEngineConfig(
      '二级',
      1,
      2,
      2000,
      knowledge: 'none',
      pruning: 'none',
      randomness: 'large',
      useBook: false,
    ),
    const NativeEngineConfig(
      '三级',
      2,
      3,
      3000,
      knowledge: 'small',
      pruning: 'small',
      randomness: 'large',
      useBook: false,
    ),
    const NativeEngineConfig(
      '四级',
      3,
      4,
      4000,
      knowledge: 'medium',
      pruning: 'small',
      randomness: 'medium',
      useBook: false,
    ),
    const NativeEngineConfig(
      '五级',
      4,
      5,
      5000,
      knowledge: 'medium',
      pruning: 'medium',
      randomness: 'large',
      useBook: true,
    ),
    const NativeEngineConfig(
      '六级',
      5,
      6,
      6000,
      knowledge: 'medium',
      pruning: 'medium',
      randomness: 'large',
      useBook: true,
    ),
    const NativeEngineConfig(
      '七级',
      6,
      7,
      8000,
      knowledge: 'large',
      pruning: 'large',
      randomness: 'small',
      useBook: true,
    ),
    const NativeEngineConfig(
      '八级',
      7,
      8,
      10000,
      knowledge: 'large',
      pruning: 'large',
      randomness: 'small',
      useBook: true,
    ),
    const NativeEngineConfig(
      '九级',
      8,
      8,
      15000,
      knowledge: 'large',
      pruning: 'large',
      randomness: 'none',
      useBook: true,
    ),
    const NativeEngineConfig(
      '十级',
      9,
      8,
      24000,
      knowledge: 'large',
      pruning: 'large',
      randomness: 'none',
      useBook: true,
    ),
  ];

  final String name;
  final int level;
  final int depth;
  final int timeLimit;
  final String knowledge;
  final String pruning;
  final String randomness;
  final bool useBook;

  const NativeEngineConfig(
    this.name,
    this.level,
    this.depth,
    this.timeLimit, {
    required this.knowledge,
    required this.pruning,
    required this.randomness,
    required this.useBook,
  });
}
