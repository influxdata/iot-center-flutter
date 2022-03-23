import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

class MyApp extends AppStatefulWidgetMVC {
  const MyApp({Key? key}) : super(key: key);

  @override
  AppStateMVC createState() => _MyAppState();
}

class _MyAppState extends AppStateMVC<MyApp> {
  factory _MyAppState() => _this ??= _MyAppState._();

  _MyAppState._()
      : super(
          controller: AppController(),
          controllers: [
            Controller(),
          ],
        );
  static _MyAppState? _this;

  @override
  Widget buildApp(BuildContext context) => MaterialApp(
        theme: ThemeData(backgroundColor: const Color(0xFFF5F5F5)),
        home: FutureBuilder<bool>(
            future: initAsync(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data!) {
                  return HomePage(key: UniqueKey());
                } else {
                  return const Text('Failed to startup');
                }
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return Container(
                padding: const EdgeInsets.all(50),
                decoration: const BoxDecoration(gradient: pinkPurpleGradient),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/influxdata-logo.png"),
                        fit: BoxFit.contain),
                  ),
                  // child: const Center(
                  //     child: CircularProgressIndicator(
                  //   color: Colors.white,
                  // ))
                ),
              );
            }),
      );
}
