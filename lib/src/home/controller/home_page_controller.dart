import 'dart:async';

import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class HomePageController extends ControllerMVC {
  factory HomePageController([StateMVC? state]) =>
      _this ??= HomePageController._(state);
  HomePageController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static HomePageController? _this;
  final InfluxModel _model;

  bool expandAppBar = false;
  bool editableCharts = false;

  Device? selectedDevice;
  List<dynamic>? deviceList;
  Future<dynamic> get futureDeviceList async =>
      await _model.fetchDevices().then((value) => deviceList = value);

  String selectedTimeOption = "-1h";
  List<DropDownItem> timeOptionsList = [
    DropDownItem(label: 'Past 5m', value: '-5m'),
    DropDownItem(label: 'Past 15m', value: '-15m'),
    DropDownItem(label: 'Past 1h', value: '-1h'),
    DropDownItem(label: 'Past 6h', value: '-6h'),
    DropDownItem(label: 'Past 1d', value: '-1d'),
    DropDownItem(label: 'Past 3d', value: '-3d'),
    DropDownItem(label: 'Past 7d', value: '-7d'),
    DropDownItem(label: 'Past 30d', value: '-30d'),
  ];

  int get rowCount => selectedDevice?.dashboard != null
      ? selectedDevice!.dashboard!
              .reduce((currentChart, nextChart) =>
                  currentChart.row > nextChart.row ? currentChart : nextChart)
              .row +
          1
      : 0;

  void updateRowCount() {
    setState(() {
      rowCount;
    });
  }

  Widget buildChartListViewRow(context, index) {
    var chartRow =
        selectedDevice!.dashboard!.where((e) => e.row == index).toList();
    List<Widget> chartWidgets = [];

    if (chartRow.isNotEmpty) {
      chartRow.sort(((a, b) => a.column.compareTo(b.column)));
      for (var chart in chartRow) {
        chartWidgets.add(chart.widget);
      }
    }
    return Row(
      children: chartWidgets,
    );
  }

  Future<void> refreshChartListView() async {
    if (selectedDevice?.dashboard != null) {
    for (var chart in selectedDevice!.dashboard!) {
      await chart.data.refreshChart!();
    }}
  }

  void refreshChartEditable() {
    if (selectedDevice?.dashboard != null) {
      for (var chart in selectedDevice!.dashboard!) {
        chart.data.refreshHeader!();
      }
    }
  }

  @override
  void refresh() async {
    await futureDeviceList;
    setState(() {
      deviceList;
    });
  }

  @override
  Future<bool> initAsync() async {
    await super.initAsync();
    _model.client.loadInfluxClient();

    return true;
  }

  void onItemTapped(int index) {
    switch (index) {
      case 0:
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (c) =>
        //             NewChartPage(refreshCharts: updateRowCount)));
        break;
      case 1:
        if (editableCharts) {
          // saveDashboard();
          setState(() {
            editableCharts = false;
          });
        } else {
          setState(() {
            editableCharts = true;
          });
        }
        refreshChartEditable();
        break;
      case 2:
        refresh();
        break;
      case 3:
        break;
    }
  }

  void selectedDeviceOnChange(String? deviceId) async {
    if (deviceList!.isNotEmpty) {
      var device =
          deviceList!.firstWhere((element) => element['deviceId'] == deviceId);

      await _model
          .fetchDeviceWithDashboard(device['deviceId'])
          .then((value) => selectedDevice = value)
          .whenComplete(() => _model.fetchFieldNames(device['deviceId']));

      setState(() {
        selectedDevice;
      });
    } else {
      selectedDevice = null;
    }
    refreshChartListView();
  }
}
