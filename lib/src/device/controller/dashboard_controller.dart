import 'dart:async';

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
          )
        : SimpleChart(
            chartData: chart.data,
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
                                          builder: (c) => EditChartPage(
                                            chart: chart,
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
}
