import 'package:flutter/foundation.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const logoTime = const Duration(seconds: 2);

final String platformStr = defaultTargetPlatform == TargetPlatform.android
    ? "android"
    : defaultTargetPlatform == TargetPlatform.iOS
        ? "ios"
        : "flutter";

class AppController extends ControllerMVC {
  factory AppController() => _this ??= AppController._();
  AppController._();
  static AppController? _this;

  final sensorsSubscriptionManager = SensorsSubscriptionManager();
  late final List<SensorInfo> sensors;

  String clientId = "";
  Future<void> saveClientId() async {
    var prefs = await SharedPreferences.getInstance();

    prefs.setString("clientId", clientId);
  }

  Future<void> loadClientId() async {
    var prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey("clientId")) {
      clientId = prefs.getString("clientId")!;
    } else {
      clientId = "$platformStr-" +
          DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(3);
      await saveClientId();
    }
  }

  Future<void> initSensors() async {
    sensors = await Sensors().sensors;
  }

  @override
  Future<bool> initAsync() async {
    try {
      await Future.wait([
        Future.delayed(logoTime, () {}),
        initSensors(),
        loadClientId()
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
