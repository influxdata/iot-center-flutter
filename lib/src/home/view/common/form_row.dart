import 'package:iot_center_flutter_mvc/src/view.dart';

class FormRow extends StatefulWidget {
  FormRow.textBoxRow(
      {this.padding = const EdgeInsets.all(5),
      this.hint = '',
      this.value = '',
      required this.label,
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
      this.validator,
      this.onChanged,
      this.onSaved,
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

  String? value2;
  String? hint2;

  List? items;
  String? mapValue;
  String? mapLabel;

  String? Function(String?)? validator;
  Function(String?)? onChanged;
  Function(String?)? onSaved;

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
        input = Container(
            height: 50,
            decoration: boxDecor,
            child: TextFormField(
              initialValue: widget.value,
              decoration: inputDecor,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onSaved: widget.onSaved,
            ));
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
                      decoration: inputDecor,
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      onSaved: widget.onSaved,
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

    return Padding(
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
    );
  }
}
