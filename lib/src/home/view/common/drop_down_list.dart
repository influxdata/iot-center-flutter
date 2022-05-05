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
      this.addIfMissing,
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
/// If current value is missing in items, then it's added so it won't fail
  final bool? addIfMissing;

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

    final List<DropdownMenuItem<String>> items = widget.items
        .where((e) => e != null) //removes null items
        .toSet()
        .map((dynamic map) {
      return DropdownMenuItem<String>(
          value: map[widget.mapValue].toString(),
          child: Text(
            map[widget.label],
            style: const TextStyle(fontSize: 16),
          ));
    }).toList();

    if (widget.addIfMissing == true &&
        items.where((element) => element.value == val).isEmpty) {
      items.add(DropdownMenuItem<String>(
          value: val,
          child: Text(
            val,
            style: const TextStyle(fontSize: 16),
          )));
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
      items: items,
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
