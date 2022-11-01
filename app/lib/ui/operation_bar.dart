import 'package:flutter/material.dart';

import '../game/game.dart';
import 'build_utils.dart';
import 'ruler.dart';

class ActionItem {
  final String name;
  final VoidCallback? callback;
  ActionItem({required this.name, this.callback});
}

class OperationBar extends StatefulWidget {
  //
  final List<ActionItem> items;

  const OperationBar({Key? key, required this.items}) : super(key: key);

  @override
  State<OperationBar> createState() => _OperationBarState();
}

class _OperationBarState extends State<OperationBar> {
  //
  final keys = <GlobalKey>[];
  final GlobalKey containerKey = GlobalKey();

  final buttonStyle = GameFonts.art(fontSize: 20, color: GameColors.primary);
  final finalChildren = <Widget>[];

  bool finalLayout = false;

  showMore() {
    //
    if (finalChildren.length == widget.items.length) return;

    final itemStyle = GameFonts.uicp(fontSize: 18);
    final moreItems = widget.items.sublist(finalChildren.length);

    final children = <Widget>[];

    if (moreItems.length < 5) {
      for (final e in moreItems) {
        children.add(
          ListTile(
            title: Text(e.name, style: itemStyle),
            onTap: () {
              Navigator.of(context).pop();
              if (e.callback != null) e.callback!();
            },
          ),
        );
        children.add(const Divider());
      }
    } else {
      //
      for (var i = 0; i < moreItems.length; i += 2) {
        //
        final left = moreItems[i];
        final right = i + 1 < moreItems.length ? moreItems[i + 1] : null;

        children.add(
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextButton(
                  child: Text(left.name, style: itemStyle),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (left.callback != null) left.callback!();
                  },
                ),
              ),
              Container(width: 1, height: 18, color: Colors.black12),
              Expanded(
                flex: 1,
                child: right == null
                    ? const SizedBox()
                    : TextButton(
                        child: Text(right.name, style: itemStyle),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (right.callback != null) right.callback!();
                        },
                      ),
              ),
            ],
          ),
        );
        children.add(const Divider());
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 10),
            ...children,
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  List<Widget> attemptChildren() {
    //
    final buttons = <TextButton>[];

    for (final e in widget.items) {
      //
      final globalKey = GlobalKey();
      keys.add(globalKey);

      buttons.add(
        TextButton(
          key: globalKey,
          onPressed: null,
          child: Text(e.name, style: buttonStyle),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      calcWeightPosition(buttons);
      setState(() => finalLayout = true);
    });

    return buttons;
  }

  calcWeightPosition(List<TextButton> buttons) {
    //
    var left = 0.0;

    final containerWidth = containerKey.currentContext!.size!.width;

    for (var i = 0; i < buttons.length; i++) {
      //
      if (i > 0) left = left + keys[i - 1].currentContext!.size!.width;
      if (left + keys[i].currentContext!.size!.width >= containerWidth) break;

      final e = widget.items[i];

      // buttons 中的按钮会被 unmount，这里直接重建
      finalChildren.add(TextButton(
        onPressed: e.callback,
        child: Text(e.name, style: buttonStyle),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    //
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: GameColors.boardBackground,
      ),
      margin: EdgeInsets.symmetric(horizontal: boardPaddingH(context)),
      padding: const EdgeInsets.symmetric(vertical: 2),
      height: Ruler.kOperationBarHeight,
      child: Row(
        children: [
          Expanded(
            key: containerKey,
            child: Row(
              children: finalLayout ? finalChildren : attemptChildren(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: GameColors.primary),
            onPressed: showMore,
          ),
        ],
      ),
    );
  }
}
