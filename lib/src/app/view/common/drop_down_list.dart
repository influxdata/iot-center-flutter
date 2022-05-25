import 'package:flutter/material.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DropDownItem {
  DropDownItem({required this.label, required this.value});

  String label;
  String value;
}

class MyDropDown extends StatefulWidget {
  const MyDropDown(
      {this.padding = EdgeInsets.zero,
      this.hint = '',
      this.value,
      required this.items,
      this.onChanged,
      this.onSaved,
      this.addIfMissing,
      Key? key})
      : super(key: key);

  final EdgeInsets padding;
  final String hint;
  final String? value;
  final List<DropDownItem> items;
  final Function(String?)? onChanged;
  final Function(String?)? onSaved;

  /// If current value is missing in items, then it's added so it won't fail
  final bool? addIfMissing;

  @override
  State<StatefulWidget> createState() {
    return _MyDropDown();
  }
}

class _MyDropDown<T> extends State<MyDropDown> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var val = widget.value ?? "";
    if (widget.items.isNotEmpty && val.isEmpty) {
      val = widget.items.first.value.toString();
    }

    final List<DropdownMenuItem<String>> items =
        widget.items
        .toSet()
        .map((DropDownItem map) {
      return DropdownMenuItem<String>(
          value: map.value.toString(),
          child: Text(
            map.label,
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
    } else if (items.where((element) => element.value == val).isEmpty &&
        widget.items.isNotEmpty) {
      val = widget.items.first.value.toString();
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
