import 'package:flutter/material.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class MyDropDown extends StatefulWidget {
  MyDropDown(
      {this.padding = EdgeInsets.zero,
      this.hint = '',
      this.value = '',
      required this.items,
      required this.mapValue,
      required this.label,
      this.onChanged,
      this.onSaved,
      Key? key})
      : super(key: key);

  EdgeInsets padding;
  String hint;
  String value;
  List items;
  String mapValue;
  String label;
  Function(String?)? onChanged;
  Function(String?)? onSaved;

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
      isExpanded: true,
      hint: Text(widget.hint),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(5),
          gapPadding: 0,
        ),
        focusedBorder:  OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(5),
          gapPadding: 0,
        ),
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
