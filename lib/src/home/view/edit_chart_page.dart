import 'package:flutter/services.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class EditChartPage extends StatefulWidget {
  const EditChartPage({Key? key, required this.chart}) : super(key: key);

  final Chart chart;

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
  var isGauge = true;
  var chartType = '';

  showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Delete"),
      onPressed: () {
        con.chartsList.removeWhere((element) =>
            element.row == widget.chart.row &&
            element.column == widget.chart.column);
        con.removeItemFromListView!();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Delete chart"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: darkBlue,
            title: const Text("Edit chart"),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.white,
                onPressed: () {
                  showAlertDialog(context);
                },
              ),
            ]),
        backgroundColor: lightGrey,
        body: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                FormRow.dropDownListRow(
                  label: "Type:",
                  items: con.chartTypeList,
                  value: widget.chart.data.chartType.toString(),
                  mapValue: 'value',
                  mapLabel: 'label',
                  onChanged: (value) {
                    setState(() {
                      isGauge = value == 'ChartType.gauge';
                    });
                  },
                  onSaved: (value) {
                    chartType = value!;
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
                          value: widget.chart.data.measurement,
                          mapValue: '_value',
                          mapLabel: '_value',
                          onChanged: (value) {},
                          onSaved: (value) {
                            widget.chart.data.measurement = value!;
                          },
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                FormRow.textBoxRow(
                  label: "Label:",
                  value: widget.chart.data.label,
                  onSaved: (value) {
                    widget.chart.data.label = value!;
                  },
                ),
                Visibility(
                  visible: isGauge,
                  child: FormRow.doubleTextBoxRow(
                    label: "Range:",
                    value: widget.chart.data.startValue.toStringAsFixed(0),
                    inputType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onSaved: (value) {
                      widget.chart.data.startValue =
                          isGauge ? double.parse(value!) : 0;
                    },
                    value2: widget.chart.data.endValue.toStringAsFixed(0),
                    inputType2: TextInputType.number,
                    inputFormatters2: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onSaved2: (value) {
                      widget.chart.data.endValue =
                          isGauge ? double.parse(value!) : 0;
                    },
                  ),
                ),
                Visibility(
                  visible: isGauge,
                  child: FormRow.textBoxRow(
                    label: "Rounded:",
                    value: isGauge && widget.chart.data.decimalPlaces != null
                        ? widget.chart.data.decimalPlaces!.toStringAsFixed(0)
                        : '0',
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
                      widget.chart.data.decimalPlaces =
                          isGauge ? int.parse(value!) : 0;
                    },
                  ),
                ),
                FormRow.textBoxRow(
                  label: "Unit:",
                  value: widget.chart.data.unit,
                  onSaved: (value) {
                    widget.chart.data.unit = value!;
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

                          widget.chart.data.chartType =
                              chartType == 'ChartType.gauge'
                                  ? ChartType.gauge
                                  : ChartType.simple;

                          widget.chart.data.refreshWidget!();

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
  }

  @override
  void initState() {
    super.initState();
    isGauge = widget.chart.data.chartType == ChartType.gauge;
  }
}
