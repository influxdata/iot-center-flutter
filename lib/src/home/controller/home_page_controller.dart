import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class HomePageController extends ControllerMVC {
  factory HomePageController([StateMVC? state]) =>
      _this ??= HomePageController._(state);
  HomePageController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static HomePageController? _this;
  final InfluxModel _model;

  InfluxDBClient get client => _model.client;
  Future<List<dynamic>> get deviceList => _model.fetchDevices();


  Future<void> checkClient(InfluxDBClient client) => _model.checkClient(client);

  DashboardsTab? devicesListView;
  late SensorsTab sensorsView;
  InfluxSettingsTab? influxSettings;

  int selectedIndex = 0;
  Widget? actualTab;

  bool deleteWithData = false;
  bool settingsReadonly = true;

  void refreshDevices() {
    setState(() {
      deviceList;
    });
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

    var selectedDeviceType = _model.deviceTypeList.first.value;
    return AlertDialog(
      title: const Text("New Device"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
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
              )),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Expanded(
                child: DropDownListRow(
                  items: _model.deviceTypeList,
                  value: selectedDeviceType,
                  onChanged: (value) {
                    selectedDeviceType = value!;
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save", style: TextStyle(color: pink)),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                await _model.createDevice(
                    newDeviceController.text, selectedDeviceType);
                refreshDevices();

                Navigator.of(context).pop();
              }
            })),
      ],
    );
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return Colors.blue;
    }
    return pink;
  }

  Widget removeDeviceDialog(BuildContext context, deviceId) {
    deleteWithData = false;
    return AlertDialog(
      title: Text("Confirm delete device $deviceId ?"),
      content: StatefulBuilder(builder: (context, setState) {
        return Row(children: <Widget>[
          Checkbox(
            checkColor: Colors.white,
            fillColor: MaterialStateProperty.resolveWith(getColor),
            value: deleteWithData,
            onChanged: (bool? value) {
              setState(() {
                deleteWithData = value!;
              });
            },
          ),
          const Text("Delete device with data?"),
        ]);
      }),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Delete", style: TextStyle(color: pink)),
            onPressed: (() async {
              await _model.deleteDevice(deviceId!, deleteWithData);
              Navigator.of(context).pop();

              refreshDevices();
            })),
      ],
    );
  }

  void deviceDetail(BuildContext context, String deviceId) async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                DeviceDetailPage(
                    deviceId: deviceId)))
        .whenComplete(
            () => refreshDevices());
  }
}
