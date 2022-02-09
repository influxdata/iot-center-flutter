import 'package:flutter/material.dart';
import 'package:flutter_influx_app/settings.dart';
import 'package:flutter_influx_app/virtual_device.dart';

import 'device_registrations.dart';

ThemeData myTheme = ThemeData();

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: myTheme,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const SettingsPage()));
                },
              ),
            ],
            bottom: const TabBar(
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
            title: const Text('IoT Center Demo'),
          ),
          body: const TabBarView(
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
