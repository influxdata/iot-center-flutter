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
                DropDownListRow(
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
                        return DropDownListRow(
                          label: "Field:",
                          items: snapshot.data,
                          value: widget.chart.data.measurement,
                          mapValue: '_value',
                          mapLabel: '_value',
                          onChanged: (value) {},
                          onSaved: (value) {
                            widget.chart.data.measurement = value!;
                          },
                          addIfMissing: true,
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                TextBoxRow(
                  label: "Label:",
                  controller:
                      TextEditingController(text: widget.chart.data.label),
                  onSaved: (value) {
                    widget.chart.data.label = value!;
                  },
                ),
                Visibility(
                  visible: isGauge,
                  child: DoubleNumberBoxRow(
                    label: "Range:",
                    firstController: TextEditingController(
                        text: widget.chart.data.startValue.toStringAsFixed(0)),
                    firstOnSaved: (value) {
                      widget.chart.data.startValue =
                          isGauge ? double.parse(value!) : 0;
                    },
                    secondController: TextEditingController(
                        text: widget.chart.data.endValue.toStringAsFixed(0)),
                    secondOnChanged: (value) {
                      widget.chart.data.endValue =
                          isGauge ? double.parse(value!) : 0;
                    },
                  ),
                ),
                Visibility(
                  visible: isGauge,
                  child: NumberBoxRow(
                    label: "Rounded:",
                    controller: TextEditingController(
                        text: isGauge && widget.chart.data.decimalPlaces != null
                            ? widget.chart.data.decimalPlaces!
                                .toStringAsFixed(0)
                            : '0'),
                    onSaved: (value) {
                      widget.chart.data.decimalPlaces =
                          isGauge ? int.parse(value!) : 0;
                    },
                  ),
                ),
                TextBoxRow(
                  label: "Unit:",
                  controller:
                      TextEditingController(text: widget.chart.data.unit),
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
