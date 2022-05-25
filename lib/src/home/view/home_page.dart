import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, this.title = 'IoT Center Demo'}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

// TODO: move into some Dashboard utils file
int getRowCount(Dashboard dashboard) => dashboard.isNotEmpty
    ? dashboard
            .reduce((currentChart, nextChart) =>
                currentChart.row > nextChart.row ? currentChart : nextChart)
            .row +
        1
    : 0;

class _HomePageState extends StateMVC<HomePage> {
  _HomePageState() : super(Controller()) {
    con = controller as Controller;
  }

  late Controller con;
  String _selectedDevice = '';
  Future<void>? _deviceList;

  int? rowCount = 0;
  bool expandAppBar = false;
  updateRowCount() {
    setState(() {
      rowCount = getRowCount(con.dashboard);
    });
  }

  @override
  void initState() {
    super.initState();

    _deviceList = con.loadDevices().whenComplete(() => _selectedDevice =
        con.selectedDevice != null ? con.selectedDevice!['deviceId'] : '');
    updateRowCount();

    con.removeItemFromListView = updateRowCount;
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
                builder: (c) =>
                    NewChartPage(refreshCharts: updateRowCount)));
        break;
      case 1:
        if (con.editable) {
          con.saveDashboard();
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
          IconButton(
            icon: Icon(expandAppBar
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded),
            color: Colors.white,
            onPressed: () {
              expandAppBar = !expandAppBar;
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
        bottom: PreferredSize(
          preferredSize: Size(size.width, 80),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
              flex: 3,
              child: FutureBuilder<dynamic>(
                  future: _deviceList,
                  builder: (context, AsyncSnapshot<dynamic> snapshot) {
                    const padding = EdgeInsets.fromLTRB(10, 10, 5, 20);

                    if (snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.done) {
                      final data = snapshot.data;
                      late List<DropDownItem> devicesOptions = List.empty();
                      if (data is List) {
                        devicesOptions = data
                            .map((d) => DropDownItem(
                                label: d['deviceId'], value: d['deviceId']))
                            .toList();
                      }

                      return MyDropDown(
                          padding: padding,
                          hint: 'Select device',
                          value: _selectedDevice,
                          items: devicesOptions,
                          onChanged: (value) {
                            con.setSelectedDevice(value, false);
                            _selectedDevice = con.selectedDevice != null
                                ? con.selectedDevice!['deviceId']
                                : '';
                            con.refreshChartListView();
                          });
                    } else {
                      return MyDropDown(
                          padding: padding,
                          hint: 'Select device',
                          items: List.empty(),
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
                onChanged: (value) {
                  con.selectedTimeOption = value!;
                  con.refreshChartListView();
                },
                addIfMissing: true,
              ),
            ),
          ]),
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
            icon: Icon(
                con.editable ? Icons.lock_open : Icons.lock_outline_rounded),
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
                  con.dashboard.where((e) => e.row == index).toList();
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
