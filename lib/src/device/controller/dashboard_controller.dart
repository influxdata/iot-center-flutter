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

  late Device selectedDevice;
  String selectedTimeOption = "-1h";

  Future<List<FluxRecord>>? fieldNames;
  var isGauge = true;
  var chartType = '';

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
  List<DropDownItem> chartTypeList = [
    DropDownItem(label: 'Gauge chart', value: ChartType.gauge.toString()),
    DropDownItem(label: 'Simple chart', value: ChartType.simple.toString()),
  ];

  @override
  void initState() {
    fieldNames = _model.fetchFieldNames(selectedDevice.id);
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
    _rowCount = selectedDevice.dashboard != null
        ? selectedDevice.dashboard!
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
    for (var chart in selectedDevice.dashboard!) {
      chart.data.refreshChart!();
    }
  }

  Widget buildChartListViewRow(index, BuildContext context) {
    var chartRow =
        selectedDevice.dashboard!.where((e) => e.row == index).toList();
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
    return _model.fetchDeviceDataFieldMedian(
        measurement, median, selectedDevice, selectedTimeOption);
  }

  double getDouble(dynamic value) =>
      value is String ? double.parse(value) : value.toDouble();

  void deleteChart(int row, int column) {
    selectedDevice.dashboard!.removeWhere(
        (element) => element.row == row && element.column == column);

    refreshCharts();
  }

  Chart getLastChart() {
    return selectedDevice.dashboard!.reduce((currentChart, nextChart) =>
        currentChart.row > nextChart.row ||
                (currentChart.row == nextChart.row &&
                    currentChart.column > nextChart.column)
            ? currentChart
            : nextChart);
  }

  void addNewChart(Chart chart) {}

  void saveChart(Chart chart, bool newChart) {
    chart.data.chartType =
        chartType == 'ChartType.gauge' ? ChartType.gauge : ChartType.simple;

    if (newChart) {
      var lastChart = getLastChart();

      if (chart.data.chartType == ChartType.gauge &&
          lastChart.data.chartType == ChartType.gauge &&
          lastChart.column == 1) {
        chart.row = lastChart.row;
        chart.column = 2;
      } else {
        chart.row = lastChart.row + 1;
        chart.column = 1;
      }

      addNewChart(chart);
    } else {
      // chart.data.refreshWidget!();
    }

    refreshCharts();
  }
}
