import 'package:iot_center_flutter_mvc/src/device/controller/device_detail_controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({required this.deviceId, Key? key}) : super(key: key);

  final String deviceId;

  @override
  _DeviceDetailPageState createState() {
    return _DeviceDetailPageState();
  }
}

class _DeviceDetailPageState extends StateMVC<DeviceDetailPage> {
  late DeviceDetailController con;

  _DeviceDetailPageState() : super(DeviceDetailController()) {
    con = controller as DeviceDetailController;
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
          title: Text(widget.deviceId),
          backgroundColor: darkBlue,
          actions: [
            Visibility(
              visible: con.selectedIndex == 0,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                onPressed: () {},
              ),
            ),
            Visibility(
              visible: con.selectedIndex == 0,
              child: IconButton(
                icon: Icon(con.editable ? Icons.done : Icons.edit),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    con.editable = !con.editable;
                  });
                  con.refreshChartEditable();
                },
              ),
            ),
            Visibility(
              visible: con.selectedIndex == 1,
              child: IconButton(
                icon: Icon(con.writeInProgress
                    ? Icons.lock_outline
                    : Icons.app_registration),
                color: Colors.white,
                onPressed: () async {
                  con.writeStart();
                },
              ),
            ),
            Visibility(
              visible: con.selectedIndex == 2,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                onPressed: () {
                  con.refreshMeasurements();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Visibility(
          visible: con.editable,
          child: FloatingActionButton(
            backgroundColor: darkBlue,
            child: const Icon(Icons.add),
            onPressed: () {},
          ),
        ),
        bottomNavigationBar: Visibility(
          visible: !con.editable,
          child: BottomNavigationBar(
            currentIndex: con.selectedIndex,
            backgroundColor: Colors.white,
            selectedItemColor: pink,
            unselectedItemColor: darkBlue,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                label: 'Dashboard',
              ),
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
        ),
        body: Padding(padding: const EdgeInsets.all(10), child: con.actualTab));
  }
}
