import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class EditChartPage extends StatefulWidget {
  const EditChartPage(
      {Key? key, required this.chart, required this.chartRefresh})
      : super(key: key);

  final StatefulWidget chart;
  final void Function() chartRefresh;

  @override
  _EditChartPageState createState() {
    return _EditChartPageState();
  }
}

class _EditChartPageState extends StateMVC<EditChartPage> {
  final _formKey = GlobalKey<FormState>();

  _EditChartPageState() : super(Controller()) {
    con = controller as Controller;
    con.loadFieldNames();
  }

  late Controller con;

  @override
  Widget build(BuildContext context) {
    if (widget.chart is GaugeChart) {
      var gaugeChart = widget.chart as GaugeChart;

      return Scaffold(
          appBar: AppBar(
            backgroundColor: darkBlue,
            title: const Text("Edit chart"),
          ),
          backgroundColor: lightGrey,
          body: Padding(
            padding:
                const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  FormRow.textBoxRow(
                    label: "Label:",
                    value: gaugeChart.chartData.label,
                    onSaved: (value) {
                      gaugeChart.chartData.label = value!;
                    },
                  ),
                  FutureBuilder<dynamic>(
                      future: con.loadFieldNames(),
                      builder: (context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return FormRow.dropDownListRow(
                            label: "Field:",
                            items: snapshot.data,
                            value: gaugeChart.chartData.measurement,
                            mapValue: '_value',
                            mapLabel: '_value',
                            onChanged: (value) {},
                            onSaved: (value) {
                              gaugeChart.chartData.measurement = value!;
                            },
                          );
                        } else {
                          return const Text("loading...");
                        }
                      }),
                  FormRow.doubleTextBoxRow(
                    label: "Range:",
                    value: gaugeChart.chartData.startValue.toStringAsFixed(0),
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onSaved: (value) {
                      gaugeChart.chartData.startValue = double.parse(value!);
                    },
                    value2: gaugeChart.chartData.endValue.toStringAsFixed(0),
                    inputType2: TextInputType.number,
                    inputFormatters2: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onSaved2: (value) {
                      gaugeChart.chartData.endValue = double.parse(value!);
                    },
                  ),
                  FormRow.textBoxRow(
                    label: "Rounded:",
                    value:
                        gaugeChart.chartData.decimalPlaces!.toStringAsFixed(0),
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      gaugeChart.chartData.decimalPlaces = int.parse(value!);
                    },
                  ),
                  FormRow.textBoxRow(
                    label: "Unit:",
                    value: gaugeChart.chartData.unit,
                    onSaved: (value) {
                      gaugeChart.chartData.unit = value!;
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                    child: FormButton(
                        label: 'Update',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            widget.chartRefresh();
                            Navigator.pop(context);
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(content: Text('Processing Data')),
                            // );
                          }
                        }),
                  ),
                ],
              ),
            ),
          ));
    } else if (widget.chart is SimpleChart) {
      var simpleChart = widget.chart as SimpleChart;
      return Scaffold(
          appBar: AppBar(
            backgroundColor: darkBlue,
            title: const Text("Edit chart"),
          ),
          backgroundColor: lightGrey,
          body: Padding(
            padding:
                const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // FormRow.dropDownListRow(
                  //   label: "Type:",
                  //   items: con.getChartTypeList(),
                  //   mapValue: 'value',
                  //   mapLabel: 'label',
                  //   onChanged: (value) {},
                  // ),
                  FormRow.textBoxRow(
                    label: "Label:",
                    value: simpleChart.label,
                  ),
                  FutureBuilder<dynamic>(
                      future: con.loadFieldNames(),
                      builder: (context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return FormRow.dropDownListRow(
                            label: "Field:",
                            items: snapshot.data,
                            value: simpleChart.measurement,
                            mapValue: '_value',
                            mapLabel: '_value',
                            onChanged: (value) {},
                          );
                        } else {
                          return const Text("loading...");
                        }
                      }),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                    child: FormButton(
                        label: 'Update',
                        onPressed: () {
                          // Validate returns true if the form is valid, or false otherwise.
                          if (_formKey.currentState!.validate()) {
                            // If the form is valid, display a snackbar. In the real world,
                            // you'd often call a server or save the information in a database.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Processing Data')),
                            );
                          }
                        }),
                  ),
                ],
              ),
            ),
          ));
    } else {
      return const Scaffold();
    }
  }

  @override
  void initState() {
    super.initState();
  }
}
