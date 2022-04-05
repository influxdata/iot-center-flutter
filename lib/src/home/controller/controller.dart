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

  bool editable = false;

  void refreshChartEditable(){
    for (var chart in _model.chartsList){
      chart.data.editableChart!();
    }
  }

 Function()? removeItemFromListView;


  void loadSavedData(){
    SharedPreferences.getInstance().then((prefs) {
      var result = prefs.getString("charts");

      if(result!.isNotEmpty){

        Iterable l = json.decode(result);
        List<Chart> charts = List<Chart>.from(l.map((model)=> Chart.fromJson(model)));

        _model.chartsList = charts;
      }
    });
  }

  void addNewChart(Chart chart){
    _model.chartsList.add(chart);
  }

  List<Chart> get chartsList => _model.chartsList;

  List get deviceList => _model.deviceList;
  List get timeOptionsList => _model.timeOptionList;
  List get chartTypeList => _model.chartTypeList;
  List get fieldNames => _model.fieldList;

  Map<String, dynamic>? get selectedDevice => _model.selectedDevice;
  String get selectedTimeOption => _model.selectedTimeOption;

  void setSelectedTimeOption(String value) => _model.selectedTimeOption = value;
  void setSelectedDevice(String value) => _model.selectedDeviceOnChange(value);

  Future<void> loadDevices() => _model.loadDevices();
  Future<void> loadFieldNames() => _model.loadFieldNames();
  Future<List<FluxRecord>> getMeasurements(String deviceId) async =>
      _model.fetchMeasurements(_model.iotCenterApi + "/api/env/$deviceId");

  Future<DeviceConfig> getDeviceConfig(String? deviceId) async {
    return _model.fetchDeviceConfig2(_model.iotCenterApi + "/api/env/$deviceId");
  }

  Future writeEmulatedData(String deviceId, Function onProgress) async =>
      _model.writeEmulatedData(deviceId, onProgress);

  void refreshChartListView() async {
    for (var chart in chartsList) {
      if (chart.data.chartType == ChartType.gauge) {
        await chart.data.refreshChart!();
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          chart.data.refreshChart!();
        });
      }
    }
  }

  Future<List<FluxRecord>> getDataFromInflux(
      String measurement, bool median) async {
    return median
        ? _model.fetchDeviceDataFieldMedian(
            _model.selectedDevice != null
                ? _model.selectedDevice!['deviceId']
                : null,
            measurement,
            _model.selectedTimeOption,
            _model.iotCenterApi)
        : _model.fetchDeviceDataField(
            _model.selectedDevice != null
                ? _model.selectedDevice!['deviceId']
                : null,
            measurement,
            _model.selectedTimeOption,
            _model.iotCenterApi);
  }

  double checkDouble(dynamic value) {
    if (value is String) {
      return double.parse(value);
    } else {
      return value.toDouble();
    }
  }
}
