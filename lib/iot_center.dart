import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:influxdb_client/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

//replace localhost with 10.0.2.2 for android devices
String _fixLocalhost(String? url) {
  url ??= "http://localhost:5000";
  if (defaultTargetPlatform == TargetPlatform.android &&
      url.startsWith("http://localhost")) {
    return url.replaceAll("/localhost", "/10.0.2.2");
  }
  return url;
}

Future<String> _getIotCenterApi() async {
  var prefs = await SharedPreferences.getInstance();
  return _fixLocalhost(prefs.getString("iot_center_url"));
}

InfluxDBClient _createClient(DeviceConfig config) {
  return InfluxDBClient(
      url: _fixLocalhost(config.influxUrl),
      token: config.influxToken,
      bucket: config.influxBucket,
      debug: false,
      org: config.influxOrg);
}

class DeviceConfig {
  String influxUrl;
  String influxOrg;
  String influxToken;
  String influxBucket;
  String createdAt;
  String id;

  DeviceConfig.fromJson(Map<String, dynamic> json)
      : influxUrl = json['influx_url'],
        influxOrg = json['influx_org'],
        influxToken = json['influx_token'],
        influxBucket = json['influx_bucket'],
        createdAt = json['createdAt'],
        id = json['id'];

  Map<String, dynamic> toJson() => {
        'influx_url': influxUrl,
        'influx_org': influxOrg,
        'influx_token': influxToken,
        'influx_bucket': influxBucket,
        'createdAt': createdAt,
        'id': id,
      };
}

Future<List<dynamic>> fetchDevices() async {
  var response =
      await http.get(Uri.parse(await _getIotCenterApi() + "/api/devices"));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load devices.');
  }
}

Future<DeviceConfig> fetchDeviceConfig(String deviceId) async {
  var response = await http
      .get(Uri.parse(await _getIotCenterApi() + "/api/env/$deviceId"));
  if (response.statusCode == 200) {
    return DeviceConfig.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load device config.');
  }
}

Future<List<FluxRecord>> fetchDeviceDataFieldLast(
    String? deviceId, String field, String maxPastTime) async {
  if (deviceId == null) {
    return [];
  }
  var config = await fetchDeviceConfig(deviceId);
  var influxDBClient = _createClient(config);
  var queryApi = influxDBClient.getQueryService();

  var fluxQuery = '''
import "influxdata/influxdb/v1"
from(bucket: "${config.influxBucket}")
|> range(start: $maxPastTime)
|> filter(fn: (r) => r.clientId == "${config.id}")
|> filter(fn: (r) => r._measurement == "environment")
|> filter(fn: (r) => r["_field"] == "$field")
|> keep(columns: ["_value", "_time"])
|> last()
''';
  try {
    var stream = await queryApi.query(fluxQuery);
    return await stream.toList();
  } finally {
    influxDBClient.close();
  }
}

Future<List<FluxRecord>> fetchDeviceDataField(
    String? deviceId, String field, String maxPastTime) async {
  if (deviceId == null) {
    return [];
  }
  var config = await fetchDeviceConfig(deviceId);
  var influxDBClient = _createClient(config);

  var queryApi = influxDBClient.getQueryService();

  var fluxQuery = '''
import "influxdata/influxdb/v1"
from(bucket: "${config.influxBucket}")
|> range(start: $maxPastTime)
|> filter(fn: (r) => r.clientId == "${config.id}")
|> filter(fn: (r) => r._measurement == "environment")
|> filter(fn: (r) => r["_field"] == "$field")
|> keep(columns: ["_value", "_time"])
''';

  try {
    var stream = await queryApi.query(fluxQuery);
    return await stream.toList();
  } finally {
    influxDBClient.close();
  }
}

Future<List<FluxRecord>> fetchMeasurements(String deviceId) async {
  var config = await fetchDeviceConfig(deviceId);
  var influxDBClient = _createClient(config);
  var queryApi = influxDBClient.getQueryService();
  var fluxQuery = '''
      import "math"
      from(bucket: "${config.influxBucket}")
        |> range(start: -30d)
        |> filter(fn: (r) => r._measurement == "environment")
        |> filter(fn: (r) => r.clientId == "${config.id}")
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
    influxDBClient.close();
  }
}

Future writeEmulatedData(String deviceId, Function onProgress) async {
  var config = await fetchDeviceConfig(deviceId);

  var influxDBClient = _createClient(config);

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

    var writeApi = influxDBClient.getWriteService(
        WriteOptions().merge(batchSize: batchSize, precision: WritePrecision.ms
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
          onProgress(
              (pointsWritten / totalPoints) * 100, pointsWritten, totalPoints);
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

const dayMillis = 24 * 60 * 60 * 1000;
var _rnd = Random();

num _generate({required num period, int min = 0, max = 40, required num time}) {
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
