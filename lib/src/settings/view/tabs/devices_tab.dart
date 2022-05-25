import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DevicesTab extends StatefulWidget {
  const DevicesTab({
    required this.con,
    Key? key,
  }) : super(key: key);

  final SettingsPageController con;

  @override
  State<StatefulWidget> createState() {
    return _DevicesTabState();
  }
}

class _DevicesTabState extends State<DevicesTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: widget.con.deviceList,
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      decoration: boxDecor,
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 30, horizontal: 10),
                            child: Icon(
                              Icons.thermostat_outlined,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${snapshot.data[index]['deviceId']}',
                              style: const TextStyle(
                                  color: darkBlue, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: pink,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return widget.con.removeDeviceDialog(context,
                                        snapshot.data[index]['deviceId']);
                                  },
                                );
                              }),
                          IconButton(
                              icon: const Icon(
                                Icons.info_outlined,
                                color: darkBlue,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DeviceDetailPage(
                                            deviceId: snapshot.data[index]
                                                ['deviceId']))).whenComplete(
                                    () => widget.con.refreshDevices());
                              }),
                        ],
                      ),
                    ),
                  );
                });
          } else {
            return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: pink,
                strokeWidth: 3,
              ),
            );
          }
        });
  }
}
