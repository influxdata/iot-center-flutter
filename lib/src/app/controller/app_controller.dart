import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class AppController extends ControllerMVC {
  factory AppController() => _this ??= AppController._();
  AppController._();
  static AppController? _this;

  @override
  Future<bool> initAsync() async {
    try {
      await Future.wait([
        // TODO: add reason why we wait 2 seconds
        Future.delayed(const Duration(seconds: 2), () {})
        // TODO: remove this quickfix - this probably doesn't stop http requests
      ]).timeout(const Duration(seconds: 5));
    } catch (e) {
      // TODO: escalation
    }
    return true;
  }

  @override
  bool onAsyncError(FlutterErrorDetails details) {
    return false;
  }
}
