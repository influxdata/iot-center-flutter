import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class FormRow extends StatefulWidget {
  FormRow.textBoxRow(
      {this.padding = const EdgeInsets.all(5),
      this.hint = '',
      this.value = '',
      required this.label,
      this.inputType = TextInputType.none,
      this.inputFormatters = const [],
      this.controller,
      this.validator,
      this.onChanged,
      this.onSaved,
      Key? key})
      : super(key: key) {
    _inputType = InputType.textField;
  }

  FormRow.doubleTextBoxRow(
      {this.padding = const EdgeInsets.all(5),
      this.hint = '',
      this.hint2 = '',
      this.value = '',
      this.value2 = '',
      required this.label,
      this.inputType = TextInputType.none,
      this.inputFormatters = const [],
      this.inputType2 = TextInputType.none,
      this.inputFormatters2 = const [],
      this.validator,
      this.onChanged,
      this.onSaved,
      this.onSaved2,
      Key? key})
      : super(key: key) {
    _inputType = InputType.doubleTextField;
  }

  FormRow.dropDownListRow(
      {this.padding = const EdgeInsets.all(5),
      this.hint = '',
      this.value = '',
      required this.label,
      required this.items,
      required this.mapValue,
      required this.mapLabel,
      required this.onChanged,
      this.onSaved,
      Key? key})
      : super(key: key) {
    _inputType = InputType.dropDownList;
  }

  late InputType _inputType;

  EdgeInsets padding;
  String? hint;
  String? label;
  String? value;
  TextInputType? inputType;
  List<TextInputFormatter> inputFormatters = [];
  TextEditingController? controller;

  List? items;
  String? mapValue;
  String? mapLabel;

  String? Function(String?)? validator;
  Function(String?)? onChanged;
  Function(String?)? onSaved;

  String? value2;
  String? hint2;
  TextInputType? inputType2;
  List<TextInputFormatter> inputFormatters2 = [];
  Function(String?)? onSaved2;

  @override
  State<StatefulWidget> createState() {
    return _FormRow();
  }
}

class _FormRow extends State<FormRow> {
  @override
  Widget build(BuildContext context) {
    Widget input = const Text('');

    var inputDecor = InputDecoration(
      isDense: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(5),
      ),
      fillColor: Colors.white,
      filled: true,
      hintText: widget.hint,
    );

    switch (widget._inputType) {
      case InputType.textField:
        if (widget.controller != null) {
          input = Container(
              height: 50,
              decoration: boxDecor,
              child: TextFormField(
                keyboardType: widget.inputType,
                inputFormatters: widget.inputFormatters,
                decoration: inputDecor,
                controller: widget.controller,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onSaved: widget.onSaved,
              ));
        } else {
          input = Container(
              height: 50,
              decoration: boxDecor,
              child: TextFormField(
                initialValue: widget.value,
                keyboardType: widget.inputType,
                inputFormatters: widget.inputFormatters,
                decoration: inputDecor,
                validator: widget.validator,
                onChanged: widget.onChanged,
                onSaved: widget.onSaved,
              ));
        }

        break;
      case InputType.doubleTextField:
        input = Row(
          children: [
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    height: 50,
                    decoration: boxDecor,
                    child: TextFormField(
                      initialValue: widget.value,
                      keyboardType: widget.inputType,
                      inputFormatters: widget.inputFormatters,
                      decoration: inputDecor,
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      onSaved: widget.onSaved,
                    ),
                  )),
            ),
            Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    height: 50,
                    decoration: boxDecor,
                    child: TextFormField(
                      initialValue: widget.value2,
                      keyboardType: widget.inputType2,
                      inputFormatters: widget.inputFormatters2,
                      decoration: inputDecor,
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      onSaved: widget.onSaved2,
                    ),
                  )),
            )
          ],
        );
        break;
      case InputType.dropDownList:
        input = Container(
            height: 50,
            decoration: boxDecor,
            child: MyDropDown(
              value: widget.value!,
              items: widget.items!,
              mapValue: widget.mapValue!,
              label: widget.mapLabel!,
              onChanged: widget.onChanged,
              onSaved: widget.onSaved,
            ));
        break;
    }

    return widget.label!.isNotEmpty
        ? Padding(
            padding: widget.padding,
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Text(
                      widget.label!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    )),
                Expanded(
                  flex: 3,
                  child: input,
                ),
              ],
            ),
          )
        : Padding(
            padding: widget.padding,
            child: Row(
              children: [
                Expanded(
                  child: input,
                ),
              ],
            ),
          );
  }
}
