import 'package:influxdb_client/api.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:iot_center_flutter_mvc/src/view.dart';

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

class _SimpleChart extends StateMVC<SimpleChart> {
  void onPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditChartPage(
                  chart: widget,
              chartRefresh: (){},
                )));
  }

  @override
  Widget build(BuildContext context) {
    var label = widget.data == null || widget.data!.isEmpty
        ? widget.measurement + " - no data"
        : widget.measurement;

    var series = [
      charts.Series<dynamic, DateTime>(
        id: widget.measurement,
        data: widget.data!,
        seriesColor: charts.ColorUtil.fromDartColor(pink),
        domainFn: (r, _) => DateTime.parse(r['_time']),
        measureFn: (r, _) => r["_value"],
      )
    ];

    return Column(children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: darkBlue),
            ),
          ),
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.settings),
            iconSize: 17,
            color: darkBlue,
          ),
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
