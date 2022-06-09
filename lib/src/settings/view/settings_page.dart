import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends StateMVC<SettingsPage> {
  late SettingsPageController con;

  _SettingsPageState() : super(SettingsPageController()) {
    con = controller as SettingsPageController;
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
                        return con.newDashboardDialog(context);
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
                  con.refreshDashboards();
                },
              ),
            ),
            Visibility(
              visible: con.selectedIndex == 2,
              child: IconButton(
                icon: Icon(con.settingsReadonly
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open),
                color: Colors.white,
                onPressed: () {
                  con.changeReadonly();
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
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboards',
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
        body:
            Padding(padding: const EdgeInsets.all(10), child: con.actualTab!));
  }
}
