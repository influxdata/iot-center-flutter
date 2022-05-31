import 'dart:async';

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class SettingsPageController extends ControllerMVC {
  factory SettingsPageController([StateMVC? state]) =>
      _this ??= SettingsPageController._(state);
  SettingsPageController._(StateMVC? state)
      : _model = InfluxModel(),
        super(state);
  static SettingsPageController? _this;
  final InfluxModel _model;

  InfluxDBClient get client => _model.client;
  Future<List<dynamic>> get deviceList => _model.fetchDevices();

  Future<void> checkClient(InfluxDBClient client) => _model.checkClient(client);

  DevicesTab? devicesListView;
  late SensorsTab sensorsView;
  InfluxSettingsTab? influxSettings;

  int selectedIndex = 0;
  Widget? actualTab;

  bool deleteWithData = false;
  bool settingsReadonly = true;

  @override
  void initState() {
    super.initState();

    devicesListView = DevicesTab(con: this);
    sensorsView = SensorsTab(con: this);
    influxSettings = InfluxSettingsTab(con: this);

    if (actualTab != null) {
      bottomMenuOnTap(selectedIndex);
    } else {
      actualTab = devicesListView;
    }
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
      devicesListView = DevicesTab(con: this);
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
            child: const Text("Save", style: TextStyle(color: pink)),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
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

  void changeReadonly() {
    setState(() {
      settingsReadonly = !settingsReadonly;
      influxSettings = InfluxSettingsTab(con: this);
    });
    bottomMenuOnTap(selectedIndex);
  }

  var _sensorsInitialized = false;
  get sensorsInitialized => _sensorsInitialized;
  Future initSensors() async {
    _sensorsInitialized = true;
    _senosors = await _model.availableSensors();
  }

  Map<String, Stream<Map<String, double>>> _senosors = {};

  List<String> get sensors => _senosors.keys.toList();

  final Map<String, StreamSubscription> _sensorSubscriptions = {};

  bool sensorIsWriting(String sensor) =>
      _sensorSubscriptions.containsKey(sensor);

  setSensorIsWriting(String sensor, bool val) {
    if (val == sensorIsWriting(sensor)) return;
    final sensorStream = _senosors[sensor];
    if (sensorStream == null) throw Error();
    if (val) {
      // TODO(sensors): use other isolate for smooth ui ?
      _sensorSubscriptions[sensor] = sensorStream.listen((event) {
        _model.writeSensor(sensor, event);
      });
    } else if (_sensorSubscriptions[sensor] != null) {
      _sensorSubscriptions[sensor]!.cancel();
      _sensorSubscriptions.remove(sensor);
    }
  }

}
