import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:intl/intl.dart';

import 'iot_center.dart';

class DevicePage extends StatefulWidget {
  final Map selectedDevice;
  final List deviceList;

  @override
  State<StatefulWidget> createState() => _DevicePageState();

  const DevicePage(
      {Key? key, required this.selectedDevice, required this.deviceList})
      : super(key: key);
}

class _DevicePageState extends State<DevicePage> {
  // List deviceList;
  bool _writeInProgress = false;

  @override
  Widget build(BuildContext context) {
    Map selectedDevice = widget.selectedDevice;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Device Detail"),
        ),
        body: Column(children: [
          Expanded(
              flex: 2,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                DropdownButton<String>(
                  itemHeight: 120.0,
                  hint: const Text("Select device"),
                  value: selectedDevice['deviceId'],
                  items: widget.deviceList.map((dynamic map) {
                    return DropdownMenuItem<String>(
                        value: map['deviceId'].toString(),
                        child: Text(map['deviceId']));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedDevice = widget.deviceList
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
              var x = await _writeSampleData(widget.selectedDevice);
              developer.log("Points written $x");
            },
            textTheme: ButtonTextTheme.primary,
            color: _writeInProgress ? Colors.red : Colors.indigo,
            child: Text(_writeInProgress
                ? "Write in progress..."
                : "Write testing data"),
          ),
          const Spacer(),
          Expanded(
              flex: 8,
              child: Center(
                  child: FutureBuilder<DeviceConfig>(
                      future:
                          fetchDeviceConfig(widget.selectedDevice['deviceId']),
                      builder: (context, AsyncSnapshot<DeviceConfig> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return _buildList(
                              widget.selectedDevice, snapshot.data!);
                        } else {
                          return const Text("loading...");
                        }
                      }))),
          Expanded(
              flex: 10,
              child: Center(
                  child: FutureBuilder<dynamic>(
                      future:
                          fetchMeasurements(widget.selectedDevice['deviceId']),
                      builder: (context, AsyncSnapshot<dynamic> snapshot) {
                        if (snapshot.hasError) {
                          return Text(snapshot.error.toString());
                        }
                        if (snapshot.hasData) {
                          return _buildMeasurementList(snapshot.data);
                        } else {
                          return const Text("loading...");
                        }
                      }))),
        ]));
  }

  Future<num?> _writeSampleData(selectedDevice) async {
    setState(() {
      var device = selectedDevice['deviceId'];
      developer.log("write data.... $device");
      _writeInProgress = true;
      writeEmulatedData(device, (progressPercent, writtenPoints, totalPoints) {
        developer.log(
            "$progressPercent%, $writtenPoints of $totalPoints points written");
      }).then((value) {
        developer.log("Write completed. $value points written.");
        setState(() {
          _writeInProgress = false;
        });
        return value;
      });
    });
    return null;
  }

  Widget _buildList(selectedDevice, DeviceConfig deviceDetail) {
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
        const Divider(),
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

  final _bold = const TextStyle(fontWeight: FontWeight.bold);

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
    for (var r in records) {
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
    }

    return Table(
        border: const TableBorder(
            top: BorderSide(),
            bottom: BorderSide(),
            horizontalInside: BorderSide(),
            verticalInside: BorderSide()),
        children: rows);
  }
}
