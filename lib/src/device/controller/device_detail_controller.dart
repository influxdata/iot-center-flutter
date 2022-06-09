import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/device/view/dashboard.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DeviceDetailController extends ControllerMVC {
  factory DeviceDetailController([StateMVC? state]) =>
      _this ??= DeviceDetailController._(state);
  DeviceDetailController._(StateMVC? state)
      : _model = InfluxModel(),
        _dashboardController = DashboardController(),
        super(state);
  static DeviceDetailController? _this;
  final InfluxModel _model;
  DashboardController _dashboardController;

  Future<Device>? selectedDevice;

  InfluxDBClient get client => _model.client;
  bool editable = false;
  String get selectedTimeOption => _dashboardController.selectedTimeOption;

  get dashboardList => _model.fetchDashboards();

  Future writeEmulatedData(Function onProgress, String deviceId) async =>
      _model.writeEmulatedData(deviceId, onProgress);

  Future<List<FluxRecord>> getMeasurements(String deviceId) async =>
      _model.fetchMeasurements(deviceId);

  int rowCount = 0;

  int getRowCount(Device device) {
    return device.dashboard != null
        ? device.dashboard!
                .reduce((currentChart, nextChart) =>
                    currentChart.row > nextChart.row ? currentChart : nextChart)
                .row +
            1
        : 0;
  }

  void updateRowCount(Device device) {
    setState(() {
      rowCount = getRowCount(device);
    });
  }

  void initDevice(String deviceId) {
    selectedIndex = 0;
    selectedDevice = _model.fetchDeviceWithDashboard(deviceId).then((value) => initTabs(value));
  }

  Device initTabs(Device device) {
    measurements = getMeasurements(device.id);

    dashboardTab = getDashboardTab(device);
    deviceDetailTab = getDeviceDetailTab(device);
    measurementsTab = getMeasurementsTab();

    _dashboardController = DashboardController();

    actualTab = dashboardTab;

    return device;
  }

  Widget? deviceDetailTab;
  Widget? measurementsTab;
  Widget? dashboardTab;

  int selectedIndex = 0;
  Widget? actualTab;

  void bottomMenuOnTap(int index) {
    setState(() {
      selectedIndex = index;
      switch (index) {
        case 0:
          actualTab = dashboardTab;
          break;
        case 1:
          actualTab = deviceDetailTab;
          break;
        case 2:
          actualTab = measurementsTab;
          break;
      }
    });
  }

  Widget getDeviceDetailTab(Device device) {
    return ListView(
      children: [
        tile(device.id, 'Device Id', Icons.device_thermostat),
        tile(device.dashboardKey, 'Dashboard Key',
            Icons.dashboard),
        tile(device.createdAt, 'Registration Time',
            Icons.lock_clock),
        tile(device.key, 'Device key', Icons.key),
        tile(device.influxBucket, 'InfluxDB Bucket',
            Icons.shopping_basket_rounded),
      ],
    );
  }

  Widget getMeasurementsTab() {
    return ListView(
      children: [
        FutureBuilder<dynamic>(
            future: measurements,
            builder: (context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              if (snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.done) {
                // return _buildMeasurementList(snapshot.data);
                List<Widget> rows = [];
                for (var record in snapshot.data) {
                  rows.add(measurementContainer(record));
                }

                return Column(
                  children: rows,
                );
              } else {
                return const Text("loading...");
              }
            }),
      ],
    );
  }

  Widget getDashboardTab(Device device) {
    return DashboardTab(selectedDevice: device);
  }

  ListTile tile(String title, String subtitle, IconData icon) => ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          icon,
        ),
      );

  Widget measurementContainer(FluxRecord record) {
    var format = NumberFormat.decimalPattern();
    var textStyle = const TextStyle(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: boxDecor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
          child: Row(
            children: [
              SizedBox(
                  width: 130,
                  child: Text(
                    record["_field"],
                    style: textStyle,
                  )),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text("Count",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(record["count"].toString(), textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Max value",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(format.format(record["maxValue"]),
                            textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Min value",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(format.format(record["minValue"]),
                            textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Max time",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(record["maxTime"], textScaleFactor: 0.8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool writeInProgress = false;
  Future<List<FluxRecord>>? measurements;

  Future<num?> writeSampleData(String deviceId) async {
    writeEmulatedData((progressPercent, writtenPoints, totalPoints) {
      developer.log(
          "$progressPercent%, $writtenPoints of $totalPoints points written");
    }, deviceId)
        .then((value) {
      developer.log("Write completed. $value points written.");
      setState(() {
        writeInProgress = false;
      });
      refreshMeasurements(deviceId);
      refreshData();
      return value;
    });
    return null;
  }

  void refreshMeasurements(String deviceId) {
    setState(() {
      measurements = getMeasurements(deviceId);
      measurementsTab = getMeasurementsTab();
    });
    bottomMenuOnTap(selectedIndex);
  }

  void writeStart(String deviceId) async {
    if (writeInProgress) {
      return;
    }

    developer.log("write data.... $deviceId");
    setState(() {
      writeInProgress = true;
    });

    var x = await writeSampleData(deviceId);
    developer.log("Points written $x");
  }

  void editableOnChange(Device device) async {
    if (editable) {
      if (await _dashboardController.saveDashboard()){
        setState(() { 
          deviceDetailTab = getDeviceDetailTab(device);
        });
      }
    }
    setState(() {
      editable = !editable;
    });
    _dashboardController.editable = editable;
  }

  void refreshData() {
    _dashboardController.refreshCharts();
  }

  void newChartPage(BuildContext context) {
    var chart = Chart(
        row: 0,
        column: 0,
        data: ChartData.gauge(
          measurement: '',
          endValue: 100,
          label: 'label',
          unit: 'unit',
          startValue: 0,
          decimalPlaces: 0,
        ));

    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => ChartDetailPage(
            chart: chart,
            newChart: true,
          ),
        ));
  }

  void timeRangeOnChange(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _dashboardController.changeTimeRange(context);
      },
    ).whenComplete(() => setState(() {
          _dashboardController.selectedTimeOption;
        }));
  }

  void changeDashboard(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _dashboardController.changeDashboard(context, '');
      },
    );
  }
}
