import 'dart:async';
import 'dart:convert';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Controller extends ControllerMVC {
  factory Controller([StateMVC? state]) => _this ??= Controller._(state);
  Controller._(StateMVC? state)
      : _model = Model(),
        super(state);
  static Controller? _this;
  final Model _model;

  Function()? removeItemFromListView;

  bool editable = false;

  void refreshChartEditable() {
    for (var chart in _model.chartsList) {
      chart.data.refreshHeader!();
    }
  }

  void loadSavedData() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.containsKey("charts")) {
        var result = prefs.getString("charts");

        if (result!.isNotEmpty && result != '[]') {
          Iterable l = json.decode(result);
          List<Chart> charts =
              List<Chart>.from(l.map((model) => Chart.fromJson(model)));

          _model.chartsList = charts;
        }
      }
    });
  }

  void addNewChart(Chart chart) {
    _model.chartsList.add(chart);
  }

  List<Chart> get chartsList => _model.chartsList;

  List get deviceList => _model.deviceList;
  List<DropDownItem> get timeOptionsList => _model.timeOptionList;
  List<DropDownItem> get chartTypeList => _model.chartTypeList;
  List get fieldNames => _model.fieldList;

  Map<String, dynamic>? get selectedDevice => _model.selectedDevice;
  String get selectedTimeOption => _model.selectedTimeOption;

  void setSelectedTimeOption(String value) => _model.selectedTimeOption = value;
  Map<String, dynamic>? setSelectedDevice(String? value, bool setNull) =>
      _model.selectedDeviceOnChange(value, setNull);

  Future<void> loadDevices() => _model.loadDevices();

  Future<void> loadFieldNames() => _model.loadFieldNames();

  Future<List<FluxRecord>> getMeasurements(Map<String, dynamic>? device) async {
    var deviceId = device != null ? device['deviceId'] : '';
    return _model.fetchMeasurements(_model.iotCenterApi + "/api/env/$deviceId");
  }

  Future<DeviceConfig> getDeviceConfig(Map<String, dynamic>? device) async {
    var deviceId = device != null ? device['deviceId'] : '';
    return _model
        .fetchDeviceConfig2(_model.iotCenterApi + "/api/env/$deviceId");
  }

  Future removeDeviceConfig(Map<String, dynamic>? device) async {
    await _model.removeDeviceConfig(device);
  }

  Future writeEmulatedData(String deviceId, Function onProgress) async =>
      _model.writeEmulatedData(deviceId, onProgress);

  Future<void> refreshChartListView() async {
    for (var chart in chartsList) {
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
    _senosors = await _model.availebleSensors();
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
