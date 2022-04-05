import 'package:charts_flutter/flutter.dart' as charts;
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class SimpleChart extends StatefulWidget {
  const SimpleChart({Key? key, required this.chartData}) : super(key: key);

  final ChartData chartData;

  @override
  State<StatefulWidget> createState() {
    return _SimpleChart();
  }
}

class _SimpleChart extends StateMVC<SimpleChart> {
  late Controller con;

  _SimpleChart() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
    widget.chartData.refreshChart = () {
      refresh();
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: con.getDataFromInflux(widget.chartData.measurement, false),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            var series = [
              charts.Series<dynamic, DateTime>(
                id: widget.chartData.measurement,
                data: snapshot.data!,
                seriesColor: charts.ColorUtil.fromDartColor(pink),
                domainFn: (r, _) => DateTime.parse(r['_time']),
                measureFn: (r, _) => r["_value"],
              )
            ];

            return Stack(
              children: [
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
              ]
            );
          } else {
            return const Text("loading...");
          }
        });
  }
}
