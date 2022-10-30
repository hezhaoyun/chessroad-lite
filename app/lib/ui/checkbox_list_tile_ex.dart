import 'package:flutter/material.dart';

class CheckboxListTileEx extends StatefulWidget {
  //
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? title;
  final Widget? subtitle;

  const CheckboxListTileEx({
    Key? key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  CheckboxListTileExState createState() => CheckboxListTileExState();
}

class CheckboxListTileExState extends State<CheckboxListTileEx> {
  //
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    //
    return CheckboxListTile(
      title: widget.title,
      subtitle: widget.subtitle,
      onChanged: (value) {
        setState(() => this.value = value!);
        widget.onChanged(value!);
      },
      value: value,
    );
  }
}
