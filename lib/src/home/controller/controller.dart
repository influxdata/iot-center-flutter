import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class Controller extends ControllerMVC {
  factory Controller([StateMVC? state]) => _this ??= Controller._(state);
  Controller._(StateMVC? state)
      : _model = Model(),
        super(state);
  static Controller? _this;
  final Model _model;

  Function()? removeItemFromListView;

  @override
  Future<bool> initAsync() async {
    await super.initAsync();
    await _model.initAsync();
    return true;
  }

  bool editable = false;

  void refreshChartEditable() {
    for (var chart in _model.dashboard) {
      chart.data.refreshHeader!();
    }
  }

  Future<void> loadSavedData() async {
    await loadDashboard(defaultDashboardKey);
  }

  Future<void> loadDashboard(String dashboardKey) async {
    await _model.loadDashboard(dashboardKey);
  }

  Future<void> saveDashboard() async {
    await _model.storeDashboard(defaultDashboardKey, dashboard);
  }

  void addNewChart(Chart chart) {
    _model.dashboard.add(chart);
  }

  Dashboard get dashboard => _model.dashboard;

  List get deviceList => _model.deviceList;
  List<DropDownItem> get timeOptionsList => _model.timeOptionList;
  List<DropDownItem> get chartTypeList => _model.chartTypeList;
  List get fieldNames => _model.fieldList;

  Map<String, dynamic>? get selectedDevice => _model.selectedDevice;

  String get selectedTimeOption => _model.selectedTimeOption;
  set selectedTimeOption(String value) => _model.selectedTimeOption = value;

  Map<String, dynamic>? setSelectedDevice(String? value, bool setNull) =>
      _model.selectedDeviceOnChange(value, setNull);

  Future<void> loadDevices() => _model.loadDevices();

  // TODO: should return typed data already instead of List of dynamics
  Future<void> loadFieldNames() => _model.loadFieldNames();


  Future removeDeviceConfig(Map<String, dynamic>? device) async {
    await _model.removeDeviceConfig(device);
  }


  Future<void> refreshChartListView() async {
    for (var chart in dashboard) {
      await chart.data.refreshChart!();
    }
  }

  Future<List<FluxRecord>> getDataFromInflux(
      String measurement, bool median) async {
    return _model.fetchDeviceDataFieldMedian(measurement, median);
  }

  double getDouble(dynamic value) =>
      value is String ? double.parse(value) : value.toDouble();

  // TODO: create specific controller for sensors

  var _sensorsInitialized = false;
  get sensorsInitialized => _sensorsInitialized;
  Future initSensors() async {
    _sensorsInitialized = true;
    _senosors = await _model.availableSensors();
  }

  Map<String, Stream<Map<String, double>>> _senosors = {};

  List<String> get sensors => _senosors.keys.toList();

  final Map<String, StreamSubscription> _sensorSubscriptions = {};

  bool sensorIsWriting(String sensor) =>
      _sensorSubscriptions.containsKey(sensor);

  setSensorIsWriting(String sensor, bool val) {
    if (val == sensorIsWriting(sensor)) return;
    final sensorStream = _senosors[sensor];
    if (sensorStream == null) throw Error();
    if (val) {
      // TODO(sensors): use other isolate for smooth ui ?
      _sensorSubscriptions[sensor] = sensorStream.listen((event) {
        _model.writeSensor(sensor, event);
      });
    } else if (_sensorSubscriptions[sensor] != null) {
      _sensorSubscriptions[sensor]!.cancel();
      _sensorSubscriptions.remove(sensor);
    }
  }
}
