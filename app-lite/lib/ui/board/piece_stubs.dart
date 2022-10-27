import 'package:flutter/material.dart';

class PiecePaintStub {
  final String piece;
  final Offset pos;
  PiecePaintStub({required this.piece, required this.pos});
}

class PieceLayoutStub {
  //
  final String piece;
  final double diameter;
  final bool selected;
  final double x, y;
  final bool rotate;

  PieceLayoutStub({
    required this.piece,
    required this.diameter,
    required this.selected,
    required this.x,
    required this.y,
    this.rotate = false,
  });
}
