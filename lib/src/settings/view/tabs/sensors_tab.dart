import 'dart:ui';

import 'package:iot_center_flutter_mvc/src/settings/view/clientId_dialog.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class SensorsTab extends StatefulWidget {
  const SensorsTab({Key? key, required this.con}) : super(key: key);

  final SettingsPageController con;

  @override
  _SensorsTabState createState() {
    return _SensorsTabState();
  }
}

class _SensorsTabState extends StateMVC<SensorsTab> {
  final AppController appController = AppController();
  late final SensorsSubscriptionManager subscriptionManager;
  late final List<SensorInfo> sensors;
  bool clientRegistered = false;

  @override
  void initState() {
    super.initState();
    add(appController);
    add(widget.con);
    subscriptionManager = appController.sensorsSubscriptionManager;
    sensors = appController.sensors;
  }

  void onData(SensorMeasurement measure, SensorInfo sensor) {
    widget.con.writeSensor(
        SensorsSubscriptionManager.addNameToMeasure(sensor, measure));
    setState(() {});
  }

  void Function(bool value) onSensorSwitchChanged(SensorInfo sensor) =>
      (bool value) async {
        if (!clientRegistered) {
          final list = await widget.con.deviceList();
          if (list.any(
              (element) => element['deviceId'] == appController.clientId)) {
            clientRegistered = true;
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ClientIdDialog(
                  currentClientId: appController.clientId,
                  con: widget.con,
                  onClientRegistered: (clientId) {
                    appController.clientId = clientId;
                    clientRegistered = true;
                  },
                );
              },
            );
            return;
          }
        }

        if (value) {
          await subscriptionManager.trySubscribe(sensor, onData);
        } else {
          subscriptionManager.unsubscribe(sensor);
        }
        setState(() {});
      };

  @override
  Widget build(BuildContext context) {
    createSensorSwitchListTile(SensorInfo sensor) => SwitchListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sensor.name),
              Text(
                  subscriptionManager
                      .lastValueOf(sensor)
                      .entries
                      .map((entry) =>
                          "${entry.key}=${entry.value.toStringAsFixed(2)}")
                      .join(" "),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
            ],
          ),
          value: subscriptionManager.isSubscribed(sensor),
          onChanged: (sensor.availeble || sensor.requestPermission != null)
              ? onSensorSwitchChanged(sensor)
              : null,
        );

    final sensorsListView = Scrollbar(
      isAlwaysShown: true,
      child: ListView(
        children: sensors.map(createSensorSwitchListTile).toList(),
      ),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Text("clientId: " + appController.clientId),
        ),
        Expanded(child: sensorsListView)
      ],
    );
  }
}
