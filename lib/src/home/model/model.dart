import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_config.dart';
import 'dart:developer' as developer;

class Model extends ModelMVC {
  factory Model([StateMVC? state]) => _this ??= Model._(state);
  Model._(StateMVC? state) : super(state);
  static Model? _this;

  final DeviceConfig _config = DeviceConfig();

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

  List<Chart> chartsList = [
    Chart(
        row: 1,
        column: 1,
        data: ChartData.gauge(
          measurement: "Temperature",
          endValue: 40,
          label: "Temperature",
          unit: '°C',
          startValue: 0,
        )),
    Chart(
        row: 1,
        column: 2,
        data: ChartData.gauge(
          measurement: "CO2",
          endValue: 3000,
          label: "CO2",
          unit: 'ppm',
          startValue: 400,
        )),
    Chart(
        row: 2,
        column: 1,
        data:
            ChartData.simple(measurement: 'TVOC', label: 'TVOC', unit: 'ppm')),
    Chart(
        row: 3,
        column: 1,
        data: ChartData.gauge(
            measurement: "Humidity",
            endValue: 100,
            label: "Humidity",
            unit: '%',
            startValue: 0)),
    Chart(
        row: 3,
        column: 2,
        data: ChartData.gauge(
            measurement: "Pressure",
            endValue: 1100,
            label: "Pressure",
            unit: 'hPa',
            startValue: 900))
  ];

  void selectedDeviceOnChange(String value) {
    selectedDevice =
        deviceList.firstWhere((device) => device['deviceId'] == value);
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
      var config = DeviceConfig();
      config.fromJson(jsonDecode(response.body));
      return config;
    } else {
      throw Exception('Failed to load device config.');
    }
  }

  Future removeDeviceConfig(String url) async {
    var response = await http.delete(Uri.parse(url));
    if (!response.isSuccess()) {
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

  Future writeEmulatedData(String deviceId, Function onProgress) async {
    var config = await fetchDeviceConfig2(iotCenterApi + "/api/env/$deviceId");

    var influxDBClient = createClient(config);

// calculate window to emulate writes
    var toTime =
        (DateTime.now().toUtc().millisecondsSinceEpoch / 60000).truncate() *
            60000;
    var lastTime = toTime - 30 * 24 * 60 * 60 * 1000;

// const getGPX = generateGPXData.bind(undefined, await fetchGPXData())
    var totalPoints = ((toTime - lastTime) / 60000);
    var pointsWritten = 0;

    if (totalPoints > 0) {
      var batchSize = 5000;

      var writeApi = influxDBClient.getWriteService(WriteOptions()
          .merge(batchSize: batchSize, precision: WritePrecision.ms
              // defaultTags: {"clientId": deviceId}));
              ));
      try {
        onProgress(0, 0, totalPoints);
        while (lastTime < toTime) {
          lastTime += 60000; // emulate next minute
          var point = Point('environment');
          point
              .addTag('clientId', deviceId)
              .addField('Temperature',
                  _generate(period: 30, min: 0, max: 40, time: lastTime))
              .addField('Humidity',
                  _generate(period: 90, min: 0, max: 99, time: lastTime))
              .addField('Pressure',
                  _generate(period: 20, min: 970, max: 1050, time: lastTime))
              //integer value
              .addField(
                  'CO2',
                  _generate(period: 1, min: 400, max: 3000, time: lastTime)
                      .toInt())
              //integer value
              .addField(
                  'TVOC',
                  _generate(period: 1, min: 250, max: 2000, time: lastTime)
                      .toInt())
              .addTag('TemperatureSensor', 'virtual_TemperatureSensor')
              .addTag('HumiditySensor', 'virtual_HumiditySensor')
              .addTag('PressureSensor', 'virtual_PressureSensor')
              .addTag('CO2Sensor', 'virtual_CO2Sensor')
              .addTag('TVOCSensor', 'virtual_TVOCSensor')
              .addTag('GPSSensor', 'virtual_GPSSensor')
              .time(lastTime);
          writeApi.batchWrite(point);
          pointsWritten++;
          if (pointsWritten % batchSize == 0) {
            await writeApi.flush();
            onProgress((pointsWritten / totalPoints) * 100, pointsWritten,
                totalPoints);
          }
        }
      } catch (e) {
        developer.log(e.toString(), level: 1000);
      } finally {
        await writeApi.flush();
        await writeApi.close();
        influxDBClient.close();
      }
      onProgress(100, pointsWritten, totalPoints);
    }

    return pointsWritten;
  }

  static const dayMillis = 24 * 60 * 60 * 1000;

  var _rnd = Random();

  num _generate(
      {required num period, int min = 0, max = 40, required num time}) {
    var dif = max - min;
// generate main value
    var periodValue =
        (dif / 4) * sin((((time / dayMillis) % period) / period) * 2 * pi);
// generate secondary value, which is lowest at noon
    var dayValue =
        (dif / 4) * sin(((time % dayMillis) / dayMillis) * 2 * pi - pi / 2);
    return (((min + dif / 2 + periodValue + dayValue + _rnd.nextDouble() * 10) /
        10));
  }
}
