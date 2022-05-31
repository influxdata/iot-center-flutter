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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: find better way of initializating sensors
    if (!widget.con.sensorsInitialized) {
      widget.con.initSensors().then((value) => setState(
            () {},
      ));
    }

    onChanged(String sensor) => (bool value) {
      setState(() {
        widget.con.setSensorIsWriting(sensor, value);
      });
    };

    return ListView(
        children: widget.con.sensors
            .map((String sensor) => SwitchListTile(
          value: widget.con.sensorIsWriting(sensor),
          onChanged: onChanged(sensor),
          title: Text(sensor),
        ))
            .toList());
  }
}
