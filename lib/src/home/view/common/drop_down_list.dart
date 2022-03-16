import 'package:flutter/material.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class MyDropDown extends StatefulWidget {
  MyDropDown(EdgeInsets _padding, String _hint, String _value, List _items,
      String _mapValue, String _label, Function(String?)? _onChange,
      {Key? key})
      : super(key: key) {
    padding = _padding;
    hint = _hint;
    value = _value;
    items = _items;
    mapValue = _mapValue;
    label = _label;
    onChange = _onChange;
  }
  EdgeInsets padding = EdgeInsets.zero;
  String hint = '';
  String value = '';
  List items = [];
  String mapValue = '';
  String label = '';
  Function(String?)? onChange;

  @override
  State<StatefulWidget> createState() {
    return _MyDropDown();
  }
}

class _MyDropDown extends State<MyDropDown> {
  @override
  Widget build(BuildContext context) {
    var val = widget.value;
    if (widget.items.isNotEmpty && val.isEmpty) {
      val = widget.items.first[widget.mapValue].toString();
    }

    var dropDown = DropdownButtonFormField<String>(
        isDense: true,
        hint: Text(widget.hint),
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
        ),
        value: val,
        items: widget.items.map((dynamic map) {
          return DropdownMenuItem<String>(
              value: map[widget.mapValue].toString(),
              child: Text(
                map[widget.label],
                style: const TextStyle(fontSize: 16),
              ));
        }).toList(),
        onChanged: widget.onChange);

    return widget.padding == EdgeInsets.zero
        ? dropDown
        : Padding(
            padding: widget.padding,
            child: dropDown,
          );
  }
}
