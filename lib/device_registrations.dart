import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_influx_app/iot_center.dart';

import 'device_page.dart';

class DeviceRegistrations extends StatefulWidget {
  const DeviceRegistrations({Key? key}) : super(key: key);

  @override
  State createState() => _DeviceRegistrationsState();
}

class _DeviceRegistrationsState extends State<DeviceRegistrations> {
  List devices = [];

  @override
  void initState() {
    super.initState();
    fetchDevices().then((devicesJson) {
      setState(() {
        devices.clear();
        devices.addAll(devicesJson);
      });
    }).catchError((e) {
      developer.log(e, level: 1000);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, position) {
          return Column(children: <Widget>[
            const Divider(height: 5.0),
            ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => DevicePage(
                              selectedDevice: devices[position],
                              deviceList: devices)));
                },
                title: Text('${devices[position]['deviceId']}',
                    style: const TextStyle(fontSize: 22.0))),
          ]);
        });
  }
}
