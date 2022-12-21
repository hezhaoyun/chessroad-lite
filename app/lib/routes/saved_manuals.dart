import 'dart:convert';
import 'dart:io';

import 'package:chessroad/common/file_extension.dart';
import 'package:chessroad/routes/main_menu/readme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/prt.dart';
import '../game/game.dart';
import '../game/page_state.dart';
import '../ui/build_utils.dart';
import '../ui/settings/edit_page.dart';

class ManualRef {
  Key? data;
  String path;
  String title;
  final Map<String, dynamic> content;
  ManualRef(this.path, this.title, this.content);
}

class SavedManuals extends StatefulWidget {
  //
  const SavedManuals({Key? key}) : super(key: key);

  @override
  State<SavedManuals> createState() => _SavedManualsState();
}

class _SavedManualsState extends State<SavedManuals> {
  //
  late PageState _pageState;

  bool _loading = false;

  final List<ManualRef> _manuals = [];

  @override
  void initState() {
    //
    super.initState();

    _pageState = Provider.of<PageState>(context, listen: false);
    _pageState.changeStatus('左滑删除，右滑改名', notify: false);

    refresh();
  }

  Future<void> refresh() async {
    //
    if (_loading) return;

    setState(() => _loading = true);

    _manuals.clear();

    final loaded = await loadManuals();

    if (mounted) {
      _manuals.addAll(loaded);
      setState(() => _loading = false);
    }
  }

  openManual(int index) async {
    //
    final file = File(_manuals[index].path);
    final content = await file.readAsString();

    List<int> bytes = utf8.encode(content);
    String crmBase64 = base64Encode(bytes);

    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'mdevs.cn',
      path: _manuals[index].path,
      queryParameters: {'crm': crmBase64},
    );

    bool success;

    try {
      success = await launchUrl(launchUri);
    } catch (e) {
      success = false;
    }

    if (!success) if (mounted) showReadme(context);
  }

  Future<List<ManualRef>> loadManuals() async {
    //
    final appDocDir = await getApplicationDocumentsDirectory();
    prt(appDocDir.path);

    final List<ManualRef> manuals = [];

    try {
      final folder = Directory('${appDocDir.path}/saved');
      final entities = await folder.list().toList();

      entities.sort((a, b) => b.path.compareTo(a.path));

      for (var entity in entities) {
        //
        final entityPath = entity.path;
        final entityLowerCase = entityPath.toLowerCase();

        ManualRef? manual;

        if (entityLowerCase.endsWith('.crm')) {
          //
          final file = File(entityPath);

          final contents = await file.readAsString();

          final map = jsonDecode(contents) as Map<String, dynamic>;

          manual = ManualRef(entityPath, file.basename, map);
        }

        if (manual != null) {
          manual.data = GlobalKey<_SavedManualsState>();
          manuals.add(manual);
        }
      }
    } catch (e) {
      prt('loadManuals: $e');
    }

    return manuals;
  }

  Future<bool> confirmEdit(ManualRef manual) async {
    //
    var confirm = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('改名', style: GameFonts.uicp()),
        content: const Text('现在去修改棋谱名称吗？'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    if (confirm) {
      await editManualName(manual);
    }

    return false;
  }

  Future<bool> confirmDelete() async {
    //
    var confirm = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('DELETE', style: GameFonts.uicp()),
        content: const Text('删除棋谱？'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    return confirm;
  }

  editManualName(ManualRef manual) async {
    //
    final newName = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EditPage(
          '棋谱名称',
          initValue: manual.title,
        ),
      ),
    );

    if (newName != null) {
      //
      final file = File(manual.path);

      final parent = file.parent.path;
      final ext = file.ext;
      final newPath = '$parent/$newName.$ext';

      await file.rename(newPath);

      setState(() {
        manual.title = newName;
        manual.path = newPath;
      });
    }
  }

  deleteManual(ManualRef manual) async {
    final file = File(manual.path);
    await file.delete(recursive: true);
  }

  buildTile(int index) {
    //
    if (index == _manuals.length) {
      //
      if (_manuals.isEmpty && !_loading) {
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '--',
              style: GameFonts.ui(fontSize: 16, color: Colors.black38),
            ),
          ),
        );
      }

      return _loading ? buildLoadingWidget() : const SizedBox();
    }

    final titleStyle = GameFonts.uicp(fontSize: 16);
    final subtitleStyle = GameFonts.uicp(fontSize: 13);

    final tile = ListTile(
      leading: const Icon(Icons.book, color: GameColors.secondary),
      title: Text(_manuals[index].title, style: titleStyle),
      subtitle: Text('在完整版中查看', style: subtitleStyle),
      trailing: const Icon(
        Icons.keyboard_arrow_right,
        color: GameColors.secondary,
      ),
      onTap: () => openManual(index),
    );

    final deleteBg = Container(
      color: Colors.red,
      child: Row(
        children: <Widget>[
          const Expanded(child: SizedBox()),
          Text(
            'DELETE',
            style: GameFonts.ui(color: Colors.white, fontSize: 17),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
    final editBg = Container(
      color: Colors.blueAccent,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          Text(
            '改名',
            style: GameFonts.ui(color: Colors.white, fontSize: 17),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );

    final manual = _manuals[index];

    return Dismissible(
      key: manual.data!,
      direction: DismissDirection.horizontal,
      background: editBg,
      secondaryBackground: deleteBg,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) return confirmEdit(manual);
        if (dir == DismissDirection.endToStart) return confirmDelete();
        return false;
      },
      onDismissed: (dir) async {
        if (dir == DismissDirection.endToStart) await deleteManual(manual);
      },
      child: tile,
    );
  }

  buildLoadingWidget() {
    //
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const <Widget>[CircularProgressIndicator(strokeWidth: 1.0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //
    final header = createPageHeader(context, GameScene.gameNotation);

    final list = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: GameColors.boardBackground,
      ),
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          itemCount: _manuals.length + 1,
          itemBuilder: (context, index) => buildTile(index),
        ),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(children: <Widget>[
          header,
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: list,
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    //
    super.dispose();
  }
}
