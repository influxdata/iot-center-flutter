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
    onChanged(bool value) {
      setState(() {
        con.sensorsIsWriting = value;
      });
    }

    // TODO(sensors): implement view
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: darkBlue,
      ),
      body: ListView(children: [
        Switch(
          value: con.sensorsIsWriting,
          onChanged: onChanged,
        )
      ]),
    );
  }
}
