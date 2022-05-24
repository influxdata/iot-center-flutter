import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class SensorsView extends StatefulWidget {
  const SensorsView({Key? key}) : super(key: key);

  @override
  _SensorsViewState createState() {
    return _SensorsViewState();
  }
}

class _SensorsViewState extends StateMVC<SensorsView> {
  late Controller con;

  _SensorsViewState() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: find better way of initializating sensors
    if (!con.sensorsInitialized) {
      con.initSensors().then((value) => setState(
            () {},
      ));
    }

    onChanged(String sensor) => (bool value) {
      setState(() {
        con.setSensorIsWriting(sensor, value);
      });
    };

    return ListView(
        children: con.sensors
            .map((String sensor) => SwitchListTile(
          value: con.sensorIsWriting(sensor),
          onChanged: onChanged(sensor),
          title: Text(sensor),
        ))
            .toList());
  }
}
