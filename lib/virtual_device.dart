import 'dart:developer' as developer;

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_influx_app/iot_center.dart';
import 'package:influxdb_client/api.dart';
import 'package:logging/logging.dart';

import 'commons.dart';

class VirtualDevice extends StatefulWidget {
  const VirtualDevice({Key? key}) : super(key: key);

  @override
  State createState() => _VirtualDeviceState();
}

class _VirtualDeviceState extends State<VirtualDevice> {
  Map? selectedDevice;
  List deviceList = [];

  String maxPastTime = "-1d";

  @override
  void initState() {
    super.initState();
    fetchDevices().then((devicesJson) {
      setState(() {
        deviceList.clear();
        deviceList.addAll(devicesJson);
        selectedDevice = deviceList.first;
      });
    }).catchError((e) {
      developer.log(e, name: "virtual_device", level: Level.SEVERE.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      buildDeviceSelector(selectedDevice, deviceList, maxPastTime, (val) {
        setState(() {
          selectedDevice =
              deviceList.firstWhere((element) => element['deviceId'] == val);
        });
      }, (val) {
        setState(() {
          maxPastTime = val!;
        });
      }, () {
        setState(() {
          _refresh();
        });
      }),
      const Spacer(),
      Expanded(
          flex: 4,
          child: Center(
              child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Center(
                      child:
                          createGaugeComponent("Temperature", (v) => "$v˚C"))),
              Expanded(
                  flex: 1,
                  child: Center(
                      child: createGaugeComponent("CO2", (v) => "$v ppm"))),
            ],
          ))),
      Expanded(
          flex: 4,
          child: Center(
              child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Center(
                      child: createGaugeComponent("Humidity", (v) => "$v%"))),
              Expanded(
                  flex: 1,
                  child: Center(
                      child:
                          createGaugeComponent("Pressure", (v) => "$v hpa"))),
            ],
          ))),
      Expanded(
          flex: 4,
          child: Center(
              child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Center(
                      child:
                          createSimpleChartComponent("TVOC", (v) => "$v ppm"))),
            ],
          ))),
      const Spacer()
    ]);
  }

  Widget createGaugeComponent(
      String measurement, String Function(dynamic) labelFn) {
    return FutureBuilder<dynamic>(
        future: fetchDeviceDataFieldLast(
            selectedDevice != null ? selectedDevice!['deviceId'] : null,
            measurement,
            maxPastTime),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            return _buildGauge(snapshot.data, measurement, labelFn);
          } else {
            return const Text("loading...");
          }
        });
  }

  void _refresh() {}

  Widget _buildChart(
      List<FluxRecord>? data, String measurement, Function labelFn) {
    if (data == null || data.isEmpty) {
      return Text("$measurement - no data");
    }
    var last = data.last["_value"];
    final d = [
      charts.Series<dynamic, DateTime>(
        id: measurement,
        data: data,
        // colorFn: (FluxRecord r, _) => r.color,
        domainFn: (r, _) => DateTime.parse(r['_time']),
        measureFn: (r, _) => r["_value"],
        labelAccessorFn: (r, _) => labelFn(r["_value"]),
      )
    ];

    return Stack(children: [
      Align(
          alignment: Alignment.topCenter,
          child: Text(measurement,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
      charts.TimeSeriesChart(
        d,
        animate: true,
      ),
      Center(
        child: Text(
            labelFn(
                last is int ? last : double.parse((last).toStringAsFixed(2))),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      )
    ]);
  }

  Widget createSimpleChartComponent(
      String measurement, String Function(dynamic) labelFn) {
    return FutureBuilder<List<FluxRecord>>(
        future: fetchDeviceDataField(
            selectedDevice != null ? selectedDevice!['deviceId'] : null,
            measurement,
            maxPastTime),
        builder: (context, AsyncSnapshot<List<FluxRecord>> snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            return _buildChart(snapshot.data, measurement, labelFn);
          } else {
            return const Text("loading...");
          }
        });
  }
}

Widget _buildGauge(List<FluxRecord> data, String s, Function labelFn) {
  if (data.isEmpty) {
    return Text("$s - no data");
  }
  var last = data.last["_value"];
  final chartData = [
    GaugeSegment('', 0, charts.MaterialPalette.indigo.shadeDefault),
    GaugeSegment('Actual', last, charts.MaterialPalette.blue.shadeDefault),
    GaugeSegment('', 100, charts.MaterialPalette.gray.shadeDefault),
  ];
  final d = [
    charts.Series<GaugeSegment, String>(
      id: 'Segments',
      colorFn: (GaugeSegment segment, _) => segment.color,
      domainFn: (GaugeSegment segment, _) => segment.segment,
      measureFn: (GaugeSegment segment, _) =>
          double.parse((segment.value).toStringAsFixed(2)),
      labelAccessorFn: (GaugeSegment segment, _) => labelFn(segment.value),
      data: chartData,
    )
  ];

  return Stack(children: [
    Align(
        alignment: Alignment.topCenter,
        child: Text(s,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
    charts.PieChart(
      d,
      animate: true,
      // defaultRenderer: new charts.ArcRendererConfig(
      //     arcWidth: 20, startAngle: 4 / 5 * pi, arcLength: 7 / 5 * pi)
    ),
    Center(
      child: Text(
          labelFn(last is int ? last : double.parse((last).toStringAsFixed(2))),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    )
  ]);
}

/// Sample data type.
class GaugeSegment {
  final String segment;
  final num value;
  final charts.Color color;

  GaugeSegment(this.segment, this.value, this.color);
}
