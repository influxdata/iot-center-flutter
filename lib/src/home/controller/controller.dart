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

  ChartListView getChartListView() {
    _model.chartListView = const ChartListView();
    return _model.chartListView;
  }

  List getDeviceList() => _model.deviceList;
  List getTimeOptionsList() => _model.timeOptionList;
  List getChartTypeList() => _model.chartTypeList;
  List getFieldNames() => _model.fieldList;

  String getSelectedDevice() => _model.selectedTimeOption;
  String getSelectedTimeOption() => _model.selectedTimeOption;

  void setSelectedTimeOption(String value) => _model.selectedTimeOption = value;
  void setSelectedDevice(String value) => _model.selectedDeviceOnChange(value);

  Future<void> loadDevices() => _model.loadDevices();
  Future<void> loadFieldNames() => _model.loadFieldNames();

  void refreshChartListView() => setState(() {});

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
