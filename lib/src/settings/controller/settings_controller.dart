import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class SettingsController extends ControllerMVC {
  factory SettingsController([StateMVC? state]) =>
      _this ??= SettingsController._(state);
  SettingsController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static SettingsController? _this;
  final InfluxModel _model;

  InfluxDBClient get client => _model.client;
  Future<List<dynamic>> get deviceList => _model.fetchDevices();

  Future<void> checkClient(InfluxDBClient client) => _model.checkClient(client);

  DevicesListView? devicesListView;
  late SensorsView sensorsView;
  late InfluxSettings influxSettings;

  int selectedIndex = 0;
  Widget? actualTab;

  @override
  void initState() {
    super.initState();
    devicesListView = DevicesListView(con: this);
    sensorsView = const SensorsView();
    influxSettings = InfluxSettings(con: this);

    actualTab = devicesListView;
  }

  void bottomMenuOnTap(int index) {
    setState(() {
      selectedIndex = index;
      switch (index) {
        case 0:
          actualTab = devicesListView;
          break;
        case 1:
          actualTab = sensorsView;
          break;
        case 2:
          actualTab = influxSettings;
          break;
      }
    });
  }

  void refreshDevices() {
    setState(() {
      deviceList;
      devicesListView = DevicesListView(con: this);
    });

    bottomMenuOnTap(selectedIndex);
  }

  /// Load client settings for a InfluxDB from Shared Preferences.
  void loadSavedInfluxClient() {
    client.loadInfluxClient();
  }

  /// Save client settings for a InfluxDB from Shared Preferences.
  void saveInfluxClient() {
    client.saveInfluxClient();
  }

  Widget newDeviceDialog(BuildContext context) {
    late TextEditingController newDeviceController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("New Device"),
      content: Form(
        key: _formKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: TextBoxRow(
            hint: 'Device ID',
            label: '',
            controller: newDeviceController,
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Device ID cannot be empty';
              }
              return null;
            },
            onSaved: (value) async {
              await _model.createDevice(value.toString());
              refreshDevices();

              Navigator.of(context).pop();
            },
          )),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save"),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
              }
            })),
      ],
    );
  }

  Widget removeDeviceDialog(BuildContext context, deviceId) {
    return AlertDialog(
      title: Text("Confirm delete device $deviceId ?"),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: (() async {
              await _model.deleteDevice(deviceId!, false);
              Navigator.of(context).pop();

              refreshDevices();
            })),
      ],
    );
  }
}
