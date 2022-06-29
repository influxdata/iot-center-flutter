import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
    add(appController);
  }

  void onData(SensorMeasurement measure, SensorInfo sensor) {
    widget.con.writeSensor(
        SensorsSubscriptionManager.addNameToMeasure(sensor, measure));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionManager = appController.sensorsSubscriptionManager;
    final sensors = appController.sensors;

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
              ? ((value) async {
                  if (value) {
                    await subscriptionManager.trySubscribe(sensor, onData);
                  } else {
                    subscriptionManager.unsubscribe(sensor);
                  }
                  setState(() {});
                })
              : null,
        );

    final sensorsListView = Scrollbar(
      isAlwaysShown: true,
      child: ListView(
        children: sensors.map(createSensorSwitchListTile).toList(),
      ),
    );

    return sensorsListView;
  }
}
