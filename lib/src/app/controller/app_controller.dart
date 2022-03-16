import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';


class AppController extends ControllerMVC {
  factory AppController() => _this ??= AppController._();
  AppController._();
  static AppController? _this;

  @override
  Future<bool> initAsync() async {
    var con = Controller();
    await con.loadDevices();
    return Future.delayed(const Duration(seconds: 2), () {
      return true;
    });
  }

  @override
  bool onAsyncError(FlutterErrorDetails details) {
    return false;
  }
}
