import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class DeviceController extends ControllerMVC {
  factory DeviceController([StateMVC? state]) =>
      _this ??= DeviceController._(state);
  DeviceController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static DeviceController? _this;
  final InfluxModel _model;

  String? deviceId;
  InfluxDBClient get client => _model.client;

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

    actualTab = deviceDetailTab;

    super.initState();
  }

  Widget? deviceDetailTab;
  Widget? measurementsTab;

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
      }
    });
  }

  Widget getDeviceDetailTab() {
    var _client = client;

    return ListView(
      children: [
        FutureBuilder<FluxRecord>(
            future: deviceDetail(deviceId!),
            builder: (context, AsyncSnapshot<FluxRecord> snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              if (snapshot.hasData && deviceId!.isNotEmpty) {
                return Column(
                  children: [
                    tile(deviceId!, 'Device Id', Icons.device_thermostat),
                    tile(_client.url!, 'InfluxDB URL',
                        Icons.cloud_done_outlined),
                    tile(_client.org!, 'InfluxDB Organization', Icons.work),
                    tile(_client.bucket!, 'InfluxDB Bucket',
                        Icons.shopping_basket_rounded),
                  ],
                );
              } else {
                return const Text("loading...");
              }
            }),
        Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: FormButton(
            onPressed: () async {
              if (writeInProgress) {
                return;
              }
              var x = await writeSampleData();
              developer.log("Points written $x");
            },
            label:
                writeInProgress ? "Write in progress..." : "Write testing data",
          ),
        ),
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

  Future<FluxRecord> deviceDetail(String deviceId) =>
      _model.fetchDevice(deviceId);

  Future<num?> writeSampleData() async {
    setState(() {
      developer.log("write data.... $deviceId");
      writeInProgress = true;
      writeEmulatedData((progressPercent, writtenPoints, totalPoints) {
        developer.log(
            "$progressPercent%, $writtenPoints of $totalPoints points written");
      }).then((value) {
        developer.log("Write completed. $value points written.");
        setState(() {
          writeInProgress = false;
          measurements = getMeasurements();
        });
        return value;
      });
    });
    return null;
  }
}
