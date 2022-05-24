import 'package:iot_center_flutter_mvc/src/settings/controller/device_controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DeviceDetail extends StatefulWidget {
  const DeviceDetail({required this.deviceId, Key? key}) : super(key: key);

  final String deviceId;

  @override
  _DeviceDetailState createState() {
    return _DeviceDetailState();
  }
}

class _DeviceDetailState extends StateMVC<DeviceDetail> {
  late DeviceController con;

  _DeviceDetailState() : super(DeviceController()) {
    con = controller as DeviceController;
  }

  @override
  void initState() {
    con.deviceId = widget.deviceId;

    super.initState();
    add(con);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: lightGrey,
        appBar: AppBar(
          title: const Text('Device Info'),
          backgroundColor: darkBlue,
          actions: [],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: con.selectedIndex,
          backgroundColor: Colors.white,
          selectedItemColor: pink,
          unselectedItemColor: darkBlue,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outlined),
              label: 'Device detail',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'Measurements',
            ),
          ],
          onTap: con.bottomMenuOnTap,
        ),
        body: Padding(padding: const EdgeInsets.all(10), child: con.actualTab));
  }
}
