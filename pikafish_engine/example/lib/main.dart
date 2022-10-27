import 'package:flutter/material.dart';

import 'native_engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //
  final engine = NativeEngine();
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(children: [
            TextButton(
              onPressed: _working
                  ? null
                  : () async {
                      setState(() => _working = true);
                      await engine.startup();
                      await engine
                          .waitResponse(['ucciok'], sleep: 100, times: 200);
                      setState(() => _working = false);
                    },
              child: const Text('Startup'),
            ),
            TextButton(
              onPressed: _working
                  ? null
                  : () async {
                      setState(() => _working = true);
                      await engine.send(
                          'position fen rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1');
                      await engine.send('go movetime 1000');
                      await engine.waitResponse(['bestmove', 'nobestmove'],
                          sleep: 100, times: 200);
                      setState(() => _working = false);
                    },
              child: const Text('Go'),
            ),
            TextButton(
              onPressed: _working
                  ? null
                  : () async {
                      setState(() => _working = true);
                      await engine.shutdown();
                      await engine
                          .waitResponse(['bye'], sleep: 100, times: 200);
                      setState(() => _working = false);
                    },
              child: const Text('Shutdown'),
            ),
          ]),
        ),
      ),
    );
  }
}
