import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title = 'IoT Center Demo'}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends StateMVC<HomePage> {
  _HomePageState() : super(HomePageController()) {
    con = controller as HomePageController;
  }

  late HomePageController con;

  @override
  void initState() {
    super.initState();
    add(con);
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: lightGrey,
        appBar: AppBar(
          title: const Text('IoT Center Demo'),
          backgroundColor: darkBlue,
          actions: [
            IconButton(
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
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: () {
                con.refreshDevices();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              color: Colors.white,
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const SettingsPage()));
                refresh();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<dynamic>(
              future: con.deviceList,
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.hasData &&
                    snapshot.connectionState == ConnectionState.done) {
                  return ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: boxDecor,
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 30, horizontal: 20),
                                  child: Icon(
                                    Icons.thermostat_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${snapshot.data[index]['deviceId']}',
                                        style: const TextStyle(
                                            color: darkBlue,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      // Text(
                                      //   '${snapshot.data[index]['dashboardKey']}',
                                      //   style: const TextStyle(
                                      //       color: Colors.grey,
                                      //       fontWeight: FontWeight.w400),
                                      // ),
                                    ],
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
                                          return con.removeDeviceDialog(context,
                                              snapshot.data[index]['deviceId']);
                                        },
                                      );
                                    }),
                                IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      color: darkBlue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DeviceDetailPage(
                                                      deviceId: snapshot
                                                          .data[index]
                                                      ['deviceId'])))
                                          .whenComplete(
                                              () => con.refreshDevices());
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
              }),
        ));
  }

  @override
  void onError(FlutterErrorDetails details) {
    super.onError(details);
  }
}
