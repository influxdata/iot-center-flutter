import 'package:iot_center_flutter_mvc/src/model.dart';

class Device {
  String influxUrl = '';
  String influxOrg = '';
  String influxToken = '';
  String influxBucket = '';
  String createdAt = '';
  String id = '';
  String key = '';
  String dashboardKey = '';
  String type = '';

  List<Chart>? _dashboard;
  List<Chart>? get dashboard => _dashboard;
  set dashboard(value) => _dashboard = value;

  String get tokenSubstring => influxToken.toString().substring(0, 3) + "...";

  Device(this.id, this.createdAt, this.key, this.influxOrg, this.influxUrl,
      this.influxBucket, this.influxToken, this.dashboardKey, this.type);
}
