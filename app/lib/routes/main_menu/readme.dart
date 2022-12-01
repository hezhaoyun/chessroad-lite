import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../game/game.dart';
import '../../ui/snack_bar.dart';

showReadme(BuildContext context) {
  //
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('棋路 Lite 版', style: GameFonts.uicp()),
      content: Linkify(
        text: '这是棋路的「开源精简」版！\n\n'
            '使用了目前棋力最强的开源引擎 - 皮卡鱼！\n\n'
            '完整版本的棋路，已为棋友提供了全面的象棋学习、训练资源！\n'
            '请从以下地址下载棋路完整版：\n\n'
            'https://mdevs.cn',
        style: GameFonts.uicp(fontSize: 16),
        onOpen: (link) async {
          Navigator.of(context).pop();
          await openLink(link.url, context);
        },
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            Platform.isAndroid ? '下载完整版' : '查看',
            style: GameFonts.uicp(fontSize: 16),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await openLink(
              Platform.isAndroid
                  ? 'https://mdevs.cn/chessroad.apk'
                  : 'https://mdevs.cn',
              context,
            );
          },
        ),
        TextButton(
          child: Text('知道了', style: GameFonts.uicp(fontSize: 16)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

Future<void> openLink(String url, BuildContext context) async {
  //
  bool success;
  try {
    success = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    success = false;
  }

  if (!success) {
    Clipboard.setData(ClipboardData(text: url));
    showSnackBar('链接已复制到剪贴板！');
  }
}
