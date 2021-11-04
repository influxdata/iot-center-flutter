import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:intl/intl.dart';

import 'iot_center.dart';

class DevicePage extends StatefulWidget {
  final Map selectedDevice;

  final List deviceList;

  @override
  State<StatefulWidget> createState() =>
      _DevicePageState(this.selectedDevice, this.deviceList);

  DevicePage(this.selectedDevice, this.deviceList);
}

class _DevicePageState extends State<DevicePage> {
  Map selectedDevice;
  List deviceList;
  bool _writeInProgress = false;

  _DevicePageState(this.selectedDevice, this.deviceList);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Device Detail"),
        ),
        body: Column(children: [
          Expanded(
              flex: 2,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                DropdownButton<String>(
                  itemHeight: 120.0,
                  hint: new Text("Select device"),
                  value: selectedDevice['deviceId'],
                  items: deviceList.map((dynamic map) {
                    return new DropdownMenuItem<String>(
                        value: map['deviceId'].toString(),
                        child: new Text(map['deviceId']));
                  }).toList(),
                  onChanged: (val) {
                    print("selected $val");
                    setState(() {
                      selectedDevice = deviceList
                          .firstWhere((element) => element['deviceId'] == val);
                    });
                  },
                ),
              ])),
          MaterialButton(
            onPressed: () async {
              if (_writeInProgress) {
                return;
              }
              var x = await _writeSampleData();
              print("Points written $x");
            },
            textTheme: ButtonTextTheme.primary,
            color: _writeInProgress ? Colors.red : Colors.indigo,
            child: Text(_writeInProgress
                ? "Write in progress..."
                : "Write testing data"),
          ),
          Spacer(),
          Expanded(
              flex: 8,
              child: Center(
                  child: FutureBuilder<DeviceConfig>(
                      future: fetchDeviceConfig(selectedDevice['deviceId']),
                      builder: (context, AsyncSnapshot<DeviceConfig> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return _buildList(snapshot.data!);
                        } else {
                          return Text("loading...");
                        }
                      }))),
          Expanded(
              flex: 10,
              child: Center(
                  child: FutureBuilder<dynamic>(
                      future: fetchMeasurements(selectedDevice['deviceId']),
                      builder: (context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return _buildMeasurementList(snapshot.data);
                        } else {
                          return Text("loading...");
                        }
                      }))),
        ]));
  }

  Future<num?> _writeSampleData() async {
    setState(() {
      var device = selectedDevice['deviceId'];
      print("write data.... $device");
      _writeInProgress = true;
      writeEmulatedData(device, (total, progress, ddd) {
        print("$total $progress $ddd");
      }).then((value) {
        print("Write Completed $value");
        setState(() {
          _writeInProgress = false;
        });
        return value;
      });
    });
  }

  Widget _buildList(DeviceConfig deviceDetail) {
    return ListView(
      children: [
        _tile(selectedDevice['deviceId'], 'Device Id', Icons.device_thermostat),
        _tile(deviceDetail.createdAt, 'Registration Time', Icons.lock_clock),
        _tile(
            deviceDetail.influxUrl, 'InfluxDB URL', Icons.cloud_done_outlined),
        _tile(deviceDetail.influxOrg, 'InfluxDB Organization', Icons.work),
        _tile(deviceDetail.influxBucket, 'InfluxDB Bucket',
            Icons.shopping_basket_rounded),
        _tile(deviceDetail.influxToken.toString().substring(0, 3) + "...",
            'InfluxDB Token', Icons.theaters),
        Divider(),
      ],
    );
  }

  ListTile _tile(String title, String subtitle, IconData icon) => ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          icon,
        ),
      );

  var _bold = TextStyle(fontWeight: FontWeight.bold);

  Widget _buildMeasurementList(List<FluxRecord> records) {
    List<TableRow> rows = [];
    rows.add(TableRow(children: [
      Text("Field", style: _bold),
      Text("Count", style: _bold),
      Text("max time", style: _bold),
      Text("max", style: _bold),
      Text("min", style: _bold),
    ]));

    var format = NumberFormat.decimalPattern();
    records.forEach((r) {
      rows.add(TableRow(children: [
        Text(
          r["_field"],
          textScaleFactor: 0.7,
        ),
        Text(r["count"].toString(), textScaleFactor: 0.7),
        Text(r["maxTime"], textScaleFactor: 0.7),
        Text(format.format(r["maxValue"]), textScaleFactor: 0.7),
        Text(format.format(r["minValue"]), textScaleFactor: 0.7),
      ]));
    });

    return Table(
        border: TableBorder(
            top: BorderSide(),
            bottom: BorderSide(),
            horizontalInside: BorderSide(),
            verticalInside: BorderSide()),
        children: rows);
  }
}
