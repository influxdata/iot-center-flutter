import 'package:charts_flutter/flutter.dart' as charts;
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class SimpleChart extends StatefulWidget {
  const SimpleChart({Key? key, required this.chartData, required this.con})
      : super(key: key);

  final ChartData chartData;
  final DashboardController con;

  @override
  State<StatefulWidget> createState() {
    return _SimpleChart();
  }
}

class _SimpleChart extends StateMVC<SimpleChart> {
  Future<List<FluxRecord>>? _data;

  @override
  void initState() {
    super.initState();
    _data = widget.con.getDataFromInflux(widget.chartData.measurement, false);

    widget.chartData.reloadData = () {
      _data = widget.con.getDataFromInflux(widget.chartData.measurement, false);
      refresh();
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: _data,
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData &&
              snapshot.connectionState == ConnectionState.done) {
            var series = [
              charts.Series<dynamic, DateTime>(
                id: widget.chartData.measurement,
                data: snapshot.data!,
                seriesColor: charts.ColorUtil.fromDartColor(pink),
                domainFn: (r, _) => DateTime.parse(r['_time']),
                measureFn: (r, _) => r["_value"],
              )
            ];

            return Stack(children: [
              SizedBox(
                height: 130,
                child: charts.TimeSeriesChart(
                  series,
                  animate: true,
                ),
              ),
              Center(
                child: Text(
                  widget.chartData.unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            ]);
          } else {
            var series = [
              charts.Series<dynamic, DateTime>(
                id: widget.chartData.measurement,
                data: [],
                seriesColor: charts.ColorUtil.fromDartColor(pink),
                domainFn: (r, _) => DateTime.parse(r['_time']),
                measureFn: (r, _) => r["_value"],
              )
            ];
            return Stack(children: [
              SizedBox(
                height: 130,
                child: charts.TimeSeriesChart(
                  series,
                  animate: true,
                ),
              ),
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.chartData.unit,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: pink,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ]);
          }
        });
  }
}
