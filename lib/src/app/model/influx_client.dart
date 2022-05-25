import 'dart:convert';

import 'package:influxdb_client/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

extension InfluxClient on InfluxDBClient {
  InfluxDBClient clone() {
    return InfluxDBClient(
        url: url,
        token: token,
        bucket: bucket,
        debug: debug,
        org: org);
  }

  void _fromJson(Map<String, dynamic> json) {
    url = json['url'];
    org = json['org'];
    token = json['token'];
    bucket = json['bucket'];
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'org': org,
        'token': token,
        'bucket': bucket,
      };

  Future<InfluxDBClient> loadInfluxClient() async {
    try {
      var prefs = await SharedPreferences.getInstance();
      _fromJson(json.decode(prefs.getString("influxClient")!));
      return this;
    } catch (e) {
      developer.log('Failed to load Influx Client' + e.toString());
      throw Exception('Failed to load Influx Client from Shared Preferences.');
    }
  }

  Future<void> saveInfluxClient() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("influxClient", jsonEncode(this));
    } catch (e) {
      developer.log('Failed to save Influx Client' + e.toString());
      throw Exception('Failed to save Influx Client to Shared Preferences.');
    }
  }
}
