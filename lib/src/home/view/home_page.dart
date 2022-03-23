import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

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

  @override
  void initState() {
    super.initState();
    appState = rootState!;
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
            icon: const Icon(Icons.lock),
            color: Colors.white,
            onPressed: () {
              onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            color: Colors.white,
            onPressed: () {
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
                    items: con.getDeviceList(),
                    mapValue: 'deviceId',
                    label: 'deviceId', onChanged: (value) {
                  con.setSelectedDevice(value!);
                  con.refreshChartListView();
                })),
            Expanded(
              flex: 2,
              child: MyDropDown(
                  padding: const EdgeInsets.fromLTRB(5, 10, 10, 20),
                  hint: 'Time Range',
                  value: con.getSelectedTimeOption(),
                  items: con.getTimeOptionsList(),
                  mapValue: 'value',
                  label: 'label', onChanged: (value) {
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
              context, MaterialPageRoute(builder: (c) => const NewChartPage()));
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: con.getChartListView(),
      ),
    );
  }

  /// Supply an error handler for Unit Testing.
  @override
  void onError(FlutterErrorDetails details) {
    /// Error is now handled.
    super.onError(details);
  }

  void onRefresh() {}
}
