import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/home/model/default_dashboard.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:developer' as developer;


class Model extends ModelMVC {
  factory Model([StateMVC? state]) => _this ??= Model._(state);
  Model._(StateMVC? state) : super(state);
  static Model? _this;

  final DeviceConfig _config = DeviceConfig();

  initAsync() async {
    await _getIotCenterApi();
  }

  String iotCenterApi = '';
  List fieldList = [];
  Map<String, dynamic>? selectedDevice;
  String selectedTimeOption = "-1h";
  List deviceList = [];
  List<DropDownItem> timeOptionList = [
    DropDownItem(label: 'Past 5m', value: '-5m'),
    DropDownItem(label: 'Past 15m', value: '-15m'),
    DropDownItem(label: 'Past 1h', value: '-1h'),
    DropDownItem(label: 'Past 6h', value: '-6h'),
    DropDownItem(label: 'Past 1d', value: '-1d'),
    DropDownItem(label: 'Past 3d', value: '-3d'),
    DropDownItem(label: 'Past 7d', value: '-7d'),
    DropDownItem(label: 'Past 30d', value: '-30d'),
  ];
  List<DropDownItem> chartTypeList = [
    DropDownItem(label: 'Gauge chart', value: ChartType.gauge.toString()),
    DropDownItem(label: 'Simple chart', value: ChartType.simple.toString()),
  ];

  List<Chart> dashboard = [];

  /// contains list of available dashboard keys
  List<String> dashboardList = [];

  Map<String, dynamic>? selectedDeviceOnChange(String? value, bool setNull) {
    if (deviceList.isNotEmpty && !setNull) {
      selectedDevice = deviceList.firstWhere(
        (device) => device['deviceId'] == value,
        orElse: () {
          return deviceList.first;
        },
      );
    } else {
      selectedDevice = null;
    }
    loadFieldNames();
    return selectedDevice;
  }

  Future<void> _getIotCenterApi() async {
    var prefs = await SharedPreferences.getInstance();
    iotCenterApi = _fixLocalhost(prefs.getString("iot_center_url"));
  }

  Future<List<dynamic>> loadDevices() async {
    try {
      var response = await http.get(Uri.parse(iotCenterApi + "/api/devices"));
      if (response.statusCode == 200) {
        deviceList = jsonDecode(response.body);
        if (deviceList.isNotEmpty &&
            (selectedDevice == null ||
                deviceList
                    .where((element) =>
                        element['deviceId'] == selectedDevice!['deviceId'])
                    .isEmpty)) selectedDevice = deviceList.first;
        return deviceList;
      } else {
        throw Exception('Failed to load devices.');
      }
    } catch (e) {
      developer.log(e.toString());
      return [];
    }
  }

  Future<List<dynamic>> loadFieldNames() async {
    if (selectedDevice == null) return [];
    var deviceId = selectedDevice!['deviceId'];

    if (deviceId != null) {
      await fetchDeviceConfig(iotCenterApi + "/api/env/$deviceId");
      var _client = createClient(_config);
      var queryApi = _client.getQueryService();

      var fluxQuery = '''
              import "influxdata/influxdb/schema"
              schema.fieldKeys(
                      bucket: "${_client.bucket}",
                      predicate: (r) => r["_measurement"] == "environment" 
                                    and r["clientId"] == "${_config.id}")
          ''';

      try {
        var stream = await queryApi.query(fluxQuery);
        var result = await stream.toList();
        fieldList = result;
        return result;
      } catch (e) {
        developer.log(e.toString());
      } finally {
        _client.close();
      }
    }
    return [];
  }

//replace localhost with 10.0.2.2 for android devices
  String _fixLocalhost(String? url) {
    url ??= "http://localhost:5000";
    if (defaultTargetPlatform == TargetPlatform.android &&
        url.startsWith("http://localhost")) {
      return url.replaceAll("/localhost", "/10.0.2.2");
    }
    return url;
  }

  Future<DeviceConfig> fetchDeviceConfig(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _config.fromJson(jsonDecode(response.body));
      return _config;
    } else {
      throw Exception('Failed to load device config.');
    }
  }

  Future<DeviceConfig> fetchDeviceConfig2(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var config = DeviceConfig.fromJson(jsonDecode(response.body));
      return config;
    } else {
      throw Exception('Failed to load device config.');
    }
  }

  Future<DeviceConfig> get influxConfig =>
      fetchDeviceConfig2(iotCenterApi + "/api/env/mobile");

  Future removeDeviceConfig(Map<String, dynamic>? device) async {
    var deviceId = device != null ? device['deviceId'] : '';
    var response =
        await http.delete(Uri.parse(iotCenterApi + "/api/devices/$deviceId"));
    if (response.statusCode <= 300) {
      // deviceList.removeWhere((element) => element['deviceId'] == deviceId);
    } else {
      throw Exception('Failed to remove device config!');
    }
  }

  InfluxDBClient createClient(DeviceConfig config) {
    return InfluxDBClient(
        url: _fixLocalhost(config.influxUrl),
        token: config.influxToken,
        bucket: config.influxBucket,
        debug: false,
        org: config.influxOrg);
  }

  Future<List<FluxRecord>> fetchDeviceDataFieldMedian(
      String field, bool median) async {
    var deviceId = selectedDevice != null ? selectedDevice!['deviceId'] : null;
    var maxPastTime = selectedTimeOption;

    if (deviceId == null) {
      return [];
    }

    await fetchDeviceConfig(iotCenterApi + "/api/env/$deviceId");
    var _client = createClient(_config);
    var queryApi = _client.getQueryService();

    var aggregate = '1m';

    switch (maxPastTime) {
      case '-3d':
      case '-7d':
        aggregate = '30m';
        break;
      case '-30d':
        aggregate = '2h';
        break;
    }

    var fluxQuery = median
        ? '''
          import "influxdata/influxdb/v1"
          from(bucket: "${_client.bucket}")
              |> range(start: $maxPastTime)
              |> filter(fn: (r) => r.clientId == "${_config.id}" 
                                and r._measurement == "environment" 
                                and r["_field"] == "$field")
              |> mean()
          '''
        : '''
          import "influxdata/influxdb/v1"
          from(bucket: "${_client.bucket}")
              |> range(start: $maxPastTime)
              |> filter(fn: (r) => r.clientId == "${_config.id}" 
                               and r._measurement == "environment" 
                               and r["_field"] == "$field")
              |> keep(columns: ["_value", "_time"])
              |> aggregateWindow(column: "_value", every: $aggregate, fn: mean)
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } catch (e) {
      developer.log(e.toString());
      return [];
    } finally {
      _client.close();
    }
  }

  Future<List<FluxRecord>> fetchMeasurements(String url) async {
    var config = await fetchDeviceConfig2(url);
    var _client = createClient(config);
    var queryApi = _client.getQueryService();

    var fluxQuery = '''
      deviceData = from(bucket: "${_client.bucket}")
        |> range(start: -30d)
        |> filter(fn: (r) => r._measurement == "environment")
        |> filter(fn: (r) => r.clientId == "${config.id}")

      measurements = deviceData
        |> keep(columns: ["_field", "_value", "_time"])
        |> group(columns: ["_field"])

      counts    = measurements |> count()                
                               |> keep(columns: ["_field", "_value"]) 
                               |> rename(columns: {_value: "count"   })
      maxValues = measurements |> max  ()  
                               |> toFloat()  
                               |> keep(columns: ["_field", "_value"]) 
                               |> rename(columns: {_value: "maxValue"})
      minValues = measurements |> min  ()  
                               |> toFloat()  
                               |> keep(columns: ["_field", "_value"]) 
                               |> rename(columns: {_value: "minValue"})
      maxTimes  = measurements |> max  (column: "_time") 
                               |> keep(columns: ["_field", "_time" ]) 
                               |> rename(columns: {_time : "maxTime" })

      j = (tables=<-, t) => join(tables: {tables, t}, on:["_field"])

      counts
        |> j(t: maxValues)
        |> j(t: minValues)
        |> j(t: maxTimes)
        |> yield(name: "measurements")
  ''';
    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } finally {
      _client.close();
    }
  }

  //#region dasboard store influx

  Future<String?> _fetchDashboardInflux(String dashboardKey) async {
    var config = await influxConfig;
    var _client = createClient(config);
    var queryApi = _client.getQueryService();

    var fluxQuery = '''
      from(bucket: "${_client.bucket}") 
        |> range(start: 0) 
        |> filter(fn: (r) => r._measurement == "$measurementDashboardFlutter")
        |> filter(fn: (r) => r.key == "$dashboardKey")
        |> filter(fn: (r) => r._field == "data")
        |> last()
        |> filter(fn: (r) => r._value != "")
    ''';
    try {
      final stream = await queryApi.query(fluxQuery);
      final rows = await stream.toList();
      if (rows.isEmpty) return null;
      final dashboardEntry = rows.first;
      final dashboard = dashboardEntry["_value"];

      return dashboard;
    } finally {
      _client.close();
    }
  }

  Future<void> _writeDashboardInflux(
      String dashboardKey, String dashboardData) async {
    final config = await influxConfig;
    final influxDBClient = createClient(config);
    final writeApi = influxDBClient.getWriteService();
    final point = Point(measurementDashboardFlutter)
        .addTag("key", dashboardKey)
        .addField("data", dashboardData);
    await writeApi.write(point);
  }

  /// list of all dashboards
  Future<List<String>> _fetchDashboardKeysInflux() async {
    /*
    var config = await influxConfig;
    var _client = createClient(config);
    var queryApi = _client.getQueryService();

    var fluxQuery = '''
      from(bucket:${_client.bucket}) 
        |> range(start: 0) 
        |> filter(fn: (r) => r._measurement == ${measurementDashboardFlutter})
        |> last()
        |> filter(fn: (r) => r._value != "")
        |> keep(columns: ["key"])
    ''';
    try {
      final stream = await queryApi.query(fluxQuery);
      final rows = await stream.toList();

      // TODO: return
    } finally {
      _client.close();
    }
    */
    return Future.error("not implemented");
  }

  //#endregion dashboard store influx

  Future<Dashboard> _fetchDashboard(String dashboardKey) async {
    final stringDashboard = await _fetchDashboardInflux(dashboardKey);
    if (stringDashboard != null) {
      Iterable l = json.decode(stringDashboard);
      Dashboard dashboard =
          List<Chart>.from(l.map((model) => Chart.fromJson(model)));
      return dashboard;
    } else {
      return [];
    }
  }

  Future<List<String>> fetchDashboardList() => _fetchDashboardKeysInflux();

  Future<void> loadDashboard(String dashboardKey) async {
    final dashboardLoaded = await _fetchDashboard(dashboardKey);

    if (dashboardKey != defaultDashboardKey || dashboardLoaded.isNotEmpty) {
      dashboard = dashboardLoaded;
    } else {
      await storeDashboard(defaultDashboardKey, defaultDashboard);
      final dashboardLoaded = await _fetchDashboard(dashboardKey);
      dashboard = dashboardLoaded;
    }
  }

  /// updates dashboard List property
  Future<void> loadDashboardList() async {
    dashboardList = await fetchDashboardList();
  }

  Future<void> storeDashboard(
    String dashboardKey,
    Dashboard? dashboard,
  ) async {
    final dashboardData = dashboard != null ? jsonEncode(dashboard) : "";
    await _writeDashboardInflux(dashboardKey, dashboardData);
  }



  Future writeSensor(
      String sensorName, Map<String, double> fieldValueMap) async {
    final config = await influxConfig;
    final influxDBClient = createClient(config);

    final writeApi = influxDBClient.getWriteService();

    final point = Point('environment')
        // TODO(sensors): mobile name/id/type
        .addTag('clientId', "mobile");
    fieldValueMap.forEach((key, value) {
      final name = key != "" ? "${sensorName}_$key" : sensorName;
      point.addField(name, value);
    });

    // TODO(sensors): batch write
    writeApi.write(point);
  }

  Stream<Map<String, double>> get accelerometer =>
      SensorsPlatform.instance.accelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<Map<String, double>> get userAccelerometer =>
      SensorsPlatform.instance.userAccelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<Map<String, double>> get gyroscope =>
      SensorsPlatform.instance.gyroscopeEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<Map<String, double>> get magnetometer =>
      SensorsPlatform.instance.magnetometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<Map<String, double>> get battery async* {
    final battery = Battery();
    final Map<String, double> batteryLastState = {};
    bool changed = true;

    setField(String name, double value) {
      if (batteryLastState[name] != value) {
        changed = true;
        batteryLastState[name] = value;
      }
    }

    await for (var _ in Stream.periodic(const Duration(seconds: 1))) {
      final level = (await battery.batteryLevel).toDouble();
      setField("level", level);

      final state = (await battery.batteryState);
      if (state != BatteryState.unknown) {
        setField("charging", state == BatteryState.charging ? 1 : 0);
      }

      if (changed) {
        changed = false;
        yield Map.from(batteryLastState);
      }
    }
  }

  Stream<Map<String, double>> get temperature =>
      EnvironmentSensors().temperature.map((x) => {"": x});

  Stream<Map<String, double>> get humidity =>
      EnvironmentSensors().humidity.map((x) => {"": x});

  Stream<Map<String, double>> get light =>
      EnvironmentSensors().light.map((x) => {"": x});

  Stream<Map<String, double>> get pressure =>
      EnvironmentSensors().pressure.map((x) => {"": x});

  Stream<Map<String, double>> get geo =>
      Geolocator.getPositionStream().map((pos) {
        // TODO: more metrics
        return {"lat": pos.latitude, "lon": pos.longitude, "acc": pos.accuracy};
      });

  Future<Map<String, Stream<Map<String, double>>>> availableSensors() async {
    final Map<String, Stream<Map<String, double>>> sensors = {};
    sensors["Accelerometer"] = accelerometer;
    sensors["UserAccelerometer"] = userAccelerometer;
    sensors["Magnetometer"] = magnetometer;
    sensors["Battery"] = battery;

    final es = EnvironmentSensors();
    if (await es.getSensorAvailable(SensorType.AmbientTemperature)) {
      sensors["Temperature"] = temperature;
    }
    if (await es.getSensorAvailable(SensorType.Humidity)) {
      sensors["Humidity"] = humidity;
    }
    if (await es.getSensorAvailable(SensorType.Light)) {
      sensors["Light"] = light;
    }
    if (await es.getSensorAvailable(SensorType.Pressure)) {
      sensors["Pressure"] = pressure;
    }
    if (await Geolocator.isLocationServiceEnabled()) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // TODO: ask when clicked on switch instead
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        sensors["Geo"] = geo;
      }
    }

    return sensors;
  }
}
