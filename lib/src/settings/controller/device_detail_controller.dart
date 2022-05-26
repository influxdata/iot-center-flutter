import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DeviceDetailController extends ControllerMVC {
  factory DeviceDetailController([StateMVC? state]) =>
      _this ??= DeviceDetailController._(state);
  DeviceDetailController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static DeviceDetailController? _this;
  final InfluxModel _model;

  String? deviceId;
  Device? selectedDevice;
  InfluxDBClient get client => _model.client;

  get dashboardList => _model.fetchDashboards();

  Future writeEmulatedData(Function onProgress) async =>
      _model.writeEmulatedData(deviceId!, onProgress);

  Future<List<FluxRecord>> getMeasurements() async =>
      _model.fetchMeasurements(deviceId!);

  @override
  void initState() {
    selectedIndex = 0;
    measurements = getMeasurements();

    deviceDetailTab = getDeviceDetailTab();
    measurementsTab = getMeasurementsTab();
    dashboardTab = getDashboardTab();

    actualTab = deviceDetailTab;

    super.initState();
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
          actualTab = deviceDetailTab;
          break;
        case 1:
          actualTab = measurementsTab;
          break;
        case 2:
          actualTab = dashboardTab;
          break;
      }
    });
  }

  Widget getDeviceDetailTab() {
    return ListView(
      children: [
        FutureBuilder<Device>(
            future: deviceDetail(deviceId!),
            builder: (context, AsyncSnapshot<Device> snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              if (snapshot.hasData && deviceId!.isNotEmpty) {
                return Column(
                  children: [
                    tile(deviceId!, 'Device Id', Icons.device_thermostat),
                    tile(snapshot.data!.dashboardKey, 'Dashboard Key',
                        Icons.dashboard),
                    tile(snapshot.data!.createdAt, 'Registration Time',
                        Icons.lock_clock),
                    tile(snapshot.data!.key, 'Device key', Icons.key),
                    tile(snapshot.data!.influxUrl, 'InfluxDB URL',
                        Icons.cloud_done),
                    tile(snapshot.data!.influxOrg, 'InfluxDB Organization',
                        Icons.work),
                    tile(snapshot.data!.influxBucket, 'InfluxDB Bucket',
                        Icons.shopping_basket_rounded),
                    tile(snapshot.data!.tokenSubstring, 'InfluxDB Token',
                        Icons.theaters),
                  ],
                );
              } else {
                return const Text("loading...");
              }
            }),
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

  Widget getDashboardTab() {
    return FutureBuilder<dynamic>(
        future: dashboardList,
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      decoration: boxDecor,
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 30, horizontal: 10),
                            child: Icon(
                              Icons.dashboard,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${snapshot.data[index]['key']}',
                                  style: const TextStyle(
                                      color: darkBlue,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                              icon: Icon(
                                snapshot.data[index]['key'] ==
                                        selectedDevice?.dashboardKey
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: snapshot.data[index]['key'] ==
                                        selectedDevice?.dashboardKey
                                    ? pink
                                    : darkBlue,
                              ),
                              onPressed: () {
                                selectedDevice?.dashboardKey =
                                    snapshot.data[index]['key'];

                                _model.pairDeviceDashboard(selectedDevice!.id,
                                    snapshot.data[index]['key']);

                                setState(() {
                                  selectedDevice?.dashboardKey;
                                });
                              }),
                        ],
                      ),
                    ),
                  );
                });
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
        });
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

  Future<Device> deviceDetail(String deviceId) =>
      _model.fetchDevice(deviceId).then((value) => selectedDevice = value);

  Future<num?> writeSampleData() async {
    writeEmulatedData((progressPercent, writtenPoints, totalPoints) {
      developer.log(
          "$progressPercent%, $writtenPoints of $totalPoints points written");
    }).then((value) {
      developer.log("Write completed. $value points written.");
      setState(() {
        writeInProgress = false;
      });
      refreshMeasurements();
      return value;
    });
    return null;
  }

  void refreshMeasurements() {
    setState(() {
      measurements = getMeasurements();
      measurementsTab = getMeasurementsTab();
    });
    bottomMenuOnTap(selectedIndex);
  }

  void writeStart() async {
    if (writeInProgress) {
      return;
    }

    developer.log("write data.... $deviceId");
    setState(() {
      writeInProgress = true;
    });

    var x = await writeSampleData();
    developer.log("Points written $x");
  }
}
