import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_config.dart';
import 'dart:developer' as developer;

class Model extends ModelMVC {
  factory Model([StateMVC? state]) => _this ??= Model._(state);
  Model._(StateMVC? state) : super(state);
  static Model? _this;

  final DeviceConfig _config = DeviceConfig();
  late ChartListView chartListView;
  String iotCenterApi = '';
  List fieldList = [];
  Map<String, dynamic>? selectedDevice;
  String selectedTimeOption = "-1h";
  List deviceList = [];
  List timeOptionList = [
    {"label": 'Past 5m', "value": '-5m'},
    {"label": 'Past 15m', "value": '-15m'},
    {"label": 'Past 1h', "value": '-1h'},
    {"label": 'Past 6h', "value": '-6h'},
    {"label": 'Past 1d', "value": '-1d'},
    {"label": 'Past 3d', "value": '-3d'},
    {"label": 'Past 7d', "value": '-7d'},
    {"label": 'Past 30d', "value": '-30d'},
  ];
  List chartTypeList = [
    {"label": 'Gauge chart', "value": ChartType.gauge},
    {"label": 'Simple chart', "value": ChartType.simple},
  ];

  void selectedDeviceOnChange(String value) {
    selectedDevice = deviceList.firstWhere((device) => device.id == value);
    loadFieldNames();
  }

  Future<void> _getIotCenterApi() async {
    var prefs = await SharedPreferences.getInstance();
    iotCenterApi = _fixLocalhost(prefs.getString("iot_center_url"));
  }

  Future<List<dynamic>> loadDevices() async {
    await _getIotCenterApi();
    try {
      var response = await http.get(Uri.parse(iotCenterApi + "/api/devices"));
      if (response.statusCode == 200) {
        deviceList = jsonDecode(response.body);
        if (deviceList.isNotEmpty) selectedDevice = deviceList.first;
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
        print(e);
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

  Future<void> fetchDeviceConfig(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      _config.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load device config.');
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

  Future<List<FluxRecord>> fetchDeviceDataFieldMedian(String? deviceId,
      String field, String maxPastTime, String iotCenterApi) async {
    if (deviceId == null) {
      return [];
    }

    await fetchDeviceConfig(iotCenterApi + "/api/env/$deviceId");
    var _client = createClient(_config);
    var queryApi = _client.getQueryService();

    var fluxQuery = '''
          import "influxdata/influxdb/v1"
          from(bucket: "${_client.bucket}")
              |> range(start: $maxPastTime)
              |> filter(fn: (r) => r.clientId == "${_config.id}")
              |> filter(fn: (r) => r._measurement == "environment")
              |> filter(fn: (r) => r["_field"] == "$field")
              |> keep(columns: ["_value", "_time"])
              |> toFloat()
              |> median()
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } catch (e) {
      print(e);
      return [];
    } finally {
      _client.close();
    }
  }

  Future<List<FluxRecord>> fetchDeviceDataField(String? deviceId, String field,
      String maxPastTime, String iotCenterApi) async {
    if (deviceId == null) {
      return [];
    }
    await fetchDeviceConfig(iotCenterApi + "/api/env/$deviceId");
    var _client = createClient(_config);

    // var queryPing = _client.getPingApi();
    //var tmp = await queryPing.getPingWithHttpInfo();

    var queryApi = _client.getQueryService();
    var fluxQuery = '''
          import "influxdata/influxdb/v1"
          from(bucket: "${_client.bucket}")
              |> range(start: $maxPastTime)
              |> filter(fn: (r) => r.clientId == "${_config.id}")
              |> filter(fn: (r) => r._measurement == "environment")
              |> filter(fn: (r) => r["_field"] == "$field")
              |> keep(columns: ["_value", "_time"])
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } finally {
      _client.close();
    }
  }

  Future<List<FluxRecord>> fetchMeasurements(
      String deviceId, String iotCenterApi) async {
    await fetchDeviceConfig(iotCenterApi + "/api/env/$deviceId");
    var _client = createClient(_config);
    var queryApi = _client.getQueryService();
    var fluxQuery = '''
          import "math"
          from(bucket: "${_client.bucket}")
              |> range(start: -30d)
              |> filter(fn: (r) => r._measurement == "environment")
              |> filter(fn: (r) => r.clientId == "${_config.id}")
              |> toFloat()
              |> group(columns: ["_field"])
              |> reduce(
                  fn: (r, accumulator) => ({
                    maxTime: (if r._time>accumulator.maxTime then r._time 
                    else accumulator.maxTime),
                    maxValue: (if r._value>accumulator.maxValue then r._value 
                    else accumulator.maxValue),
                    minValue: (if r._value<accumulator.minValue then r._value 
                    else accumulator.minValue),
                    count: accumulator.count + 1.0
                  }),
                identity: {maxTime: 1970-01-01, count: 0.0, 
                  minValue: math.mInf(sign: 1), 
                  maxValue: math.mInf(sign: -1)}
        )
  ''';
    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } finally {
      _client.close();
    }
  }
}
