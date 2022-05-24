import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class NewChartPage extends StatefulWidget {
  const NewChartPage({required this.refreshCharts, Key? key}) : super(key: key);

  final Function() refreshCharts;

  @override
  _NewChartPageState createState() {
    return _NewChartPageState();
  }
}

class _NewChartPageState extends StateMVC<NewChartPage> {
  final _formKey = GlobalKey<FormState>();

  _NewChartPageState() : super(Controller()) {
    con = controller as Controller;
    con.loadFieldNames();
  }

  late Controller con;

  String measurement = '';
  String label = '';
  String unit = '';
  double startValue = 0;
  double endValue = 100;
  double size = 120;
  int? decimalPlaces;
  String? chartType;

  bool isGauge = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightGrey,
        appBar: AppBar(
          backgroundColor: darkBlue,
          title: const Text("New chart"),
        ),
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
                  value: con.chartTypeList.first.value.toString(),
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
                        final List<FluxRecord> data = snapshot.data;
                        final items = data
                            .map((x) => DropDownItem(
                                label: x["_value"], value: x["_value"]))
                            .toList();

                        return DropDownListRow(
                          label: "Field:",
                          items: items,
                          value: snapshot.data.first['_value'].toString(),
                            onChanged: (value) {},
                            onSaved: (value) {
                              measurement = value!;
                          },
                          addIfMissing: true,
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                TextBoxRow(
                  label: "Label:",
                  onSaved: (value) {
                    label = value!;
                  },
                ),
                Visibility(
                  visible: isGauge,
                  child: DoubleNumberBoxRow(
                      label: "Range:",
                      firstController: TextEditingController(text: '0'),
                      firstOnSaved: (value) {
                        startValue = double.parse(value!);
                      },
                      secondController: TextEditingController(text: '100'),
                      secondOnChanged: (value) {
                        endValue = double.parse(value!);
                      }),
                ),
                Visibility(
                  visible: isGauge,
                  child: NumberBoxRow(
                      label: "Rounded:",
                      controller: TextEditingController(text: '0'),
                      onSaved: (value) {
                        decimalPlaces = int.parse(value!);
                      }),
                ),
                TextBoxRow(
                    label: "Unit:",
                    onSaved: (value) {
                      unit = value!;
                    }),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                  child: FormButton(
                      label: 'Create',
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          var lastChart = con.dashboard.reduce(
                              (currentChart, nextChart) =>
                                  currentChart.row > nextChart.row ||
                                          (currentChart.row == nextChart.row &&
                                              currentChart.column >
                                                  nextChart.column)
                                      ? currentChart
                                      : nextChart);

                          int row, column = 0;

                          if (chartType == 'ChartType.gauge' &&
                              lastChart.data.chartType == ChartType.gauge &&
                              lastChart.column == 1) {
                            row = lastChart.row;
                            column = 2;
                          } else {
                            row = lastChart.row + 1;
                            column = 1;
                          }

                          if (chartType == 'ChartType.gauge') {
                            con.addNewChart(Chart(
                                row: row,
                                column: column,
                                data: ChartData.gauge(
                                  measurement: measurement,
                                  endValue: endValue,
                                  label: label,
                                  unit: unit,
                                  startValue: startValue,
                                  decimalPlaces: decimalPlaces,
                                )));
                          } else {
                            con.addNewChart(Chart(
                                row: row,
                                column: column,
                                data: ChartData.simple(
                                  measurement: measurement,
                                  label: label,
                                  unit: unit,
                                )));
                          }
                          widget.refreshCharts();
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
  }
}
