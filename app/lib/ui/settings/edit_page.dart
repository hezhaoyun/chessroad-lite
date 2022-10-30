import 'package:flutter/material.dart';

import '../../game/game.dart';

class EditPage extends StatefulWidget {
  //
  final String title;
  final String? initValue;
  const EditPage(this.title, {Key? key, this.initValue}) : super(key: key);

  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  //
  late TextEditingController _textController;
  final FocusNode _commentFocus = FocusNode();

  onSubmit(String input) {
    Navigator.of(context).pop(input);
  }

  @override
  void initState() {
    //
    _textController = TextEditingController();
    _textController.text = widget.initValue!;

    Future.delayed(
      const Duration(milliseconds: 10),
      () => FocusScope.of(context).requestFocus(_commentFocus),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: GameColors.secondary),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          TextButton(
            child: Text(
              'OK',
              style: GameFonts.ui(color: Colors.white),
            ),
            onPressed: () => onSubmit(_textController.text),
          )
        ],
      ),
      backgroundColor: GameColors.lightBackground,
      body: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder,
              ),
              style: GameFonts.uicp(fontSize: 16),
              onSubmitted: (input) => onSubmit(input),
              focusNode: _commentFocus,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void deactivate() {
    FocusScope.of(context).requestFocus(FocusNode());
    super.deactivate();
  }
}
