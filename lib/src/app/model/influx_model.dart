import 'dart:convert';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'dart:async';

import 'dart:developer' as developer;

import 'package:sensors_plus/sensors_plus.dart';

const measurementDashboardFlutter = "dashboard-flutter";
const defaultDashboardKey = "default";
typedef Dashboard = List<Chart>;

class InfluxModel extends ModelMVC {
  factory InfluxModel([StateMVC? state]) => _this ??= InfluxModel._(state);
  InfluxModel._(StateMVC? state) : super(state);
  static InfluxModel? _this;

  //#region Client

  /// Create a new client for a InfluxDB with default values.
  final InfluxDBClient client = InfluxDBClient(
      url: "http://influxdb_v2:8086",
      token: "my-token",
      bucket: "iot_center",
      debug: false,
      org: "my-org");

  /// Checks the status of InfluxDB instance and version of InfluxDB.
  Future<void> checkClient(InfluxDBClient client) async {
    await client.getPingApi().getPing();
  }

  //#endregion Client

  //#region Organizations

  Future<String?> getOrganizationId() async {
    var _influxDBClient = client.clone();
    var orgList = await _influxDBClient.getOrganizationsApi().getOrgs();
    try {
      return orgList.orgs!.first.id;
    } catch (e) {
      developer.log('Failed to load organization Id. - ${e.toString()}');
      throw Exception('Failed to load organization Id.');
    } finally {
      _influxDBClient.close();
    }
  }

  //#endregion Organizations

  //#region Buckets

  Future<String?> getBucketId(String bucketName) async {
    var _influxDBClient = client.clone();

    try {
      var buckets = await _influxDBClient.getBucketsApi().getBuckets();
      var bucket =
          buckets.buckets!.firstWhere((element) => element.name == bucketName);
      return bucket.id;
    } catch (e) {
      developer.log('Failed to load organization Id. - ${e.toString()}');
      throw Exception('Failed to load organization Id.');
    } finally {
      _influxDBClient.close();
    }
  }

  //#endregion Buckets

  //#region Devices

  ///
  /// Gets devices without empty/unknown key (InfluxDB authorization is not
  /// associated).
  ///
  Future<List<dynamic>> fetchDevices() async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    developer.log('Fetch devices from bucket - ${_influxDBClient.bucket}');

    var fluxQuery = '''
          from(bucket: "${_influxDBClient.bucket}")
              |> range(start: -30d)
              |> filter(fn: (r) => r["_measurement"] == "deviceauth"
                               and r["_field"] == "key")
              |> last()
              |> filter(fn: (r) => r["_value"] != "")
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } catch (e) {
      developer.log('Failed to load devices. - ${e.toString()}');
      // throw Exception('Failed to load devices.');
      return [];
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Gets first device of this stream matching [deviceId].
  /// Can return device with empty/unknown key (without associated InfluxDB
  /// authorization)
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<Device> fetchDevice(String deviceId) async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    developer
        .log('Fetch device $deviceId from bucket - ${_influxDBClient.bucket}');

    var fluxQuery = '''
          from(bucket: "${_influxDBClient.bucket}")
              |> range(start: -30d)
              |> filter(fn: (r) => r["_measurement"] == "deviceauth" 
                               and r.deviceId == "$deviceId")
              |> last()
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      var result = await stream.toList();

      var keyRec = result.firstWhere((element) => element['_field'] == 'key',
          orElse: () => FluxRecord(-1));
      var createdAtRec = result.firstWhere(
          (element) => element['_field'] == 'createdAt',
          orElse: () => FluxRecord(-1));
      var dashboardKeyRec = result.firstWhere(
          (element) => element['_field'] == 'dashboardKey',
          orElse: () => FluxRecord(-1));

      var key = keyRec.containsKey("_value") ? keyRec['_value'] : "";
      var createdAt =
          createdAtRec.containsKey("_value") ? createdAtRec['_value'] : "";
      var dashboardKey = dashboardKeyRec.containsKey("_value")
          ? dashboardKeyRec['_value']
          : "";

      return Device(
          deviceId,
          createdAt,
          key,
          _influxDBClient.org!,
          _influxDBClient.url!,
          _influxDBClient.bucket!,
          _influxDBClient.token!,
          dashboardKey);
    } catch (e) {
      developer.log('Failed to load device $deviceId. - ${e.toString()}');
      throw Exception('Failed to load device $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Gets first device of this stream matching [deviceId] with
  /// associated dashboard.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<Device> fetchDeviceWithDashboard(String deviceId) async {
    var device = await fetchDevice(deviceId);
    device.dashboard = await fetchDashboard(device.dashboardKey);
    return device;
  }

  ///
  /// Gets all dashboards from influx.
  ///
  Future<List<dynamic>> fetchDashboards() async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    developer.log('Fetch dashboards from bucket - ${_influxDBClient.bucket}');

    var fluxQuery = '''
          from(bucket: "${_influxDBClient.bucket}")
              |> range(start: -30d)
              |> filter(fn: (r) => r["_measurement"] == "$measurementDashboardFlutter")
              |> last()
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } catch (e) {
      developer.log('Failed to load dashboards. - ${e.toString()}');
      return [];
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Gets first dashboard of this stream matching [dashboardKey].
  ///
  /// Parameters:
  /// * [String] dashboardKey: dashboard identifier
  ///
  Future<dynamic> fetchDashboard(String dashboardKey) async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    developer.log('Fetch dashboard $dashboardKey');

    var fluxQuery = '''
      from(bucket: "${_influxDBClient.bucket}") 
        |> range(start: 0) 
        |> filter(fn: (r) => r._measurement == "$measurementDashboardFlutter")
        |> filter(fn: (r) => r.key == "$dashboardKey")
        |> filter(fn: (r) => r._field == "data")
        |> last()
        |> filter(fn: (r) => r._value != "")
    ''';

    try {
      final stream = await queryApi.query(fluxQuery);
      final result = await stream.toList();
      final stringDashboard = result.first["_value"].toString();

      if (stringDashboard.isNotEmpty) {
        var l = json.decode(stringDashboard);
        var dashboard =
            List<Chart>.from(l.map((model) => Chart.fromJson(model)));
        return dashboard;
      }

      return null;
    } catch (e) {
      developer.log('Failed to load dashboard. - ${e.toString()}');
      return null;
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Creates a new dashboard.
  ///
  /// Parameters:
  /// * [String] dashboardKey: dashboard identifier
  ///
  Future<void> createDashboard(
      String dashboardKey, String dashboardData) async {
    developer.log('Create dashboard $dashboardKey');

    var _influxDBClient = client.clone();
    var writeApi = _influxDBClient.getWriteService();

    var point = Point(measurementDashboardFlutter)
        .addTag("key", dashboardKey)
        .addField("data", dashboardData);

    try {
      await writeApi.write(point);
    } catch (e) {
      developer
          .log('Failed to create dashboard $dashboardKey. - ${e.toString()}');
      throw Exception('Failed to create dashboard $dashboardKey.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Pair dashboard with device.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  /// * [String] dashboardKey: dashboard identifier
  ///
  Future<void> pairDeviceDashboard(String deviceId, String dashboardKey) async {
    developer.log('Pair dashboard $dashboardKey with $deviceId.');

    var _influxDBClient = client.clone();
    var writeApi = _influxDBClient.getWriteService();

    var point = Point('deviceauth')
        .addTag('deviceId', deviceId)
        .addField('dashboardKey', dashboardKey);

    try {
      await writeApi.write(point);
    } catch (e) {
      developer.log(
          'Failed to pair dashboard $dashboardKey with $deviceId. - ${e.toString()}');
      throw Exception('Failed to pair dashboard $dashboardKey with $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Return [List] of Field Names of specified device
  ///
  /// Parameters:
  /// * [Map<String, dynamic>?] deviceId
  ///
  Future<List<FluxRecord>> fetchFieldNames(String deviceId) async {
    if (deviceId.isEmpty) return [];

    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    var fluxQuery = '''
              import "influxdata/influxdb/schema"
              schema.fieldKeys(
                      bucket: "${_influxDBClient.bucket}",
                      predicate: (r) => r["_measurement"] == "environment" 
                                    and r["clientId"] == "$deviceId")
          ''';

    try {
      var stream = await queryApi.query(fluxQuery);
      return await stream.toList();
    } catch (e) {
      developer
          .log('Failed to load field names for $deviceId. - ${e.toString()}');
      throw Exception('Failed to load field names for $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Return [List] of Measurements of specified device
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<List<FluxRecord>> fetchMeasurements(String deviceId) async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    var fluxQuery = '''
      deviceData = from(bucket: "${_influxDBClient.bucket}")
        |> range(start: -30d)
        |> filter(fn: (r) => r._measurement == "environment"
                         and r.clientId == "$deviceId")

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
    } catch (e) {
      developer
          .log('Failed to load measurements for $deviceId. - ${e.toString()}');
      throw Exception('Failed to load measurements for $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Creates a new device with associated InfluxDB authorization.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<DeviceConfig> createDevice(String deviceId) async {
    developer.log('Create device $deviceId');

    var _influxDBClient = client.clone();
    var writeApi = _influxDBClient.getWriteService();
    final createdAt = DateTime.now().toIso8601String();

    var point = Point('deviceauth')
        .addTag('deviceId', deviceId)
        .addField('createdAt', createdAt);

    try {
      await writeApi.write(point);
      var authorization = await _createDeviceAuthorization(deviceId);
      return DeviceConfig.withParams(deviceId, createdAt, _influxDBClient.org!,
          _influxDBClient.url!, _influxDBClient.bucket!, authorization.token!);
    } catch (e) {
      developer.log('Failed to create device $deviceId. - ${e.toString()}');
      throw Exception('Failed to create device $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Creates and assigns authorization to the specified device.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<Authorization> _createDeviceAuthorization(String deviceId) async {
    developer.log('Create device Authorization for device $deviceId');

    var authorization = await _createIoTAuthorization(deviceId);

    var _influxDBClient = client.clone();
    var writeApi = _influxDBClient.getWriteService();

    var point = Point('deviceauth')
        .addTag('deviceId', deviceId)
        .addField('key', authorization.id)
        .addField('token', authorization.token);

    try {
      await writeApi.write(point);
      return authorization;
    } catch (e) {
      developer.log(
          'Failed to create device Authorization $deviceId. - ${e.toString()}');
      throw Exception('Failed to create device Authorization $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// Creates authorization for a specified deviceId
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<Authorization> _createIoTAuthorization(String deviceId) async {
    developer.log('Create IoT Authorization for device $deviceId');

    var orgId = await getOrganizationId();

    var _influxDBClient = client.clone();
    var authorizationApi = _influxDBClient.getAuthorizationsApi();

    var bucketId = await getBucketId(_influxDBClient.bucket!);
    var org = _influxDBClient.org;

    var permissions = [
      Permission(
          action: PermissionActionEnum.read,
          resource: Resource(
              type: ResourceTypeEnum.buckets,
              id: bucketId,
              orgID: orgId,
              org: org)),
      Permission(
          action: PermissionActionEnum.write,
          resource: Resource(
              type: ResourceTypeEnum.buckets,
              id: bucketId,
              orgID: orgId,
              org: org)),
    ];

    try {
      AuthorizationPostRequest request = AuthorizationPostRequest(
          orgID: orgId,
          description: 'IoTCenterDevice: ' + deviceId,
          permissions: permissions);
      return await authorizationApi.postAuthorizations(request);
    } catch (e) {
      developer.log(
          'Failed to create IoT Authorization $deviceId. - ${e.toString()}');
      throw Exception('Failed to create IoT Authorization $deviceId.');
    } finally {
      _influxDBClient.close();
    }
  }

  ///
  /// If [deleteWithData] is true, will delete device authorization and all
  /// data associated to device. Else delete only device authorization.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  /// * [bool] deleteWithData
  ///
  Future<void> deleteDevice(String deviceId, bool deleteWithData) async {
    var _influxDBClient = client.clone();
    var deleteApi = _influxDBClient.getDeleteService();

    if (deleteWithData) {
      try {
        await deleteApi.delete(
            predicate: 'clientId="$deviceId"',
            start: DateTime(1970).toUtc(),
            stop: DateTime.now().toUtc(),
            bucket: _influxDBClient.bucket,
            org: _influxDBClient.org);
      } catch (e) {
        developer.log(e.toString());
        throw Exception('Failed to delete data.');
      } finally {
        _influxDBClient.close();
      }
    }

    await _removeDeviceAuthorization(deviceId);
  }

  ///
  /// Removes authorization from a specified device including InfluxDB
  /// authorization.
  ///
  /// Parameters:
  /// * [String] deviceId: client identifier
  ///
  Future<bool> _removeDeviceAuthorization(String deviceId) async {
    developer.log('Remove device Authorization for device $deviceId');

    var device = await fetchDevice(deviceId);

    if (device.key.isNotEmpty) {
      await _deleteIoTAuthorization(device.key);

      var _influxDBClient = client.clone();
      var writeApi = _influxDBClient.getWriteService();

      var point = Point('deviceauth')
          .addTag('deviceId', deviceId)
          .addField('key', '')
          .addField('token', '');

      try {
        await writeApi.write(point);
        return true;
      } catch (e) {
        developer.log(
            'Failed to remove device Authorization $deviceId. - ${e.toString()}');
        throw Exception('Failed to remove device Authorization $deviceId.');
      } finally {
        _influxDBClient.close();
      }
    } else if (device.key.isEmpty) {
      developer.log('$deviceId authorization is already removed.');
      return false;
    } else {
      developer.log('$deviceId is not available.');
      return false;
    }
  }

  ///
  /// Deletes authorization for a supplied InfluxDB key
  ///
  /// Parameters:
  /// * [String] key: InfluxDB id of the authorization
  ///
  Future<void> _deleteIoTAuthorization(String key) async {
    developer.log('Delete IoT Authorization.');

    var _influxDBClient = client.clone();
    var authorizationApi = _influxDBClient.getAuthorizationsApi();

    try {
      await authorizationApi.deleteAuthorizationsID(key);
    } catch (e) {
      developer.log('Failed to delete IoT Authorization. - ${e.toString()}');
      throw Exception('Failed to delete IoT Authorization.');
    } finally {
      _influxDBClient.close();
    }
  }

  //#endregion Devices

  Future<List<FluxRecord>> fetchDeviceDataFieldMedian(
      String field, bool median, Device device, String maxTime) async {
    var _influxDBClient = client.clone();
    var queryApi = _influxDBClient.getQueryService();

    var aggregate = '1m';

    switch (maxTime) {
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
          from(bucket: "${_influxDBClient.bucket}")
              |> range(start: $maxTime)
              |> filter(fn: (r) => r.clientId == "${device.id}" 
                                and r._measurement == "environment" 
                                and r["_field"] == "$field")
              |> mean()
          '''
        : '''
          import "influxdata/influxdb/v1"
          from(bucket: "${_influxDBClient.bucket}")
              |> range(start: $maxTime)
              |> filter(fn: (r) => r.clientId == "${device.id}" 
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
      _influxDBClient.close();
    }
  }

  /// replace localhost with 10.0.2.2 for android devices
  String fixLocalhost(String? url) {
    url ??= "http://localhost:5000";
    if (defaultTargetPlatform == TargetPlatform.android &&
        url.startsWith("http://localhost")) {
      return url.replaceAll("/localhost", "/10.0.2.2");
    }
    return url;
  }

//#region Write emulated data

  Future writeEmulatedData(String deviceId, Function onProgress) async {
    developer.log('Write emulated data for device $deviceId');

    var _influxDBClient = client.clone();

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

      var writeApi = _influxDBClient.getWriteService(WriteOptions()
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
        _influxDBClient.close();
      }
      onProgress(100, pointsWritten, totalPoints);
    }

    return pointsWritten;
  }

  static const dayMillis = 24 * 60 * 60 * 1000;
  final _rnd = Random();

  num _generate(
      {required num period, int min = 0, max = 40, required num time}) {
    var dif = max - min;
// generate main value
    var periodValue =
        (dif / 4) * sin((((time / dayMillis) % period) / period) * 2 * pi);
// generate secondary value, which is lowest at noon
    var dayValue =
        (dif / 4) * sin(((time % dayMillis) / dayMillis) * 2 * pi - pi / 2);
    return (((min +
        dif / 2 +
        periodValue +
        dayValue +
        _rnd.nextDouble() * 10)));
  }

//#endregion Write emulated data

//#region Sensors

  Future writeSensor(
      String sensorName, Map<String, double> fieldValueMap) async {
    var _influxDBClient = client.clone();
    final writeApi = _influxDBClient.getWriteService();

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

//#endregion Sensors
}
