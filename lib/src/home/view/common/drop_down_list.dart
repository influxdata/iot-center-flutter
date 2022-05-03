import 'package:flutter/material.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class MyDropDown extends StatefulWidget {
  const MyDropDown(
      {this.padding = EdgeInsets.zero,
      this.hint = '',
      this.controller,
      required this.items,
      required this.mapValue,
      required this.label,
      this.onChanged,
      this.onSaved,
      Key? key})
      : super(key: key);

  final EdgeInsets padding;
  final String hint;
  final TextEditingController? controller;
  final List items;
  final String mapValue;
  final String label;
  final Function(String?)? onChanged;
  final Function(String?)? onSaved;

  @override
  State<StatefulWidget> createState() {
    return _MyDropDown();
  }
}

class _MyDropDown extends State<MyDropDown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var val = _controller.text;
    if (widget.items.isNotEmpty && val.isEmpty) {
      val = widget.items.first[widget.mapValue].toString();
    }

    var dropDown = DropdownButtonFormField<String>(
      isExpanded: true,
      hint: Text(widget.hint),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(5),
          gapPadding: 0,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(5),
          gapPadding: 0,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: val,
      items: widget.items
          .where((e) => e != null) //removes null items
          .toSet()
          .map((dynamic map) {
        return DropdownMenuItem<String>(
            value: map[widget.mapValue].toString(),
            child: Text(
              map[widget.label],
              style: const TextStyle(fontSize: 16),
            ));
      }).toList(),
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
    );

    return widget.padding == EdgeInsets.zero
        ? dropDown
        : Padding(
            padding: widget.padding,
            child: dropDown,
          );
  }
}
