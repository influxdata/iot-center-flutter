import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DashboardsTab extends StatefulWidget {
  const DashboardsTab({
    required this.con,
    Key? key,
  }) : super(key: key);

  final SettingsPageController con;

  @override
  State<StatefulWidget> createState() {
    return _DashboardsTabState();
  }
}

class _DashboardsTabState extends State<DashboardsTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: widget.con.dashboardList,
        builder: (context, AsyncSnapshot<dynamic> dashboardRecords) {
          if (dashboardRecords.hasData &&
              dashboardRecords.connectionState == ConnectionState.done) {
            return ListView.builder(
                itemCount: dashboardRecords.data.length,
                itemBuilder: (_, index) {
                  var devicesList = widget.con
                      .deviceList(dashboardRecords.data[index]['dashboardKey'] ?? "");

                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Container(
                      decoration: boxDecor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(right: 10.0),
                                  child: Icon(
                                    Icons.dashboard_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dashboard key:   ${dashboardRecords.data[index]['dashboardKey']}',
                                        style: const TextStyle(
                                            color: darkBlue,
                                            fontWeight: FontWeight.w500),
                                      ),
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
                                          return widget.con
                                              .removeDashboardDialog(
                                                  context,
                                                  dashboardRecords.data[index]
                                                      ['dashboardKey']);
                                        },
                                      );
                                    }),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Divider(
                                color: Colors.black,
                                height: 36,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child: FutureBuilder<dynamic>(
                                        future: devicesList,
                                        builder: (context,
                                            AsyncSnapshot<dynamic>
                                                devicesRecord) {
                                          if (devicesRecord.hasData &&
                                              devicesRecord.connectionState ==
                                                  ConnectionState.done) {
                                            List<Widget> deviceRows = [];
                                            for (var device
                                                in devicesRecord.data) {
                                              deviceRows.add(Row(
                                                children: [
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 10.0),
                                                    child: Icon(
                                                      Icons.thermostat_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    device['deviceId'],
                                                    style: const TextStyle(
                                                        color: darkBlue,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ));
                                            }

                                            if (deviceRows.isEmpty) {
                                              deviceRows.add(Row(
                                                children: const [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 10.0),
                                                    child: Icon(
                                                      Icons.cancel_outlined,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    'No devices',
                                                    style: TextStyle(
                                                        color: darkBlue,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ));
                                            }

                                            return Column(
                                              children: deviceRows,
                                            );
                                          }
                                          return const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: pink,
                                              strokeWidth: 3,
                                            ),
                                          );
                                        }),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
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
