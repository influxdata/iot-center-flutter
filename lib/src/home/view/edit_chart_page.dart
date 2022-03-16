import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditChartPage extends StatefulWidget {
  const EditChartPage({Key? key, required this.chart}) : super(key: key);

  final Widget chart;

  @override
  _EditChartPageState createState() {
    return _EditChartPageState();
  }
}

class _EditChartPageState extends State<EditChartPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (widget.chart is GaugeChart) {
      var gaugeChart = widget.chart as GaugeChart;
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: const Text("Edit chart"),
          ),
          body: Padding(
            padding:
                const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  getTextBoxRow(
                    "Label:",
                    gaugeChart.label,
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  getTextBoxRow(
                    "Field:",
                    gaugeChart.measurement,
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  getRangeTextBoxRow(
                      "Range:",
                      gaugeChart.startValue.toStringAsFixed(0),
                      gaugeChart.endValue.toStringAsFixed(0)),
                  getTextBoxRow(
                    "Rounded:",
                    gaugeChart.decimalPlaces.toString(),
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  getTextBoxRow(
                    "Unit:",
                    gaugeChart.unit,
                    (value) {
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 25, horizontal: 5),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(20)),
                        backgroundColor:
                            MaterialStateProperty.all(Colors.deepPurple),
                        textStyle: MaterialStateProperty.all(const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          // widget.chart.refresh();

                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ),
          ));
    }
    else if (widget.chart is SimpleChart) {
      var simpleChart = widget.chart as SimpleChart;
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurple,
            title: const Text("Edit chart"),
          ),
          body: Padding(
            padding:
            const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  getTextBoxRow(
                    "Label:",
                    simpleChart.label,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  getTextBoxRow(
                    "Field:",
                    simpleChart.measurement,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  getTextBoxRow(
                    "Unit:",
                    "",
                        (value) {
                      return null;
                    },
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 5),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        padding:
                        MaterialStateProperty.all(const EdgeInsets.all(20)),
                        backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurple),
                        textStyle: MaterialStateProperty.all(const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
                        }
                      },
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ),
          ));
    }
    else{
      return const Scaffold();
    }
  }

  Padding getTextBoxRow(
      String label, String? hintText, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [getLabel(label), getTextBox(hintText, validator)],
      ),
    );
  }

  Padding getRangeTextBoxRow(String label, String startValue, endValue) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          getLabel(label),
          Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextFormField(
                        initialValue: startValue,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onSaved: (value) {
                          // setState(() =>
                          //     widget.chart.startValue = double.parse(value!));
                        },
                        // validator: validator,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: TextFormField(
                        initialValue: endValue,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        // validator: validator,
                      ),
                    ),
                  )
                ],
              ))
        ],
      ),
    );
  }

  Padding getDropDownRow(
      String label,
      String hintText,
      String value,
      List items,
      String mapValue,
      String? labelDropDown,
      void Function(String?)? onChange) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          getLabel(label),
          Expanded(
              flex: 3,
              child: MyDropDown(EdgeInsets.zero, hintText, value, items,
                  mapValue, label, onChange))
        ],
      ),
    );
  }

  Expanded getLabel(String label) {
    return Expanded(
        flex: 1,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ));
  }

  Expanded getTextBox(String? hintText, String? Function(String?)? validator) {
    return Expanded(
      flex: 3,
      child: TextFormField(
        initialValue: hintText,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
        ),
        validator: validator,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      var val = prefs.getString("iot_center_url");
      _controller.text = val ?? "";
    });
  }
}
