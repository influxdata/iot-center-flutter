import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class NumberTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int?>? onChanged;
  final Function(String?)? onSaved;

  const NumberTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.min = -9999,
    this.max = 9999,
    this.step = 1,
    this.onChanged,
    this.onSaved,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NumberTextFieldState();
}

class _NumberTextFieldState extends State<NumberTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _notMaxValue = false;
  bool _notMinValue = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  void didUpdateWidget(covariant NumberTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller = widget.controller ?? _controller;
    _focusNode = widget.focusNode ?? _focusNode;
    _updateArrows(int.tryParse(_controller.text));
  }

  @override
  Widget build(BuildContext context) => TextFormField(
      onSaved: widget.onSaved,
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.number,
      maxLength: widget.max.toString().length + (widget.min.isNegative ? 1 : 0),
      decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(5),
          ),
          fillColor: Colors.white,
          filled: true,
          suffixIconConstraints: const BoxConstraints(
              maxHeight: 45, maxWidth: kMinInteractiveDimension),
          suffixIcon:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
                child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                        child: Opacity(
                            opacity: _notMaxValue ? 1 : .4,
                            child: const Icon(
                              Icons.arrow_drop_up,
                              color: darkGrey,
                            )),
                        onTap: _notMaxValue ? () => _update(true) : null))),
            Expanded(
                child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                        child: Opacity(
                            opacity: _notMinValue ? 1 : .4,
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: darkGrey,
                            )),
                        onTap: _notMinValue ? () => _update(false) : null))),
          ])),
      onChanged: (value) {
        final intValue = int.tryParse(value);
        widget.onChanged?.call(intValue);
        _updateArrows(intValue);
      },
      inputFormatters: [_NumberTextInputFormatter(widget.min, widget.max)]);

  void _update(bool up) {
    var intValue = int.tryParse(_controller.text);
    intValue == null
        ? intValue = 0
        : intValue += up ? widget.step : -widget.step;
    _controller.text = intValue.toString();
    _updateArrows(intValue);
    _focusNode.requestFocus();
  }

  void _updateArrows(int? value) {
    final notMaxValue = value == null || value < widget.max;
    final notMinValue = value == null || value > widget.min;
    if (_notMaxValue != notMaxValue || _notMinValue != notMinValue) {
      setState(() {
        _notMaxValue = notMaxValue;
        _notMinValue = notMinValue;
      });
    }
  }
}

class _NumberTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (const ['-', ''].contains(newValue.text)) return newValue;
    final intValue = int.tryParse(newValue.text);
    if (intValue == null) return oldValue;
    if (intValue < min) return newValue.copyWith(text: min.toString());
    if (intValue > max) return newValue.copyWith(text: max.toString());
    return newValue.copyWith(text: intValue.toString());
  }
}
