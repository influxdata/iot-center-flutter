import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

const logoTime = const Duration(seconds: 2);

class AppController extends ControllerMVC {
  factory AppController() => _this ??= AppController._();
  AppController._();
  static AppController? _this;

  final sensorsSubscriptionManager = SensorsSubscriptionManager();
  late final List<SensorInfo> sensors;

  Future<void> initSensors() async {
    sensors = await Sensors().sensors;
  }

  @override
  Future<bool> initAsync() async {
    try {
      await Future.wait([
        Future.delayed(logoTime, () {}),
        initSensors(),
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
