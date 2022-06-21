import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class DashboardController extends ControllerMVC {
  factory DashboardController([StateMVC? state]) =>
      _this ??= DashboardController._(state);
  DashboardController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static DashboardController? _this;
  final InfluxModel _model;

  Device? selectedDevice;
  String selectedTimeOption = "-1h";

  Future<List<FluxRecord>>? fieldNames;
  var isGauge = true;

  List<DropDownItem> timeOptionList = [
    DropDownItem(label: 'Past 5m', value: '-5m'),
    DropDownItem(label: 'Past 15m', value: '-15m'),
    DropDownItem(label: 'Past 1h', value: '-1h'),
    DropDownItem(label: 'Past 6h', value: '-6h'),
    DropDownItem(label: 'Past 1d', value: '-1d'),
    DropDownItem(label: 'Past 3d', value: '-3d'),
    DropDownItem(label: 'Past 7d', value: '-7d'),
    DropDownItem(label: 'Past 30d', value: '-30d'),
  ];

  @override
  void initState() {
    fieldNames = _model.fetchFieldNames(selectedDevice!.id);
    super.initState();
  }

  bool _editable = false;
  bool get editable => _editable;
  set editable(bool value) {
    _editable = value;
    setState(() {
      editable;
    });
  }

  int _rowCount = 0;
  int get rowCount => _rowCount;
  void setRowCount() {
    _rowCount = selectedDevice!.dashboard != null &&
            selectedDevice!.dashboard!.isNotEmpty
        ? selectedDevice!.dashboard!
                .reduce((currentChart, nextChart) =>
                    currentChart.row > nextChart.row ? currentChart : nextChart)
                .row +
            1
        : 0;
    setState(() {
      rowCount;
    });
  }

  void refreshCharts() {
    for (var chart in selectedDevice!.dashboard!) {
      if (chart.data.reloadData != null) {
        chart.data.reloadData!();
        setState(() {
          chart.data;
        });
      }
    }
  }

  Widget buildChartListViewRow(index, BuildContext context) {
    var chartRow =
        selectedDevice!.dashboard!.where((e) => e.row == index).toList();
    List<Widget> chartWidgets = [];

    if (chartRow.isNotEmpty) {
      chartRow.sort(((a, b) => a.column.compareTo(b.column)));
      for (var chart in chartRow) {
        chartWidgets.add(getChartWidget(chart, context));
      }
    }
    return Row(
      children: chartWidgets,
    );
  }

  Widget getChartWidget(Chart chart, BuildContext context) {
    Widget chartWidget = chart.data.chartType == ChartType.gauge
        ? GaugeChart(
            chartData: chart.data,
            con: this,
          )
        : SimpleChart(
            chartData: chart.data,
            con: this,
          );

    return Expanded(
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                decoration: boxDecor,
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Padding(
                          padding: editable
                              ? const EdgeInsets.only(bottom: 0)
                              : const EdgeInsets.only(bottom: 15, top: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chart.data.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: editable,
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (c) => ChartDetailPage(
                                            chart: chart,
                                            newChart: false,
                                          ),
                                        ));
                                  },
                                  icon: const Icon(Icons.settings),
                                  iconSize: 17,
                                  color: darkBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        chartWidget,
                      ],
                    )))));
  }

  Future<List<FluxRecord>> getDataFromInflux(
      String measurement, bool median) async {
    return _model.fetchDeviceDataField(
        measurement, median, selectedDevice!, selectedTimeOption);
  }

  double getDouble(dynamic value) =>
      value is String ? double.parse(value) : value.toDouble();

  void deleteChart(int row, int column) {
    selectedDevice!.dashboard!.removeWhere(
        (element) => element.row == row && element.column == column);

    refreshCharts();
    setRowCount();
  }

  Chart? getLastChart() {
    return selectedDevice!.dashboard != null &&
            selectedDevice!.dashboard!.isNotEmpty
        ? selectedDevice!.dashboard!.reduce((currentChart, nextChart) =>
            currentChart.row > nextChart.row ||
                    (currentChart.row == nextChart.row &&
                        currentChart.column > nextChart.column)
                ? currentChart
                : nextChart)
        : null;
  }

  void saveChart(Chart chart, bool newChart) {
    if (newChart) {
      var lastChart = getLastChart();

      if (lastChart != null &&
          chart.data.chartType == ChartType.gauge &&
          lastChart.data.chartType == ChartType.gauge &&
          lastChart.column == 1) {
        chart.row = lastChart.row;
        chart.column = 2;
      } else if (lastChart != null) {
        chart.row = lastChart.row + 1;
        chart.column = 1;
      } else {
        chart.row = 1;
        chart.column = 1;
      }

      selectedDevice!.dashboard!.add(chart);
    } else {
      chart.data.reloadData!();
      setState(() {
        chart.data;
      });
    }

    setRowCount();
  }

  Widget changeTimeRange(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("Change time range"),
      content: Form(
        key: _formKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
            child: DropDownListRow(
              items: timeOptionList,
              value: selectedTimeOption,
              onChanged: (value) {},
              onSaved: (value) {
                setState(() {
                  selectedTimeOption = value!;
                });
                refreshCharts();
                Navigator.of(context).pop();
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save", style: TextStyle(color: pink)),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
              }
            })),
      ],
    );
  }

  Widget changeDashboard(BuildContext context, String? dashboardKey) {
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("Change dashboard"),
      content: Form(
        key: _formKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FutureBuilder<dynamic>(
              future: _model.fetchDashboardsByType(selectedDevice!.type),
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.done) {
                  final data = snapshot.data;
                  late List<DropDownItem> dashboardList = List.empty();
                  if (data is List) {
                    dashboardList = data
                        .map((d) =>
                            DropDownItem(label: d['key'], value: d['key']))
                        .toList();
                  }
                  var selectedDashboard =
                      dashboardKey == null || dashboardKey.isEmpty
                          ? selectedDevice!.dashboardKey
                          : dashboardKey;

                  return Expanded(
                    child: DropDownListRow(
                      items: dashboardList,
                      value: selectedDashboard,
                      onChanged: (value) {
                        selectedDevice!.dashboardKey = value.toString();
                      },
                      onSaved: (value) {
                        selectedDevice!.dashboardKey = value.toString();
                      },
                    ),
                  );
                } else {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: pink,
                      strokeWidth: 3,
                    ),
                  );
                }
              }),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text("New"),
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return newDashboard(context);
              },
            );
          },
        ),
        TextButton(
            child: const Text("Save", style: TextStyle(color: pink)),
            onPressed: (() async {
              _formKey.currentState!.save();
              _model.pairDeviceDashboard(
                  selectedDevice!.id, selectedDevice!.dashboardKey);

              selectedDevice!.dashboard = await _model.fetchDashboard(
                  selectedDevice!.dashboardKey, selectedDevice!.type);

              Navigator.of(context).pop();

              setRowCount();
              refreshCharts();
            })),
      ],
    );
  }

  Widget newDashboard(BuildContext context) {
    late TextEditingController newDashboardController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("New dashboard"),
      content: Form(
        key: _formKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: TextBoxRow(
            hint: 'Dashboard key',
            label: '',
            controller: newDashboardController,
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Dashboard ID cannot be empty';
              }
              return null;
            },
          )),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Create", style: TextStyle(color: pink)),
            onPressed: (() async {
              await _model.createDashboard(
                  newDashboardController.text, selectedDevice!.type, null);

              Navigator.of(context).pop();

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return changeDashboard(context, newDashboardController.text);
                },
              );
            })),
      ],
    );
  }

  Future<bool> saveDashboard() async{
    var pairDeviceDashboard = selectedDevice!.dashboardKey.isEmpty;
    var dashboardKey = await _model.createDashboard(selectedDevice!.dashboardKey, selectedDevice!.type,
        selectedDevice!.dashboard);

    if (pairDeviceDashboard) {
      selectedDevice!.dashboardKey = dashboardKey;
      _model.pairDeviceDashboard(
          selectedDevice!.id, selectedDevice!.dashboardKey);
    }

    return pairDeviceDashboard;
  }
}
