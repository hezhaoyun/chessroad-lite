import 'dart:math';

import 'package:flutter/material.dart';

class Petal {
  //
  Offset position, origin;
  double speed, radius;
  Color color;

  Petal(this.position, this.origin, this.color, this.speed, this.radius);
}

class FlowerPainter extends CustomPainter {
  //
  final List<Petal> petals;

  final Paint _paint = Paint()..isAntiAlias = true;
  final Random _random = Random(DateTime.now().microsecondsSinceEpoch);

  FlowerPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    //
    for (final p in petals) {
      //
      double dx = -_random.nextDouble() / 2;
      double dy = p.speed;
      p.position += Offset(dx, dy);

      if (p.position.dy > size.height) {
        p.position = p.origin;
      }
    }

    for (var p in petals) {
      _paint.color = p.color;
      canvas.drawCircle(p.position, p.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

mixin FlowersMixin {
  //
  late BuildContext _context;
  late Function _callUpdate;

  final List<Petal> _petals = [];
  final Random _random = Random(DateTime.now().microsecondsSinceEpoch);

  late AnimationController _animationController;

  void createFlowers(BuildContext ctx, TickerProvider vsync, Function cb) {
    //
    _context = ctx;
    _callUpdate = cb;

    Future.delayed(Duration.zero, () => initData());

    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 10),
    );

    _animationController.addListener(() => _callUpdate());
    _animationController.repeat();
  }

  void initData() {
    //
    for (int i = 0; i < 160; i++) {
      //
      final x = _random.nextDouble() * MediaQuery.of(_context).size.width;
      final y = _random.nextDouble() * MediaQuery.of(_context).size.height;
      final z = _random.nextDouble() + 0.5;

      final position = Offset(x, y);
      final origin = Offset(x, 0);
      final color = getRandomColor();
      final speed = _random.nextDouble() + 0.01 / z;
      final radius = 2.0 / z;

      _petals.add(Petal(position, origin, color, speed, radius));
    }
  }

  Color getRandomColor() {
    final alpha = _random.nextInt(180);
    return Color.fromARGB(alpha, 0xEE, 0x41, 0x5d1);
  }

  Widget buildFlowersCanvas() => CustomPaint(
        size: MediaQuery.of(_context).size,
        painter: FlowerPainter(_petals),
      );
}
