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
                FormRow.dropDownListRow(
                  label: "Type:",
                  items: con.chartTypeList,
                  value: con.chartTypeList.first['value'].toString(),
                  mapValue: 'value',
                  mapLabel: 'label',
                  onChanged: (value) {},
                  onSaved: (value) {
                    chartType = value!;
                  },
                ),
                FormRow.textBoxRow(
                  label: "Label:",
                  onSaved: (value) {
                    label = value!;
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
                            value: snapshot.data.first['_value'].toString(),
                            mapValue: '_value',
                            mapLabel: '_value',
                            onChanged: (value) {},
                            onSaved: (value) {
                              measurement = value!;
                            });
                      } else {
                        return const Text("loading...");
                      }
                    }),
                FormRow.doubleTextBoxRow(
                    label: "Range:",
                    onSaved: (value) {
                      startValue = double.parse(value!);
                    },
                    onSaved2: (value) {
                      endValue = double.parse(value!);
                    }),
                FormRow.textBoxRow(
                    label: "Rounded:",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      decimalPlaces = int.parse(value!);
                    }),
                FormRow.textBoxRow(
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

                          var lastChart = con.chartsList.reduce(
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
