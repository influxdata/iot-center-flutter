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
  late AppStateMVC appState;
  int? rowCount = 0;

  @override
  void initState() {
    super.initState();
    appState = rootState!;
    rowCount = con.chartsList
            .reduce((currentChart, nextChart) =>
                currentChart.row > nextChart.row ? currentChart : nextChart)
            .row +
        1;

    con.removeItemFromListView = () {
      setState(() {
        rowCount = con.chartsList
            .reduce((currentChart, nextChart) =>
        currentChart.row > nextChart.row
            ? currentChart
            : nextChart)
            .row +
            1;
      });
    };
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
            icon: con.editable
                ? const Icon(Icons.lock_open)
                : const Icon(Icons.lock),
            color: Colors.white,
            onPressed: () async {
              if (con.editable) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                var tmp = jsonEncode(con.chartsList);
                prefs.setString("charts", tmp);

                setState(() { con.editable = false;});
              }
              else{
                setState(() { con.editable = true;});
              }
              con.refreshChartEditable();
            },
          ),
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            color: Colors.white,
            onPressed: () {
              // con.refreshChartListView();
              con.refreshChartListView();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.white,
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const SettingsPage()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size(size.width, 80),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
                flex: 3,
                child: MyDropDown(
                    padding: const EdgeInsets.fromLTRB(10, 10, 5, 20),
                    hint: 'Select device',
                    items: con.deviceList,
                    mapValue: 'deviceId',
                    label: 'deviceId',
                    onChanged: (value) {
                      con.setSelectedDevice(value!);
                      con.refreshChartListView();
                    })),
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
                  }),
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: darkBlue,
        child: const Icon(Icons.add),
        onPressed: () {
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
        },
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
