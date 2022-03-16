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
    _model.chartListView = ChartListView(con: this);
    return _model.chartListView;
  }

  List getDeviceList() => _model.deviceList;
  List getTimeOptionsList() => _model.timeOptions;
  String getSelectedTimeOption() => _model.selectedTimeOption;


  Future<void> loadDevices() => _model.loadDevices();

  void refreshChartListView() => setState(() {});

  Future<List<FluxRecord>> getDataFromInflux(
      String measurement, bool last) async {
    return last
        ? _model.fetchDeviceDataFieldLast(
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

  void refreshCharts(ChartListView chartListView) {
    chartListView = ChartListView(con: this);
  }
}
