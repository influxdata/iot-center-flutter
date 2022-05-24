import 'dart:convert';

import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title = 'IoT Center Demo'}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends StateMVC<HomePage> {
  _HomePageState() : super(Controller()) {
    con = controller as Controller;
  }

  late Controller con;
  String _selectedDevice = '';
  Future<void>? _deviceList;

  int? rowCount = 0;
  bool expandAppBar = false;

  @override
  void initState() {
    super.initState();

    _deviceList = con.loadDevices().whenComplete(() => _selectedDevice =
        con.selectedDevice != null ? con.selectedDevice!['deviceId'] : '');

    rowCount = con.chartsList
            .reduce((currentChart, nextChart) =>
                currentChart.row > nextChart.row ? currentChart : nextChart)
            .row +
        1;

    con.removeItemFromListView = () {
      setState(() {
        rowCount = con.chartsList.isNotEmpty
            ? con.chartsList
                    .reduce((currentChart, nextChart) =>
                        currentChart.row > nextChart.row
                            ? currentChart
                            : nextChart)
                    .row +
                1
            : 0;
      });
    };
  }

  @override
  void refresh() async {
    setState(() {
      _deviceList =
          con.loadDevices().whenComplete(() => con.refreshChartListView());
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (c) => NewChartPage(refreshCharts: () {
                      setState(() {
                        rowCount = con.chartsList
                                .reduce((currentChart, nextChart) =>
                                    currentChart.row > nextChart.row
                                        ? currentChart
                                        : nextChart)
                                .row +
                            1;
                      });
                    })));
        break;
      case 1:
        if (con.editable) {
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          // var tmp = jsonEncode(con.chartsList);
          // prefs.setString("charts", tmp);

          setState(() {
            con.editable = false;
          });
        } else {
          setState(() {
            con.editable = true;
          });
        }
        con.refreshChartEditable();
        break;
      case 2:
        refresh();
        break;
      case 3:
        break;
    }
  }

  @override
  Widget buildWidget(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: lightGrey,
      appBar: AppBar(
        title: const Text('IoT Center Demo'),
        backgroundColor: darkBlue,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.screen_rotation),
          //   color: Colors.white,
          //   onPressed: () {
          //     Navigator.push(context,
          //         MaterialPageRoute(builder: (c) => const SensorsPage()));
          //   },
          // ),
          IconButton(
            icon: Icon(expandAppBar
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded),
            color: Colors.white,
            onPressed: () {
              setState(() {
                expandAppBar = !expandAppBar;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const Settings2Page()));
              refresh();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize:
              expandAppBar ? Size(size.width, 80) : Size(size.width, 0),
          child: Visibility(
            visible: expandAppBar,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 3,
                    child: FutureBuilder<dynamic>(
                        future: _deviceList,
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.done) {
                            return MyDropDown(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 5, 20),
                                hint: 'Select device',
                                value: _selectedDevice,
                                items: snapshot.data,
                                mapValue: 'deviceId',
                                label: 'deviceId',
                                onChanged: (value) {
                                  con.setSelectedDevice(value, false);
                                  _selectedDevice = con.selectedDevice != null
                                      ? con.selectedDevice!['deviceId']
                                      : '';
                                  con.refreshChartListView();
                                });
                          } else {
                            return MyDropDown(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 5, 20),
                                hint: 'Select device',
                                items: List.empty(),
                                mapValue: 'deviceId',
                                label: 'deviceId',
                                onChanged: (value) {});
                          }
                        }),
                  ),
                  Expanded(
                    flex: 2,
                    child: MyDropDown(
                      padding: const EdgeInsets.fromLTRB(5, 10, 10, 20),
                      hint: 'Time Range',
                      value: con.selectedTimeOption,
                      items: con.timeOptionsList,
                      mapValue: 'value',
                      label: 'label',
                      onChanged: (value) {
                        con.setSelectedTimeOption(value!);
                        con.refreshChartListView();
                      },
                      addIfMissing: true,
                    ),
                  ),
                ]),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: darkBlue,
        unselectedItemColor: darkBlue,
        // iconSize: 20,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        // landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(con.editable ? Icons.lock_open : Icons.lock_outline_rounded),
            label: 'Edit charts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.autorenew_rounded),
            label: 'Refresh',
          ),
        ],
        onTap: _onItemTapped,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ListView.builder(
            itemCount: rowCount,
            itemBuilder: (context, index) {
              var chartRow =
                  con.chartsList.where((e) => e.row == index).toList();
              List<Widget> chartWidgets = [];

              if (chartRow.isNotEmpty) {
                chartRow.sort(((a, b) => a.column.compareTo(b.column)));
                for (var chart in chartRow) {
                  chartWidgets.add(chart.widget);
                }
              }
              return Row(
                children: chartWidgets,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void onError(FlutterErrorDetails details) {
    super.onError(details);
  }
}
