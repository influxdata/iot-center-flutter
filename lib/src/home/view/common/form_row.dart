import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class TextBoxRow extends FormRow {
  TextBoxRow(
      {Key? key,
      padding = const EdgeInsets.all(5),
      label,
      this.hint = '',
      this.inputFormatters = const [],
      this.controller,
      this.validator,
      this.onChanged,
      this.onSaved})
      : super(
          key: key,
          label: label,
          inputWidget: Container(
              decoration: boxDecor,
              child: TextFormField(
                inputFormatters: inputFormatters,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: hint,
                ),
                controller: controller ?? TextEditingController(),
                validator: validator,
                onChanged: onChanged,
                onSaved: onSaved,
              )),
        );

  final String? hint;
  final TextEditingController? controller;
  final List<TextInputFormatter> inputFormatters;
  final Function(String?)? onChanged;
  final Function(String?)? onSaved;
  final String? Function(String?)? validator;
}

class NumberBoxRow extends FormRow {
  NumberBoxRow(
      {Key? key,
      padding = const EdgeInsets.all(5),
      label,
      this.hint = '',
      this.min = -99999,
      this.max = 99999,
      this.controller,
      this.onChanged,
      this.onSaved})
      : super(
          key: key,
          label: label,
          inputWidget: Container(
            decoration: boxDecor,
            child: NumberTextField(
              onSaved: onSaved,
              min: min,
              max: max,
              controller: controller ?? TextEditingController(),
            ),
          ),
        );

  final String? hint;
  final TextEditingController? controller;
  final int min;
  final int max;

  final Function(String?)? onChanged;
  final Function(String?)? onSaved;
}

class DropDownListRow extends FormRow {
  DropDownListRow(
      {Key? key,
      padding = const EdgeInsets.all(5),
      label,
      this.hint = '',
      this.mapLabel = '',
      required this.mapValue,
      required this.items,
      this.controller,
      this.onChanged,
      this.onSaved,
      bool? addIfMissing})
      : super(
          key: key,
          label: label,
          inputWidget: Container(
              decoration: boxDecor,
              child: MyDropDown(
                controller: controller ?? TextEditingController(),
                items: items!,
                mapValue: mapValue!,
                label: mapLabel!,
                onChanged: onChanged,
                onSaved: onSaved,
                addIfMissing: addIfMissing,
              )),
        );

  final String? hint;
  final List? items;
  final String? mapValue;
  final String? mapLabel;
  final TextEditingController? controller;
  final Function(String?)? onChanged;
  final Function(String?)? onSaved;
}

class DoubleNumberBoxRow extends FormRow {
  DoubleNumberBoxRow({
    Key? key,
    padding = const EdgeInsets.all(5),
    label,
    this.firstHint = '',
    this.firstController,
    this.firstMin = -99999,
    this.firstMax = 99999,
    this.firstOnChanged,
    this.firstOnSaved,
    this.secondHint = '',
    this.secondController,
    this.secondMin = -99999,
    this.secondMax = 99999,
    this.secondOnChanged,
    this.secondOnSaved,
  }) : super(
          key: key,
          label: label,
          inputWidget: Row(
            children: [
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      decoration: boxDecor,
                      child: NumberTextField(
                        onSaved: firstOnSaved,
                        controller: firstController ?? TextEditingController(),
                        min: firstMin,
                        max: firstMax,
                      ),
                    )),
              ),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      decoration: boxDecor,
                      child: NumberTextField(
                        onSaved: secondOnSaved,
                        controller: secondController ?? TextEditingController(),
                        min: secondMin,
                        max: secondMax,
                      ),
                    )),
              )
            ],
          ),
        );

  final String? firstHint;
  final TextEditingController? firstController;
  final int firstMin;
  final int firstMax;
  final Function(String?)? firstOnChanged;
  final Function(String?)? firstOnSaved;

  final String? secondHint;
  final TextEditingController? secondController;
  final int secondMin;
  final int secondMax;
  final Function(String?)? secondOnChanged;
  final Function(String?)? secondOnSaved;
}

class FormRow extends StatefulWidget {
  const FormRow(
      {this.padding = const EdgeInsets.all(5),
      required this.label,
      required this.inputWidget,
      Key? key})
      : super(key: key);

  final EdgeInsets padding;
  final String? label;
  final Widget inputWidget;

  @override
  State<StatefulWidget> createState() {
    return _FormRowState();
  }
}

class _FormRowState extends State<FormRow> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.label!.isNotEmpty
        ? Padding(
            padding: widget.padding,
            child: Row(
              children: [
                SizedBox(
                    width: 110,
                    child: Text(
                      widget.label!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    )),
                Expanded(
                  child: SizedBox(child: widget.inputWidget),
                ),
              ],
            ),
          )
        : Padding(
            padding: widget.padding,
            child: Row(
              children: [
                Expanded(
                  child: widget.inputWidget,
                ),
              ],
            ),
          );
  }
}
