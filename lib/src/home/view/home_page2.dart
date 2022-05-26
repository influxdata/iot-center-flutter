import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({Key? key, this.title = 'IoT Center Demo'}) : super(key: key);
  final String title;

  @override
  State<StatefulWidget> createState() => _HomePage2State();
}

class _HomePage2State extends StateMVC<HomePage2> {
  _HomePage2State() : super(HomePageController()) {
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
    var size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: lightGrey,
      appBar: AppBar(
        title: const Text('IoT Center Demo'),
        backgroundColor: darkBlue,
        actions: [
          IconButton(
            icon: Icon(con.expandAppBar
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded),
            color: Colors.white,
            onPressed: () {
              setState(() {
                con.expandAppBar = !con.expandAppBar;
              });
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
          preferredSize:
              con.expandAppBar ? Size(size.width, 80) : const Size(0, 0),
          child: Visibility(
            visible: con.expandAppBar,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    flex: 3,
                    child: FutureBuilder<dynamic>(
                        future: con.futureDeviceList,
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          const padding = EdgeInsets.fromLTRB(10, 10, 5, 20);

                          if (snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.done) {
                            final data = snapshot.data;
                            late List<DropDownItem> devicesOptions =
                                List.empty();
                            if (data is List) {
                              devicesOptions = data
                                  .map((d) => DropDownItem(
                                      label: d['deviceId'],
                                      value: d['deviceId']))
                                  .toList();
                            }

                            return MyDropDown(
                                padding: padding,
                                hint: 'Select device',
                                value: con.selectedDevice?.id,
                                items: devicesOptions,
                                onChanged: (value) {
                                  con.selectedDeviceOnChange(value);
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: darkBlue,
        unselectedItemColor: darkBlue,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(con.editableCharts
                ? Icons.lock_open
                : Icons.lock_outline_rounded),
            label: 'Edit charts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.autorenew_rounded),
            label: 'Refresh',
          ),
        ],
        onTap: con.onItemTapped,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ListView.builder(
            itemCount: con.rowCount,
            itemBuilder: (context, index) {
              return con.buildChartListViewRow(context, index);
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
