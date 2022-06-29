import 'dart:async';
import 'dart:developer';

import 'package:battery_plus/battery_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sensors can return multiple subfields.
///
/// For example sensor can return {"x": 10, "y": 20 ...}
///
/// If sensor returns only one value
///   then there will be only one entry with "" key
typedef SensorMeasurement = Map<String, double>;

/// Used by SensorInfo to ask user for permission to use sensor
typedef PermissionRequester = Future<Stream<SensorMeasurement>?> Function();

class SensorInfo {
  /// sensor or measurement name
  String name;
  Stream<SensorMeasurement>? stream;

  bool get availeble {
    return (stream != null);
  }

  /// if sensor needs ask user for permission, this function is set
  PermissionRequester? _permissionRequester;

  Future<void> Function()? get requestPermission {
    if (_permissionRequester == null) return null;
    return (() async {
      stream = await _permissionRequester!();
      _permissionRequester = null;
    });
  }

  SensorInfo(this.name,
      {this.stream, PermissionRequester? permissionRequester}) {
    _permissionRequester = permissionRequester;
  }
}

class Sensors {
  final _es = EnvironmentSensors();

  Stream<SensorMeasurement> get _accelerometer =>
      SensorsPlatform.instance.accelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _userAccelerometer =>
      SensorsPlatform.instance.userAccelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _gyroscope =>
      SensorsPlatform.instance.gyroscopeEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _magnetometer =>
      SensorsPlatform.instance.magnetometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _battery async* {
    final battery = Battery();
    final SensorMeasurement batteryLastState = {};
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

  Future<Stream<SensorMeasurement>?> get _temperature async =>
      (await _es.getSensorAvailable(SensorType.AmbientTemperature))
          ? EnvironmentSensors().temperature.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _humidity async =>
      (await _es.getSensorAvailable(SensorType.Humidity))
          ? EnvironmentSensors().humidity.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _light async =>
      (await _es.getSensorAvailable(SensorType.Light))
          ? EnvironmentSensors().light.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _pressure async =>
      (await _es.getSensorAvailable(SensorType.Pressure))
          ? EnvironmentSensors().pressure.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _geo async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    return (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse)
        ? Geolocator.getPositionStream().map((pos) {
            return {
              "lat": pos.latitude,
              "lon": pos.longitude,
              "acc": pos.accuracy
            };
          })
        : null;
  }

  Future<PermissionRequester?> get _geoRequester async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) return null;

    return () async {
      await Geolocator.requestPermission();
      return await _geo;
    };
  }

  Future<List<SensorInfo>> get sensors async => <SensorInfo>[
        SensorInfo("Accelerometer", stream: _accelerometer),
        SensorInfo("UserAccelerometer", stream: _userAccelerometer),
        SensorInfo("Gyroscope", stream: _gyroscope),
        SensorInfo("Magnetometer", stream: _magnetometer),
        SensorInfo("Battery", stream: _battery.asBroadcastStream()),
        SensorInfo("Temperature", stream: await _temperature),
        SensorInfo("Humidity", stream: await _humidity),
        SensorInfo("Light", stream: await _light),
        SensorInfo("Pressure", stream: await _pressure),
        SensorInfo("Geo",
            stream: await _geo, permissionRequester: await _geoRequester),
      ];
}

class SensorsSubscriptionManager {
  final Map<SensorInfo, StreamSubscription<Map<String, double>>> subscriptions =
      {};

  final Map<String, SensorMeasurement> _lastValues = {};
  DateTime? _lastDataRead;

  DateTime? get lastDataRead => _lastDataRead;

  /// Returns function that adds sensorname into SensorMeasurement
  static SensorMeasurement addNameToMeasure(
          SensorInfo sensor, SensorMeasurement measurement) =>
      measurement.map((key, value) {
        final name = sensor.name + (key != "" ? "_$key" : "");
        return MapEntry(name, value);
      });

  SensorMeasurement lastValueOf(SensorInfo sensor) =>
      _lastValues[sensor.name] ?? {};

  bool isSubscribed(SensorInfo sensor) => subscriptions.containsKey(sensor);

  void subscribe(SensorInfo sensor,
      void Function(SensorMeasurement, SensorInfo) callback) {
    if (subscriptions[sensor] != null) unsubscribe(sensor);
    final stream = sensor.stream;
    if (stream == null) {
      log("sensor ${sensor.name} is not subsciable", level: 900);
      return;
    }

    subscriptions[sensor] = stream.listen((metrics) {
      _lastDataRead = DateTime.now();
      _lastValues[sensor.name] = metrics;
      callback(metrics, sensor);
    });
  }

  Future<bool> trySubscribe(SensorInfo sensor,
      void Function(SensorMeasurement, SensorInfo) callback) async {
    if (!sensor.availeble && sensor.requestPermission != null) {
      await sensor.requestPermission!();
    }
    if (sensor.availeble) {
      subscribe(sensor, callback);
    }
    return sensor.availeble;
  }

  void unsubscribe(SensorInfo sensor) {
    final subscriptionHandler = subscriptions[sensor];
    if (subscriptionHandler == null) return;
    subscriptionHandler.cancel();
    subscriptions.remove(sensor);
    _lastValues.remove(sensor.name);
  }

  void unsubscribeAll() {
    subscriptions.keys.toList().forEach(unsubscribe);
  }
}
