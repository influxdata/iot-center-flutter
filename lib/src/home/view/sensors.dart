import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class SensorsPage extends StatefulWidget {
  const SensorsPage({Key? key}) : super(key: key);

  @override
  _SensorsPageState createState() {
    return _SensorsPageState();
  }
}

class _SensorsPageState extends StateMVC<SensorsPage> {
  late Controller con;

  _SensorsPageState() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    onChanged(String sensor) => (bool value) {
          setState(() {
            con.setSensorIsWriting(sensor, value);
          });
        };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe sensors'),
        backgroundColor: darkBlue,
      ),
      body: ListView(
          children: con.sensors
              .map((String sensor) => SwitchListTile(
                    value: con.sensorIsWriting(sensor),
                    onChanged: onChanged(sensor),
                    title: Text(sensor),
                  ))
              .toList()),
    );
  }
}
