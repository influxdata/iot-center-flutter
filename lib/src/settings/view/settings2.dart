import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class Settings2Page extends StatefulWidget {
  const Settings2Page({Key? key}) : super(key: key);

  @override
  _Settings2PageState createState() {
    return _Settings2PageState();
  }
}

class _Settings2PageState extends StateMVC<Settings2Page> {
  late SettingsController con;

  _Settings2PageState() : super(SettingsController()) {
    con = controller as SettingsController;
  }

  @override
  void initState() {
    super.initState();
    add(con);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: lightGrey,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: darkBlue,
          actions: [
            Visibility(
              visible: con.selectedIndex == 0,
              child: IconButton(
                  icon: const Icon(Icons.add),
                  color: Colors.white,
                  onPressed: (() {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return con.newDeviceDialog(context);
                      },
                    );
                  })),
            ),
            Visibility(
              visible: con.selectedIndex == 0,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                onPressed: () {
                  con.refreshDevices();
                },
              ),
            ),
          ],
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
              icon: Icon(Icons.thermostat_outlined),
              label: 'Devices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors),
              label: 'Sensors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_outlined),
              label: 'Influx settings',
            ),
          ],
          onTap: con.bottomMenuOnTap,
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: con.actualTab!));
  }
}
