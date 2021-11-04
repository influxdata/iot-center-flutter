import 'package:flutter/material.dart';
import 'package:flutter_influx_app/iot_center.dart';

import 'device_page.dart';

class DeviceRegistrations extends StatefulWidget {
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
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, position) {
          return Column(children: <Widget>[
            Divider(height: 5.0),
            ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) =>
                              DevicePage(devices[position], devices)));
                },
                title: Text('${devices[position]['deviceId']}',
                    style: TextStyle(fontSize: 22.0))),
          ]);
        });
  }
}
