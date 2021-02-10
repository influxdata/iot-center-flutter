import 'package:flutter/material.dart';
import 'package:flutter_influx_app/dashboard.dart';
import 'package:flutter_influx_app/virtual_device.dart';

import 'device_registrations.dart';

void main() {
  runApp(
    MaterialApp(
      home: HomePage(),
    ),
  );
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
        primarySwatch: Colors.indigo
        ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.device_thermostat),
                  text: 'Virtual device',
                ),
                Tab(
                  icon: Icon(Icons.app_registration),
                  text: 'Device Registrations',
                ),
              ],
            ),
            title: Text('IoT Center V2 Homepage'),
          ),
          body: TabBarView(
            children: [
              VirtualDevice(),
              DeviceRegistrations(),
            ],
          ),
        ),
      ),
    );
  }
}

