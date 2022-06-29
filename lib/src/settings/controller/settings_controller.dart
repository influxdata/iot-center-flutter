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
  Future<List<dynamic>> get dashboardList => _model.fetchDashboards();

  Future<void> checkClient(InfluxDBClient client) => _model.checkClient(client);

  DashboardsTab? dashboardsListView;
  late SensorsTab sensorsView;
  InfluxSettingsTab? influxSettings;

  int selectedIndex = 0;
  Widget? actualTab;

  bool deleteWithData = false;
  bool settingsReadonly = true;

  @override
  void initState() {
    super.initState();

    dashboardsListView = DashboardsTab(con: this);
    sensorsView = SensorsTab(con: this);
    influxSettings = InfluxSettingsTab(con: this);

    if (actualTab != null) {
      bottomMenuOnTap(selectedIndex);
    } else {
      actualTab = dashboardsListView;
    }
  }

  void bottomMenuOnTap(int index) {
    setState(() {
      selectedIndex = index;
      switch (index) {
        case 0:
          actualTab = dashboardsListView;
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

  void refreshDashboards() {
    setState(() {
      dashboardList;
      dashboardsListView = DashboardsTab(con: this);
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

  Widget newDashboardDialog(BuildContext context) {
    late var newDashboardController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    var selectedDeviceType = _model.deviceTypeList.first.value;
    return AlertDialog(
      title: const Text("New Dashboard"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Expanded(
                  child: TextBoxRow(
                hint: 'Dashboard key',
                label: '',
                controller: newDashboardController,
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Dashboard key cannot be empty';
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

                await _model.createDashboard(newDashboardController.text,
                    selectedDeviceType, List.empty(growable: true));
                refreshDashboards();

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

  Widget removeDashboardDialog(BuildContext context, dashboardKey) {
    return AlertDialog(
      title: Text("Confirm delete dashboard $dashboardKey ?"),
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
              _model.deleteDashboard(dashboardKey);
              Navigator.of(context).pop();

              refreshDashboards();
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

  Future<List<dynamic>> deviceList(String data) {
    return _model.fetchDashboardDevices(data);
  }

  void writeSensor(Map<String, double> fieldValueMap) {
    _model.writePoint(fieldValueMap);
  }
}
