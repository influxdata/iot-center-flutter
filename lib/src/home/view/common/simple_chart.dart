import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import '../edit_chart_page.dart';

class SimpleChart extends StatefulWidget {
  const SimpleChart({
    Key? key,
    required this.data,
    required this.measurement,
    required this.label,
  }) : super(key: key);

  final List<FluxRecord>? data;
  final String measurement;
  final String label;

  @override
  State<StatefulWidget> createState() {
    return _SimpleChart();
  }
}

class _SimpleChart extends State<SimpleChart> {
  void onPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditChartPage(
              chart: widget,
            )));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data == null || widget.data!.isEmpty) {
      return Text(widget.measurement + " - no data");
    }

    var series = [
      charts.Series<dynamic, DateTime>(
        id: widget.measurement,
        data: widget.data!,
        domainFn: (r, _) => DateTime.parse(r['_time']),
        measureFn: (r, _) => r["_value"],
      )
    ];

    return Column(children: [
      Row(
        children: [
          Expanded(
            child: Text(
              widget.measurement,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(onPressed: onPressed, icon: const Icon(Icons.edit)),
        ],
      ),
      SizedBox(
        height: 130,
        child: charts.TimeSeriesChart(
          series,
          animate: true,
        ),
      )
    ]);
  }
}
