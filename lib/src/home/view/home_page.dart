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

    var timeDropDown = MyDropDown(
        const EdgeInsets.fromLTRB(5, 10, 10, 20),
        'Time Range',
        con.getSelectedTimeOption(),
        con.getTimeOptionsList(),
        'value',
        'label',
        (value) {});

    return Container(
      height: size.height,
      decoration: const BoxDecoration(color: Color.fromRGBO(250, 250, 250, 1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            height: 190, //size.height * 0.28,
            decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomCenter,
                  stops: [
                    0,
                    0.8,
                  ],
                  colors: [
                    Color.fromRGBO(211, 9, 113, 1),
                    Color.fromRGBO(155, 42, 255, 1),
                  ],
                )),
          ),
          Scaffold(
              extendBodyBehindAppBar: false,
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('IoT Center Demo'),
                elevation: 0,
                backgroundColor: Colors.transparent,
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
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const SettingsPage()));
                    },
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const AddChartPage()));
                },
              ),
              body: Stack(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                            flex: 3,
                            child: MyDropDown(
                                const EdgeInsets.fromLTRB(10, 10, 5, 20),
                                'Select device',
                                '',
                                con.getDeviceList(),
                                'deviceId',
                                'deviceId',
                                (value) {})),
                        Expanded(
                          flex: 2,
                          child: timeDropDown,
                        ),
                      ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 84.0),
                    child: con.getChartListView(),
                  ),
                ],
              )),
        ],
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
