import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class ChartDetailPage extends StatefulWidget {
  const ChartDetailPage({Key? key, required this.chart, required this.newChart})
      : super(key: key);

  final Chart chart;
  final bool newChart;

  @override
  _ChartDetailPageState createState() {
    return _ChartDetailPageState();
  }
}

class _ChartDetailPageState extends StateMVC<ChartDetailPage> {
  final _formKey = GlobalKey<FormState>();

  _ChartDetailPageState() : super() {
    con =  DashboardController();
  }

  late DashboardController con;

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
        con.deleteChart(widget.chart.row, widget.chart.column);
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
            title: widget.newChart
                ? const Text("New chart")
                : const Text("Edit chart"),
            actions: [
              Visibility(
                visible: !widget.newChart,
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.white,
                  onPressed: () {
                    showAlertDialog(context);
                  },
                ),
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
                  onChanged: (value) {
                    setState(() {
                      con.isGauge = value == 'ChartType.gauge';
                    });
                  },
                  onSaved: (value) {
                    con.chartType = value!;
                  },
                ),
                FutureBuilder<List<FluxRecord>>(
                    future: con.fieldNames,
                    builder:
                        (context, AsyncSnapshot<List<FluxRecord>> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        final List<FluxRecord> data = snapshot.data!;
                        final items = data
                            .map((x) => DropDownItem(
                                label: x["_value"], value: x["_value"]))
                            .toList();

                        return DropDownListRow(
                          label: "Field:",
                          items: items,
                          value: widget.chart.data.measurement,
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
                  visible: con.isGauge,
                  child: DoubleNumberBoxRow(
                    label: "Range:",
                    firstController: TextEditingController(
                        text: widget.chart.data.startValue.toStringAsFixed(0)),
                    firstOnSaved: (value) {
                      widget.chart.data.startValue =
                          con.isGauge ? double.parse(value!) : 0;
                    },
                    secondController: TextEditingController(
                        text: widget.chart.data.endValue.toStringAsFixed(0)),
                    secondOnChanged: (value) {
                      widget.chart.data.endValue =
                          con.isGauge ? double.parse(value!) : 0;
                    },
                  ),
                ),
                Visibility(
                  visible: con.isGauge,
                  child: NumberBoxRow(
                    label: "Rounded:",
                    controller: TextEditingController(
                        text: con.isGauge &&
                                widget.chart.data.decimalPlaces != null
                            ? widget.chart.data.decimalPlaces!
                                .toStringAsFixed(0)
                            : '0'),
                    onSaved: (value) {
                      widget.chart.data.decimalPlaces =
                          con.isGauge ? int.parse(value!) : 0;
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
                      label: widget.newChart ? 'Create' : 'Update',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();


                          con.saveChart(widget.chart, widget.newChart);

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
    con.isGauge = widget.chart.data.chartType == ChartType.gauge;
  }
}
