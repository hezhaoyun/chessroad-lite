import 'dart:io';

import 'package:chessroad/routes/main_menu/readme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../../config/local_data.dart';
import '../../game/game.dart';

Future openPrivacyPolicy(BuildContext context) async {
  //
  const url = 'https://www.mdevs.cn/privacy-policy.html';

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('隐私政策', style: GameFonts.uicp()),
      content: SingleChildScrollView(
        child: Linkify(
          onOpen: (link) async => openLink(url, context),
          text: '请你务必审慎阅读我们的 http://《隐私政策》 包含但不限于我们需要收集你'
              '的设备信息、操作日志等个人信息。如果同意，请点击「同意」按钮！',
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('拒绝'),
          onPressed: () async {
            LocalData().acceptedPrivacyPolicy.value = false;
            await LocalData().save();
            exit(0);
          },
        ),
        TextButton(
          child: const Text('同意'),
          onPressed: () async {
            Navigator.of(context).pop();
            LocalData().acceptedPrivacyPolicy.value = true;
            await LocalData().save();
          },
        )
      ],
    ),
  );
}
