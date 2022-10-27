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
                onPressed: () {
                  engine.startup();
                },
                child: const Text('Startup')),
            TextButton(
                onPressed: () {
                  engine.shutdown();
                },
                child: const Text('Shutdown')),
          ]),
        ),
      ),
    );
  }
}
